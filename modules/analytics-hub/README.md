# Analytics Hub Module

This module sets up the necessary infrastructure for Masthead Data to monitor Analytics Hub operations in your Google Cloud project.

## Resources Created

- **IAM Bindings**: Grants necessary permissions to Masthead service accounts

## APIs Enabled

- `analyticshub.googleapis.com`

## Required Variables

- `project_id`: Your GCP project ID
- `masthead_service_accounts`: Object containing Masthead service account emails

## Optional Variables

- `labels`: Labels to apply to all resources

## Outputs

- `service_account_member`: Service account member granted Analytics Hub viewer permissions
- `granted_role`: IAM role granted to the service account
