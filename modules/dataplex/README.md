# Dataplex Module

This module sets up the necessary infrastructure for Masthead Data to monitor Dataplex operations in your Google Cloud project.

## Resources Created

- **Pub/Sub Topic**: Receives Dataplex audit logs
- **Pub/Sub Subscription**: Allows Masthead agents to consume audit logs
- **Cloud Logging Sink**: Routes Dataplex audit logs to Pub/Sub
- **Custom IAM Role**: Custom role for Dataplex locations access
- **IAM Bindings**: Grants necessary permissions to Masthead service accounts
