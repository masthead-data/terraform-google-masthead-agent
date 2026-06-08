# Dataplex Module

This module sets up the necessary infrastructure for Masthead Data to monitor Dataplex operations in your Google Cloud project.

## Resources Created

- **Pub/Sub Topic**: Receives Dataplex audit logs
- **Pub/Sub Subscription**: Allows Masthead agents to consume audit logs
- **Cloud Logging Sink**: Routes Dataplex audit logs to Pub/Sub
- **IAM Bindings**: Grants the following predefined roles to Masthead service accounts:
  - `roles/dataplex.dataProductsViewer` — View Dataplex data products
  - `roles/dataplex.dataScanDataViewer` — View data scan results and profiles
  - `roles/dataplex.dataScanEditor` — Create and manage data scans _(only when `enable_datascan_editing = true`)_
  - `roles/dataplex.storageDataReader` — Read underlying Cloud Storage data for datascan execution _(only when `enable_datascan_editing = true`)_
  - `roles/bigquery.jobUser` — Run BigQuery jobs for datascan execution _(only when `enable_datascan_editing = true`)_
