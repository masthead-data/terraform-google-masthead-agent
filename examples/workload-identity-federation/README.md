# Workload Identity Federation for Masthead

Creates step 1 of [Customer-owned service account with Workload Identity Federation](../../docs/workload-identity-federation.md): a service account that you own, and a workload identity pool and provider that let Masthead service accounts use it. Pass the `masthead_service_accounts` output to the Masthead agent module.

## Usage

```hcl
module "masthead_federation" {
  source  = "masthead-data/masthead-agent/google//examples/workload-identity-federation"
  version = ">=0.4.4"

  project_id = "project-1"
}

module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.4.4"

  project_id = "project-1"

  masthead_service_accounts = module.masthead_federation.masthead_service_accounts
}

output "masthead_federation" {
  description = "Federation details to share with Masthead"
  value       = module.masthead_federation.masthead_federation
}
```

The example creates accounts, trust bindings and provider subjects only for the features that you configure. See [Configure features](#configure-features) for Dataform, Dataplex and data scans.

Apply the federation first and send the `masthead_federation` output to Masthead. Add `module "masthead_agent"` with `masthead_service_accounts` after Masthead confirms the token exchange works, so monitoring continues without a gap.

### Existing pool

To add the Masthead provider to a workload identity pool that you already manage elsewhere, reference it instead of creating one:

```hcl
module "masthead_federation" {
  source  = "masthead-data/masthead-agent/google//examples/workload-identity-federation"
  version = ">=0.4.4"

  project_id      = "project-1"
  create_pool     = false
  pool_id         = "existing-pool"
  pool_project_id = "identity-project" # omit if the pool is in project_id
}
```

The provider ID (`masthead-google` by default) must be unused in that pool. The provider's attribute condition admits only Masthead service accounts, so other providers in the pool are unaffected.

### Configure features

`bigquery_sa` and `retro_sa` are always created. Dataform and Dataplex are on by default, so existing setups don't change. Data scans are off until you list the datasets that hold your scan metrics:

```hcl
module "masthead_federation" {
  source  = "masthead-data/masthead-agent/google//examples/workload-identity-federation"
  version = ">=0.4.4"

  project_id                = "project-1"
  separate_service_accounts = true # recommended: least privilege per Masthead identity
  enable_dataform           = false
  data_scan_dataset_ids     = ["project-1.masthead_dq"]
}

module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.4.4"

  project_id = "project-1"

  masthead_service_accounts = module.masthead_federation.masthead_service_accounts

  # Match enable_modules to the features that you configured: a disabled feature has a null service account.
  enable_modules = {
    bigquery      = true
    dataform      = false
    dataplex      = true
    analytics_hub = true
  }
}
```

- `enable_dataform = false` or `enable_dataplex = false` creates no account, trust binding or provider subject for that feature, sets its key in `masthead_service_accounts` to `null`, and removes it from `masthead_federation`. Set the matching `enable_modules` entry to `false`; the agent module needs a service account for every enabled module.
- A non-empty `data_scan_dataset_ids` creates `quality_sa` and grants it `roles/bigquery.dataViewer` on each `project.dataset`. Use your own datasets, conventionally `masthead_dq`. For views over other datasets, authorize the view separately. The agent module doesn't take `quality_sa`; the key appears only in `masthead_federation`, which Masthead maps to `qualitySa`.
- With `separate_service_accounts = true`, each configured key gets its own account (`masthead-bigquery`, `masthead-retro`, `masthead-dataform`, `masthead-dataplex`, `masthead-quality`). Separate accounts are recommended: with one shared account, the data scan identity can use every monitoring role, and every Masthead identity can read your metrics dataset.

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | Project for the service account, and the pool unless `pool_project_id` is set | required |
| `service_account_id` | Account ID of the service account. With `separate_service_accounts`, the prefix of the per-identity account IDs | `masthead` |
| `separate_service_accounts` | One service account per configured Masthead identity: `masthead-bigquery`, `masthead-retro`, `masthead-dataform`, `masthead-dataplex`, `masthead-quality`. Recommended | `false` |
| `enable_dataform` | Create the Dataform identity (`dataform_sa`). Set `enable_modules.dataform = false` in the agent module when `false` | `true` |
| `enable_dataplex` | Create the Dataplex identity (`dataplex_sa`). Set `enable_modules.dataplex = false` in the agent module when `false` | `true` |
| `data_scan_dataset_ids` | Datasets (`project.dataset`, conventionally `masthead_dq`) that hold your data scan metrics. Non-empty creates `quality_sa` with `roles/bigquery.dataViewer` on each | `[]` |
| `create_pool` | Create the workload identity pool. `false` adds the Masthead provider to an existing pool | `true` |
| `pool_id` | Workload identity pool ID, created or existing. A deleted pool's ID stays reserved for 30 days | `masthead` |
| `pool_project_id` | Project of the pool and provider | `project_id` |
| `provider_id` | Workload identity pool provider ID | `masthead-google` |
| `enable_apis` | Enable the IAM, IAM Credentials and Security Token Service APIs | `true` |

## Outputs

| Name | Description |
|---|---|
| `masthead_service_accounts` | Service accounts for the module's `masthead_service_accounts` input. `null` for a feature that is not configured |
| `masthead_federation` | Provider and service accounts of the configured features to share with Masthead. Contains no secrets |
