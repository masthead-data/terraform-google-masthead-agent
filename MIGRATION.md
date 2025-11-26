# Migration Guide: v0.2.x to v0.3.0

This guide helps you migrate from the previous single-project architecture to the new multi-mode architecture that supports folder-level and project-level configurations.

## Breaking Changes

### Variable Changes

#### Renamed Variables
- `project_id` is now **optional** and only used in **Integrated Mode**

#### New Variables
- `folder_id` - For enterprise/folder-level deployments
- `deployment_project_id` - Where Pub/Sub infrastructure is created in enterprise mode
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

### Path 1: Continue with Single Project (Integrated Mode)

**No changes required!** Your existing configuration will continue to work:

```hcl
# Before (v0.2.x) - Still works in v0.3.0
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  project_id = "my-project"
  # ... rest of config
}
```

### Path 2: Upgrade to Enterprise Mode (Folder-Level)

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
  deployment_project_id = "my-data-project"    # Same or different project

  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }
}
```

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
   terraform plan
   ```

   You will see:
   - Existing project-level sinks will be **destroyed**
   - New folder-level sinks will be **created**
   - Pub/Sub topics and subscriptions may be recreated (depends on project)
   - IAM bindings will move from project to folder level

4. **Apply with caution**
   ```bash
   terraform apply
   ```

5. **Verify**
   - Check that folder-level sinks are created
   - Verify IAM bindings at folder level
   - Test that logs are flowing to Pub/Sub

### Path 3: Hybrid Mode (Folder + Additional Projects)

If you have a folder but also need to monitor some specific projects:

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  folder_id              = "folders/123456789"
  deployment_project_id  = "central-logging-project"
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

### Resource Recreation

When migrating from integrated to enterprise mode:

- **Log Sinks**: Project-level sinks will be destroyed and folder-level sinks created
- **Pub/Sub**: Topics and subscriptions will be recreated if `deployment_project_id` differs from old `project_id`
- **IAM Bindings**: Will move from project-level to folder-level
- **Potential Data Loss**: Brief interruption in log collection during migration

### Recommendations

1. **Test in non-production first**: Try the migration in a dev/test environment
2. **Plan during low-traffic period**: Minimize impact of brief logging interruption
3. **Monitor after migration**: Verify logs are flowing correctly
4. **Keep backups**: Maintain Terraform state backups

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

### Integrated Mode (no change needed)
- Same as before: project-level IAM and logging permissions

### Enterprise Mode (new requirements)
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
- Enterprise mode with folder-level logging
- Hybrid mode for folder + additional projects
- Shared logging infrastructure module
- Validation for deployment mode selection
- New outputs: `deployment_mode`, `folder_id`, `monitored_project_ids`

### Changed
- `project_id` is now optional (required for integrated mode only)
- All service modules refactored to use shared infrastructure
- IAM bindings now support both folder and project levels
- Output structure changed for `logging_sink_id` and `logging_sink_writer_identity`

### Deprecated
- None (backward compatible for integrated mode)

### Removed
- None

### Fixed
- None
