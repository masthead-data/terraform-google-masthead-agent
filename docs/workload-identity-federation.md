# Customer-owned service account with Workload Identity Federation

By default, the module grants read-only roles to Masthead service accounts (`masthead-data@masthead-prod`, `retro-data@masthead-prod` and others). If your security policy doesn't allow identities from other organizations in your IAM policies, use a service account that you own instead:

- You create the service account and grant it the roles. The module does this when you pass your service account in `masthead_service_accounts`.
- Masthead reaches that service account through [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation). No service account keys are created or exchanged.
- No Masthead identity appears in your IAM policies; the only grants are `roles/iam.workloadIdentityUser` on your service account to principals of a pool that you own.

## How it works

1. Masthead requests a Google-signed ID token for one of its service accounts.
2. Masthead exchanges the token with the [Security Token Service](https://cloud.google.com/iam/docs/reference/sts/rest). The exchange succeeds only because your workload identity pool provider trusts `https://accounts.google.com` tokens whose subject is a Masthead service account ID.
3. Masthead uses the federated token to get a short-lived (1 hour) access token for your service account.

To stop access immediately, disable or delete the service account. Disabling the provider or the pool blocks new token exchanges, but access tokens already issued stay valid until they expire (up to 1 hour). API calls are recorded in your Cloud Audit Logs.

## Setup

### 1. Create the service account and the federation

Create these resources in one of your projects, for example the deployment project in Organization Mode. The [workload-identity-federation example](../examples/workload-identity-federation) packages the same resources as a module, including the [separate service accounts](#separate-service-accounts) option.

```hcl
locals {
  # OIDC subjects (unique IDs) of Masthead service accounts.
  # Keys match the module's `masthead_service_accounts` input. Remove the entries of features that you don't use,
  # and add `quality_sa` for data scans (see "Data scans").
  masthead_subjects = {
    bigquery_sa = "110299410351654081203" # masthead-data@masthead-prod
    dataform_sa = "113640520915211463906" # masthead-dataform@masthead-prod
    dataplex_sa = "117888223789069357263" # masthead-dataplex@masthead-prod
    retro_sa    = "115289587456476335753" # retro-data@masthead-prod
  }
}

resource "google_project_service" "apis" {
  for_each = toset(["iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com"])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "masthead" {
  project      = var.project_id
  account_id   = "masthead"
  display_name = "Masthead Data"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool" "masthead" {
  project                   = var.project_id
  workload_identity_pool_id = "masthead"
  display_name              = "Masthead Data"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "masthead" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.masthead.workload_identity_pool_id
  workload_identity_pool_provider_id = "masthead-google"
  display_name                       = "Masthead Data (Google)"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  attribute_condition = "assertion.sub in ${jsonencode(values(local.masthead_subjects))}"

  oidc {
    issuer_uri = "https://accounts.google.com"
  }
}

resource "google_service_account_iam_member" "masthead_workload_user" {
  for_each = local.masthead_subjects

  service_account_id = google_service_account.masthead.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.masthead.name}/subject/${each.value}"
}

locals {
  masthead_service_accounts = { for k in keys(local.masthead_subjects) : k => google_service_account.masthead.email }
}

output "masthead_federation" {
  description = "Federation details to share with Masthead"
  value = {
    provider         = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.masthead.name}"
    service_accounts = local.masthead_service_accounts
  }
}
```

If you delete the pool, its ID stays reserved for 30 days. Use a different `workload_identity_pool_id` to re-create it within that period.

### 2. Share the federation details with Masthead

Send the `masthead_federation` output to Masthead. It contains no secrets:

```bash
terraform output -json masthead_federation
```

```json
{
  "provider": "//iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/masthead/providers/masthead-google",
  "service_accounts": {
    "bigquery_sa": "masthead@my-project.iam.gserviceaccount.com",
    "dataform_sa": "masthead@my-project.iam.gserviceaccount.com",
    "dataplex_sa": "masthead@my-project.iam.gserviceaccount.com",
    "retro_sa": "masthead@my-project.iam.gserviceaccount.com"
  }
}
```

The `service_accounts` map contains one entry for each feature that you configured. `bigquery_sa` and `retro_sa` are always present. Masthead maps the keys to its deploy request: `bigquery_sa` to `bigquerySa`, `retro_sa` to `retroSa`, `dataform_sa` to `dataformSa`, `dataplex_sa` to `dataplexSa` and `quality_sa` to `qualitySa`. For a feature without a key, Masthead disables the feature for your tenant instead of using a Masthead identity.

Masthead confirms when the token exchange works. This doesn't require any roles on your service account yet.

### 3. Deploy the module with your service account

Pass your service account in place of the Masthead defaults:

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.4.3"

  project_id = "project-1"

  masthead_service_accounts = local.masthead_service_accounts
}
```

The module grants the same roles as in the default setup, now to your service account.

If you don't use Dataform or Dataplex with Masthead, omit their service accounts from the federation and turn off the matching modules. `masthead_service_accounts` accepts `null` for these keys only when the matching module is disabled:

```hcl
module "masthead_agent" {
  # ...
  masthead_service_accounts = {
    bigquery_sa = local.masthead_service_accounts.bigquery_sa
    dataform_sa = null
    dataplex_sa = null
    retro_sa    = local.masthead_service_accounts.retro_sa
  }

  enable_modules = {
    bigquery      = true
    dataform      = false
    dataplex      = false
    analytics_hub = true
  }
}
```

If the module is already deployed with the default Masthead service accounts, this change removes their grants. Apply it after Masthead confirms step 2, so monitoring continues without a gap.

## Separate service accounts

To give each Masthead service account only the roles it needs, create one service account per Masthead identity. Replace `google_service_account.masthead`, `google_service_account_iam_member.masthead_workload_user` and the `masthead_service_accounts` local from step 1 with:

```hcl
resource "google_service_account" "masthead" {
  for_each = local.masthead_subjects

  project      = var.project_id
  account_id   = "masthead-${replace(trimsuffix(each.key, "_sa"), "_", "-")}"
  display_name = "Masthead Data (${each.key})"

  depends_on = [google_project_service.apis]
}

resource "google_service_account_iam_member" "masthead_workload_user" {
  for_each = local.masthead_subjects

  service_account_id = google_service_account.masthead[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.masthead.name}/subject/${each.value}"
}

locals {
  masthead_service_accounts = { for k, sa in google_service_account.masthead : k => sa.email }
}
```

This creates `masthead-bigquery`, `masthead-retro`, and `masthead-dataform`, `masthead-dataplex` and `masthead-quality` for the features that you configure. Each Masthead identity can use only its matching service account.

Separate service accounts are recommended. With one shared service account, the data scan identity can use every role that you grant for monitoring, and every Masthead identity that impersonates the shared account can read your metrics dataset. You can still share one service account across keys, including `quality_sa`, if your policy requires it.

## Dataform

Masthead reads Dataform repositories and workflows with the `dataform_sa` service account. The module grants it `roles/dataform.viewer` on the monitored projects and folders. Dataform is supported with federation. Without a `dataform_sa` key, Masthead doesn't connect Dataform for your tenant. Set `enable_modules.dataform` to `false` in that case.

## Dataplex

Masthead reads Dataplex data products and data scans with the `dataplex_sa` service account. The module grants it `roles/dataplex.dataProductsViewer` and `roles/dataplex.dataScanDataViewer` on the monitored projects and folders. With `enable_datascan_editing = true`, it also grants `roles/dataplex.dataScanEditor`, `roles/dataplex.storageDataReader` and `roles/bigquery.jobUser`. Dataplex is supported with federation. Without a `dataplex_sa` key, Masthead doesn't connect Dataplex for your tenant. Set `enable_modules.dataplex` to `false` in that case.

## Data scans

Data scans run SQL on metrics tables that you maintain, in a dataset in your own project, conventionally `masthead_dq`. Masthead runs them as your `quality_sa` service account. The module doesn't grant this account any monitoring roles. It needs only read access to your metrics datasets. With the [example module](../examples/workload-identity-federation), set `enable_modules.data_scans = true` instead of step 1. In step 2, use `module.masthead_federation.masthead_federation.service_accounts["quality_sa"]` as the account:

1. Add the Masthead data scan subject to `masthead_subjects` in step 1, so that the provider trusts it and `quality_sa` gets a service account:

    ```hcl
    quality_sa = "107725254217268738982" # masthead-quality-checks@masthead-prod
    ```

2. Grant `roles/bigquery.dataViewer` on each metrics dataset to that service account:

    ```hcl
    resource "google_bigquery_dataset_iam_member" "quality_data_viewer" {
      project    = "project-1"
      dataset_id = "masthead_dq"
      role       = "roles/bigquery.dataViewer"
      member     = "serviceAccount:${local.masthead_service_accounts["quality_sa"]}"
    }
    ```

3. If a metrics table is a view over tables in other datasets, [authorize the view](https://cloud.google.com/bigquery/docs/authorized-views) or its dataset to read them. `roles/bigquery.dataViewer` on the metrics dataset doesn't cover the source tables.

`quality_sa` is not an input of the module's `masthead_service_accounts`. Send it to Masthead in the `masthead_federation` output only. Without a `quality_sa` key, Masthead refuses to create data scans for your tenant.

If you use VPC Service Controls, add the `quality_sa` account to the ingress identities of your perimeter yourself: the module's `vpc_service_controls_config` output doesn't list it, because it isn't a module input.

## Remove log access after the backfill

`roles/logging.privateLogViewer` lets Masthead read the last 30 days of audit logs once, during onboarding. After Masthead confirms the backfill is complete, set `enable_privatelogviewer_role = false` in the module and apply.

## Verify

After Masthead confirms the connection, BigQuery audit logs of the monitored projects show API calls by your service account.
