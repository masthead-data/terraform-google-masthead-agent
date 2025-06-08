# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.2.0 (2025-06-07)

### Features

- **Conditional Module Deployment**: Added ability to enable/disable individual modules via `enable_modules` variable
- **Resource Labels**: Added `labels` variable to apply custom labels to all resources
- **Logging Sink Security**: Changed `unique_writer_identity` to `true` for better security isolation
- **Service Management**: Added `disable_on_destroy` and `disable_dependent_services` configuration for `google_project_service` resources
- **IAM Optimization**: Switched from `google_iam_member` to `google_pubsub_topic_iam_member` for more specific Pub/Sub permissions

### Migration Guide from 0.1.3

To upgrade from version 0.1.3 to the current version - update variable declaration:

**Before:**

```hcl
module "masthead_agent" {
  source     = "..."
  project_id = "your-project"
}
```

**After:**

```hcl
module "masthead_agent" {
  source     = "..."
  project_id = "your-project"

  # Optional: Enable only specific modules
  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }
}
```

## 0.1.3 (2025-05-26)

### Features

- Analytics Hub permissions

### Deprecations

- `project_number` variable is removed. Use `project_id` instead.

## 0.1.2 (2025-04-10)

## 0.1.1 (2025-04-10)

## 0.1.0 (2025-03-31)

### Features

- Basic BigQuery monitoring setup
- Dataform integration
- Dataplex monitoring
