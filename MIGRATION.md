# Migration Guide: v0.2.x to v0.3.0

This guide helps you migrate from the previous single-project architecture to the new multi-mode architecture that supports folder-level and project-level configurations.

## Breaking Changes

### Variable Changes

#### Renamed Variables
- `project_id` is now **optional** and only used in **Project Mode**

#### New Variables
- `folder_id` - For organization/folder-level deployments
- `deployment_project_id` - Where Pub/Sub infrastructure is created in organization mode
- `monitored_project_ids` - List of additional projects to monitor

### Module Interface Changes

All service modules (BigQuery, Dataform, Dataplex) now use:
- `pubsub_project_id` instead of `project_id`
- `folder_id` (optional)
- `monitored_project_ids` (optional)

### Output Changes

- `project_id` output renamed to `pubsub_project_id`
- New outputs: `deployment_mode`, `folder_id`, `monitored_project_ids`
- `logging_sink_id` and `logging_sink_writer_identity` now return different structures based on mode

## Migration Paths

### Path 1: Continue with Single Project (Project Mode)

**Configuration stays the same**, but resources will be recreated due to module restructuring:

```hcl
# Before (v0.2.x) - Configuration compatible with v0.3.0
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  project_id = "my-project"
  # ... rest of config
}
```

**Important**: Even in project mode, resources will be recreated because the internal module structure changed. The configuration syntax is backward compatible, but Terraform will see different resource addresses.

### Path 2: Upgrade to Organization Mode (Folder-Level)

If you want to move to folder-level monitoring:

#### Before (v0.2.x)
```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = "0.2.8"

  project_id = "my-data-project"

  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }
}
```

#### After (v0.3.0)
```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  # Remove project_id, add folder_id and deployment_project_id
  folder_id             = "folders/123456789"  # Your folder ID
  deployment_project_id = "my-data-project"    # Use same project ID
  organization_id       = "123456789"          # Required for Analytics Hub

  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }
}
```

**Note**: Using the same project ID keeps Pub/Sub in the same location, but all resources will still be recreated due to new module paths.

#### Migration Steps

1. **Backup your Terraform state**
   ```bash
   terraform state pull > backup-state.json
   ```

2. **Update your configuration**
   - Replace `project_id` with `folder_id` and `deployment_project_id`
   - Update version constraint to `>=0.3.0`

3. **Plan the changes**
   ```bash
   terraform plan -out=migration.tfplan
   ```

   Expected changes (~25-35 resources):
   - **Destroyed**: All existing resources (project-level sinks, project IAM, Pub/Sub, etc.)
   - **Created**: All new resources (folder-level sinks, folder IAM, Pub/Sub, etc.)
   - Even resources in the same project will be recreated due to module path changes

4. **Review the plan**
   ```bash
   terraform show migration.tfplan | grep -E "(# module|will be created|will be destroyed)"
   ```

5. **Apply during maintenance window**
   ```bash
   terraform apply migration.tfplan
   ```

6. **Verify immediately**
   - Check folder-level sinks exist: `gcloud logging sinks list --folder=123456789`
   - Verify IAM at folder level
   - Test logs flowing to Pub/Sub within 5 minutes

### Path 3: Hybrid Mode (Folder + Additional Projects)

If you have a folder but also need to monitor some specific projects:

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  folder_id              = "folders/123456789"
  deployment_project_id  = "central-logging-project"
  organization_id        = "123456789"  # Required for Analytics Hub
  monitored_project_ids  = [
    "special-project-1",
    "external-project-2"
  ]

  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }
}
```

## Important Notes

### Resource Recreation - ALL Resources Will Be Recreated

**Critical**: Due to the internal module restructuring in v0.3.0, **all resources will be recreated** regardless of your migration path:

#### Why Resources Are Recreated
The module structure changed from:
- `module.bigquery.google_pubsub_topic.logs_topic`

To:
- `module.bigquery[0].module.logging_infrastructure.google_pubsub_topic.logs_topic`

Terraform sees these as completely different resources.

#### What Gets Recreated

**Project Mode (same configuration)**:
- ✅ **Configuration**: Unchanged, backward compatible
- ⚠️ **Resources**: ALL recreated (new module paths)
- ✅ **Same Project**: Pub/Sub topics/subscriptions in same project
- ✅ **Same Scope**: Sinks and IAM remain project-level
- ⏱️ **Downtime**: ~30-60 seconds during sink recreation

**Organization Mode (folder-level)**:
- ⚠️ **Resources**: ALL recreated (module paths + scope change)
- 🔄 **Scope Change**: Sinks move from project → folder level
- 🔄 **IAM Change**: Bindings move from project → folder level
- 🔄 **Custom Roles**: Analytics Hub role moves to organization level
- ⏱️ **Downtime**: ~30-60 seconds during sink recreation

### Migration Strategies

#### Option A: Use Moved Blocks (Recommended - Zero Recreation)

**NEW**: Use the provided script to generate `moved` blocks that preserve your existing resources:

```bash
# 1. Backup your state first
terraform state pull > backup-state.json

