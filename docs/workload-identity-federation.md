# Customer-owned service account with Workload Identity Federation

By default, the module grants read-only roles to Masthead service accounts (`masthead-data@masthead-prod`, `retro-data@masthead-prod` and others). If your security policy doesn't allow identities from other organizations in your IAM policies, use a service account that you own instead:

- You create the service account and grant it the roles. The module does this when you pass your service account in `masthead_service_accounts`.
- Masthead reaches that service account through [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation). No service account keys are created or exchanged.
- No Masthead identity appears in your IAM policies; the only grant is `roles/iam.workloadIdentityUser` on your service account to principals of a pool that you own.

## How it works

1. Masthead requests a Google-signed ID token for its service account.
2. Masthead exchanges the token with the [Security Token Service](https://cloud.google.com/iam/docs/reference/sts/rest). The exchange succeeds only because your workload identity pool provider trusts `https://accounts.google.com` tokens whose subject is a Masthead service account ID.
3. Masthead uses the federated token to get a short-lived (1 hour) access token for your service account.

Access stops as soon as you disable the provider, the pool or the service account. API calls are recorded in your Cloud Audit Logs.

## Setup

### 1. Create the service account and the federation

Create these resources in one of your projects, for example the deployment project in Organization Mode:

```hcl
locals {
  # OIDC `sub` claims (unique IDs) of Masthead service accounts
  masthead_sa_unique_ids = [
    "110299410351654081203", # masthead-data@masthead-prod.iam.gserviceaccount.com
    "115289587456476335753", # retro-data@masthead-prod.iam.gserviceaccount.com
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(["iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com"])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "masthead" {
  project      = var.project_id
  account_id   = "masthead-reader"
  display_name = "Masthead Data reader"

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
  attribute_condition = "assertion.sub in ${jsonencode(local.masthead_sa_unique_ids)}"

  oidc {
    issuer_uri = "https://accounts.google.com"
  }
}

resource "google_service_account_iam_member" "masthead_workload_user" {
  for_each = toset(local.masthead_sa_unique_ids)

  service_account_id = google_service_account.masthead.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.masthead.name}/subject/${each.value}"
}

output "masthead_service_account" {
  value = google_service_account.masthead.email
}

output "masthead_provider" {
  value = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.masthead.name}"
}
```

If you delete the pool, its ID stays reserved for 30 days. Use a different `workload_identity_pool_id` to re-create it within that period.

### 2. Deploy the module with your service account

Pass your service account in place of the Masthead defaults:

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.4.3"

  project_id = "project-1"

  masthead_service_accounts = {
    bigquery_sa = google_service_account.masthead.email
    dataform_sa = google_service_account.masthead.email
    dataplex_sa = google_service_account.masthead.email
    retro_sa    = google_service_account.masthead.email
  }
}
```

The module grants the same roles as in the default setup, now to your service account.

### 3. Share the federation details with Masthead

Send the `masthead_service_account` and `masthead_provider` outputs to Masthead. They contain no secrets.

## Verify

After Masthead confirms the connection, BigQuery audit logs of the monitored projects show API calls by your service account.

To also log each token exchange, enable [Data Access audit logs](https://cloud.google.com/logging/docs/audit/configure-data-access) for `iamcredentials.googleapis.com` and `sts.googleapis.com` in the federation project. `GenerateAccessToken` entries then show the pool principal that used your service account.

## Revoke access

Do any of the following:

- Disable the provider: `gcloud iam workload-identity-pools providers update-oidc masthead-google --workload-identity-pool=masthead --location=global --disabled --project=PROJECT_ID --quiet`
- Remove the `roles/iam.workloadIdentityUser` bindings from the service account.
- Disable or delete the service account.
