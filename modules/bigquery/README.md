# BigQuery Module

This module sets up the necessary infrastructure for Masthead Data to monitor BigQuery operations in your Google Cloud project.

## Resources Created

- **Pub/Sub Topic**: Receives BigQuery audit logs
- **Pub/Sub Subscription**: Allows Masthead agents to consume audit logs
- **Cloud Logging Sink**: Routes BigQuery audit logs to Pub/Sub
- **IAM Bindings**: Grants necessary permissions to Masthead service accounts
- **Custom IAM Role**: Grants `bigquery.datasets.listSharedDatasetUsage` permission
  - Organization-level role for folder monitoring (requires `organization_id`)
  - Project-level role for project mode

## Requirements

- **Organization Mode**: `organization_id` must be provided to create organization-level custom IAM role
