# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.2.6] - 2025-09-25

### Removed

- **Dataplex IAM**: Removed `roles/dataplex.storageDataReader` role from Dataplex service account permissions

## [0.2.5] - 2025-08-26

### Removed

- **Custom IAM Role**: Removed custom role for Dataplex locations access

## [0.2.4] - 2025-07-23

### Added

- **Optional API Management**: Added `enable_apis` variable to control whether modules enable required Google Cloud APIs (enabled by default)

## [0.2.3] - 2025-07-12

### Added

- Added `roles/logging.privateLogViewer` role as optional for Masthead service account.

## [0.2.2] - 2025-07-11

### Removed

- Removed provider configuration to align with Terraform module best practices.

## [0.2.1] - 2025-07-01

### Removed

- Removed `roles/logging.privateLogViewer` permissions for Masthead service account.

## [0.2.0] - 2025-06-11

### Added

- **Conditional Module Deployment**: Added ability to enable/disable individual modules via `enable_modules` variable
- **Resource Labels**: Added `labels` variable to apply custom labels to all resources

### Fixed

- **Service Management**: Added `disable_on_destroy` and `disable_dependent_services` configuration for `google_project_service` resources

### Security

- **IAM Optimization**: Switched from `google_iam_member` to `google_pubsub_topic_iam_member` for more specific Pub/Sub permissions
- **Logging Sink Security**: Changed `unique_writer_identity` to `true` for better security isolation
- **IAM Security Enhancement**: Moved Masthead subscriber role from project level to specific subscription level for improved security isolation

### Migration Guide from 0.1.3

To upgrade from version 0.1.3 to the current version - update variable declaration:

**Before:**

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  project_id = "YOUR_PROJECT_ID"
}
```

**After:**

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  project_id = "YOUR_PROJECT_ID"

  # Optional: Enable only specific modules
  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }
}
```

## [0.1.3] - 2025-05-26

### Added

- Analytics Hub permissions

### Removed

- `project_number` variable is removed. Use `project_id` instead.

## [0.1.2] - 2025-04-10

## [0.1.1] - 2025-04-10

## [0.1.0] - 2025-03-31

### Added

- Basic BigQuery monitoring setup
- Dataform integration
- Dataplex monitoring

[Unreleased]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.2.6...HEAD
[0.2.6]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.1.3...v0.2.0
[0.1.3]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/masthead-data/terraform-google-masthead-agent/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/masthead-data/terraform-google-masthead-agent/releases/tag/v0.1.0
