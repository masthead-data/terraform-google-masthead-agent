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

The example creates accounts, trust bindings and provider subjects only for the modules that you enable. See [Configure features](#configure-features) for Dataform, Dataplex and data scans.

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

`bigquery_sa` and `retro_sa` are always created. `enable_modules` takes the same keys as the agent module's, plus `data_scans`. Dataform and Dataplex are on by default, so existing setups don't change. Data scans are off by default. Pass the example's `enable_modules` output to the agent module. It fills in the defaults and drops `data_scans`:

```hcl
locals {
  enable_modules = {
    dataform   = false
    data_scans = true
  }
}

module "masthead_federation" {
  source  = "masthead-data/masthead-agent/google//examples/workload-identity-federation"
  version = ">=0.4.4"

  project_id                = "project-1"
  separate_service_accounts = true # recommended: least privilege per Masthead identity
  enable_modules            = local.enable_modules
}

module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.4.4"

  project_id = "project-1"

  masthead_service_accounts = module.masthead_federation.masthead_service_accounts
  enable_modules            = module.masthead_federation.enable_modules
}
```

- With `dataform` or `dataplex` set to `false`, the example creates no account, trust binding or provider subject for that module. It also sets the module's key in `masthead_service_accounts` to `null` and leaves it out of `masthead_federation`.
- `data_scans = true` creates `quality_sa`, with no roles. Grant it `roles/bigquery.dataViewer` on your own metrics datasets, conventionally `masthead_dq`, yourself; see [Data scans](../../docs/workload-identity-federation.md#data-scans). The agent module doesn't take `quality_sa`. The key appears only in `masthead_federation`, which Masthead maps to `qualitySa`.
- With `separate_service_accounts = true`, each enabled key gets its own account: `masthead-bigquery`, `masthead-retro`, `masthead-dataform`, `masthead-dataplex` and `masthead-quality`. Separate accounts are recommended. With one shared account, the data scan identity can use every monitoring role, and every Masthead identity can read your metrics datasets.

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | Project for the service account, and the pool unless `pool_project_id` is set | required |
| `service_account_id` | Account ID of the service account. With `separate_service_accounts`, the prefix of the per-identity account IDs | `masthead` |
| `enable_modules` | Modules to create identities for: the agent module's `enable_modules` keys plus `data_scans`. `dataform`, `dataplex` and `data_scans` create `dataform_sa`, `dataplex_sa` and `quality_sa` | `dataform`, `dataplex` on; `data_scans` off |
| `separate_service_accounts` | One service account per configured Masthead identity: `masthead-bigquery`, `masthead-retro`, `masthead-dataform`, `masthead-dataplex`, `masthead-quality`. Recommended | `false` |
| `create_pool` | Create the workload identity pool. `false` adds the Masthead provider to an existing pool | `true` |
| `pool_id` | Workload identity pool ID, created or existing. A deleted pool's ID stays reserved for 30 days | `masthead` |
| `pool_project_id` | Project of the pool and provider | `project_id` |
| `provider_id` | Workload identity pool provider ID | `masthead-google` |
| `enable_apis` | Enable the IAM, IAM Credentials and Security Token Service APIs | `true` |

## Outputs

| Name | Description |
|---|---|
| `masthead_service_accounts` | Service accounts for the module's `masthead_service_accounts` input. `null` for a disabled module |
| `enable_modules` | The `enable_modules` input without `data_scans`, for the agent module's `enable_modules` |
| `masthead_federation` | Provider and service accounts of the enabled modules to share with Masthead. Contains no secrets |
