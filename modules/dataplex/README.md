# Dataplex Module

This module sets up the necessary infrastructure for Masthead Data to monitor Dataplex operations in your Google Cloud project.

## Resources Created

- **Pub/Sub Topic**: Receives Dataplex audit logs
- **Pub/Sub Subscription**: Allows Masthead agents to consume audit logs
- **Cloud Logging Sink**: Routes Dataplex audit logs to Pub/Sub
- **Custom IAM Role**: Dataplex locations access permissions
- **IAM Bindings**: Grants necessary permissions to Masthead service accounts

## APIs Enabled

- `pubsub.googleapis.com`
- `logging.googleapis.com`
- `dataplex.googleapis.com`
- `bigquery.googleapis.com`

## Required Variables

- `project_id`: Your GCP project ID
- `masthead_service_accounts`: Object containing Masthead service account emails

## Optional Variables

- `labels`: Labels to apply to all resources

## Outputs

- `pubsub_topic_id`: ID of the created Pub/Sub topic
- `pubsub_subscription_id`: ID of the created subscription
- `logging_sink_id`: ID of the created logging sink
- `logging_sink_writer_identity`: Writer identity for the logging sink
- `custom_role_id`: ID of the custom IAM role for Dataplex locations
