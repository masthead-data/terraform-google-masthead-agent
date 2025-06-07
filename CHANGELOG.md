# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.2.0 (2025-06-07)

### Features

- **Conditional Module Deployment**: Added ability to enable/disable individual modules via `enable_modules` variable
- **Regional Configuration**: Added `region` variable to specify GCP region for resources
- **Resource Naming**: Added `resource_prefix` variable for customizable resource naming
- **Resource Labels**: Added `labels` variable to apply custom labels to all resources
- **Comprehensive Outputs**: Added detailed outputs for all created resources
- **Regional Restrictions**: Restricted Pub/Sub topics to specified region
- **Example Configuration**: Added `terraform.tfvars.example` file
- **Logging Sink Security**: Changed `unique_writer_identity` to `true` for better security isolation

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

  # Optional: Configure service accounts if different from defaults
  masthead_service_accounts = {
    bigquery_sa = "your-custom-sa@your-project.iam.gserviceaccount.com"
    # ... other service accounts
  }

  # Optional: Enable only specific modules
  enable_modules = {
    bigquery      = true
    dataform      = false
    dataplex      = true
    analytics_hub = false
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
