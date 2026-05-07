# Analytics Hub Module

This module sets up the necessary infrastructure for Masthead Data to monitor Analytics Hub operations in your Google Cloud project.

## Resources Created

- **IAM Bindings**: Grants necessary permissions to Masthead service accounts
- **Custom IAM Role**: Grants `analyticshub.listings.viewSubscriptions` permission
  - Organization-level role for folder monitoring (requires `organization_id`); gated by `create_organization_custom_roles`.
  - Project-level role for project mode.

## Requirements

- **Organization Mode**: `organization_id` must be provided to create the organization-level custom IAM role.
