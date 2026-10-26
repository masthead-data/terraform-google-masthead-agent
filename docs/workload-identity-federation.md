# Customer-owned service accounts with Workload Identity Federation

By default, the module grants read-only roles to Masthead service accounts (`masthead-data@masthead-prod`, `retro-data@masthead-prod` and others). If your security policy doesn't allow identities from other organizations in your IAM policies, use service accounts that you own instead:

- You create the service accounts and grant them the roles. The module does this when you pass your service accounts in `masthead_service_accounts`.
- Masthead reaches those service accounts through [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation). No service account keys are created or exchanged.
- No Masthead identity appears in your IAM policies; the only grants are `roles/iam.workloadIdentityUser` on each of your service accounts to one principal of a pool that you own.

## How it works

1. Masthead requests a Google-signed ID token for its service account.
2. Masthead exchanges the token with the [Security Token Service](https://cloud.google.com/iam/docs/reference/sts/rest). The exchange succeeds only because your workload identity pool provider trusts `https://accounts.google.com` tokens whose subject is a Masthead service account ID.
3. Masthead uses the federated token to get a short-lived (1 hour) access token for the matching service account.

Access stops as soon as you disable the provider, the pool or the service accounts. API calls are recorded in your Cloud Audit Logs.

## Setup

### 1. Create the service accounts and the federation

Create one service account per Masthead service account. Each Masthead identity can use only its matching service account. Create these resources in one of your projects, for example the deployment project in Organization Mode:

```hcl
locals {
  # Keys match the module's `masthead_service_accounts` input.
  # `sub` is the OIDC subject (unique ID) of the Masthead service account.
  masthead_identities = {
    bigquery_sa = { sub = "110299410351654081203", account_id = "masthead-bigquery" } # masthead-data@masthead-prod
    dataform_sa = { sub = "113640520915211463906", account_id = "masthead-dataform" } # masthead-dataform@masthead-prod
    dataplex_sa = { sub = "117888223789069357263", account_id = "masthead-dataplex" } # masthead-dataplex@masthead-prod
    retro_sa    = { sub = "115289587456476335753", account_id = "masthead-retro" }    # retro-data@masthead-prod
  }
}

resource "google_project_service" "apis" {
  for_each = toset(["iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com"])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "masthead" {
  for_each = local.masthead_identities

  project      = var.project_id
  account_id   = each.value.account_id
  display_name = "Masthead Data (${each.key})"

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
  attribute_condition = "assertion.sub in ${jsonencode([for i in local.masthead_identities : i.sub])}"

  oidc {
    issuer_uri = "https://accounts.google.com"
  }
}

resource "google_service_account_iam_member" "masthead_workload_user" {
  for_each = local.masthead_identities

  service_account_id = google_service_account.masthead[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.masthead.name}/subject/${each.value.sub}"
}

output "masthead_federation" {
  description = "Federation details to share with Masthead"
  value = {
    provider         = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.masthead.name}"
    service_accounts = { for k, sa in google_service_account.masthead : k => sa.email }
  }
}
```

If you delete the pool, its ID stays reserved for 30 days. Use a different `workload_identity_pool_id` to re-create it within that period.

### 2. Deploy the module with your service accounts

Pass your service accounts in place of the Masthead defaults:

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.4.3"

  project_id = "project-1"

  masthead_service_accounts = { for k, sa in google_service_account.masthead : k => sa.email }
}
```

The module grants the same roles as in the default setup, now to your service accounts.

### 3. Share the federation details with Masthead

Send the `masthead_federation` output to Masthead. It contains no secrets:

```bash
terraform output -json masthead_federation
```

```json
{
  "provider": "//iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/masthead/providers/masthead-google",
  "service_accounts": {
    "bigquery_sa": "masthead-bigquery@my-project.iam.gserviceaccount.com",
    "dataform_sa": "masthead-dataform@my-project.iam.gserviceaccount.com",
    "dataplex_sa": "masthead-dataplex@my-project.iam.gserviceaccount.com",
    "retro_sa": "masthead-retro@my-project.iam.gserviceaccount.com"
  }
}
```

## Verify

After Masthead confirms the connection, BigQuery audit logs of the monitored projects show API calls by your service accounts.
