# BigQuery Module

This module sets up the necessary infrastructure for Masthead Data to monitor BigQuery operations in your Google Cloud project.

## Resources Created

- **Pub/Sub Topic**: Receives BigQuery audit logs
- **Pub/Sub Subscription**: Allows Masthead agents to consume audit logs
- **Cloud Logging Sink**: Routes BigQuery audit logs to Pub/Sub
- **IAM Bindings**: Grants the following roles to Masthead service accounts:
  - `roles/bigquery.metadataViewer` — Read metadata of BigQuery resources
  - `roles/bigquery.resourceViewer` — View BigQuery resource configurations
  - `roles/resourcemanager.folderViewer` — View folder hierarchy _(folder mode only)_
  - `roles/logging.privateLogViewer` — Read private log entries _(only when `enable_privatelogviewer_role = true`)_
  - `mastheadBigQueryCustomRole` (custom) — See **Custom IAM Role** below
- **Custom IAM Role**: Grants the following custom permissions:
  - `bigquery.config.get` — Read BigQuery project-level configuration settings
  - `bigquery.datasets.listSharedDatasetUsage` — List shared dataset usage across projects

## Requirements

- **Organization Mode**: `organization_id` must be provided to create the organization-level custom IAM role.