# 2. Generate moved blocks from your current state
./generate-moved-blocks.sh

# 3. Review the generated moved-blocks.tf file
cat moved-blocks.tf

# 4. Update your configuration to v0.3.0
# (Keep same variables for project mode, or add folder_id for organization)

# 5. Upgrade Terraform providers
terraform init -upgrade

# 6. Plan - should show moves, not recreations
terraform plan

# 7. Apply the moves
terraform apply

# 8. Clean up the moved blocks file
rm moved-blocks.tf
```

**Downtime**: Zero! Resources are preserved through Terraform moves
**Risk**: Very low - just renames in state
**Best for**: Production environments where downtime must be avoided

**Note**: The script works for standard deployments. Complex configurations may need manual adjustment of the generated `moved-blocks.tf`.

#### Option B: Accept Recreation (Simple)

If you prefer a clean slate or have simple dev/test environments:

1. **Backup state**: `terraform state pull > backup-state.json`
2. **Update configuration**: Change version to `>=0.3.0`
3. **Plan**: `terraform plan -out=migration.tfplan`
4. **Review carefully**: Expect ~20-30 resources to be recreated
5. **Apply during maintenance window**: `terraform apply migration.tfplan`
6. **Verify**: Check logs are flowing within 5 minutes

**Downtime**: 30-60 seconds for log collection
**Risk**: Low (resources recreated with same/similar names)
**Best for**: Dev/test environments, non-critical deployments

### Recommendations

1. **Use Option A (moved blocks)**: Zero downtime, preserves all resources
2. **Use the migration script**: `./generate-moved-blocks.sh` automates the process
3. **Test in non-production first**: Validate the migration process
4. **Keep backups**: Save state before migration
5. **Monitor after**: Verify logs flowing within first hour

**For production environments**: Use Option A with moved blocks
**For dev/test environments**: Either Option A or B is fine

### Rollback Plan

If you need to rollback:

1. Restore your Terraform state backup
   ```bash
   terraform state push backup-state.json
   ```

2. Revert your configuration to use `project_id`

3. Pin to the old version
   ```hcl
   version = "0.2.8"
   ```

## Required Permissions for Migration

### Project Mode (no change needed)
- Same as before: project-level IAM and logging permissions

### Organization Mode (new requirements)
You need these **additional** permissions:
- `resourcemanager.folders.get`
- `resourcemanager.folders.setIamPolicy`
- `logging.sinks.create` (at folder level)
- `logging.sinks.delete` (to remove old project sinks)

## Compatibility Matrix

| Version | Single Project | Folder-Level | Hybrid Mode |
|---------|---------------|--------------|-------------|
| 0.2.x   | ✅            | ❌           | ❌          |
| 0.3.0+  | ✅            | ✅           | ✅          |

## Support

If you encounter issues during migration:
1. Check the [examples/](../examples/) directory for reference configurations
2. Review the updated [README.md](../README.md)
3. Contact Masthead Data support

## Changelog Summary

### Added
- Organization mode with folder-level logging
- Hybrid mode for folder + additional projects
- Shared logging infrastructure module
- Validation for deployment mode selection
- New outputs: `deployment_mode`, `folder_id`, `monitored_project_ids`

### Changed
- `project_id` is now optional (required for project mode only)
- All service modules refactored to use shared infrastructure
- IAM bindings now support both folder and project levels
- Output structure changed for `logging_sink_id` and `logging_sink_writer_identity`

### Deprecated
- None (backward compatible for project mode)

### Removed
- None

### Fixed
- None
