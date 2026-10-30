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

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | Project for the service account, and the pool unless `pool_project_id` is set | required |
| `service_account_id` | Account ID of the service account. With `separate_service_accounts`, the prefix of the per-identity account IDs | `masthead` |
| `separate_service_accounts` | One service account per Masthead identity: `masthead-bigquery`, `masthead-dataform`, `masthead-dataplex`, `masthead-retro` | `false` |
| `create_pool` | Create the workload identity pool. `false` adds the Masthead provider to an existing pool | `true` |
| `pool_id` | Workload identity pool ID, created or existing. A deleted pool's ID stays reserved for 30 days | `masthead` |
| `pool_project_id` | Project of the pool and provider | `project_id` |
| `provider_id` | Workload identity pool provider ID | `masthead-google` |
| `enable_apis` | Enable the IAM, IAM Credentials and Security Token Service APIs | `true` |

## Outputs

| Name | Description |
|---|---|
| `masthead_service_accounts` | Service accounts for the module's `masthead_service_accounts` input |
| `masthead_federation` | Provider and service accounts to share with Masthead. Contains no secrets |
