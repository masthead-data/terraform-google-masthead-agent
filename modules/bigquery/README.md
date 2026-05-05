# BigQuery Module

This module sets up the necessary infrastructure for Masthead Data to monitor BigQuery operations in your Google Cloud project.

## Resources Created

- **Pub/Sub Topic**: Receives BigQuery audit logs
- **Pub/Sub Subscription**: Allows Masthead agents to consume audit logs
- **Cloud Logging Sink**: Routes BigQuery audit logs to Pub/Sub
- **IAM Bindings**: Grants necessary permissions to Masthead service accounts
- **Custom IAM Role**: Grants `bigquery.datasets.listSharedDatasetUsage` permission
  - Organization-level role for folder monitoring (requires `organization_id`); gated by `create_organization_custom_roles` (default `true`). Set to `false` to manage the org-level role and binding externally.
  - Project-level role for project mode; always created (not affected by `create_organization_custom_roles`).

## Requirements

- **Organization Mode** with `create_organization_custom_roles = true`: `organization_id` must be provided to create the organization-level custom IAM role.
