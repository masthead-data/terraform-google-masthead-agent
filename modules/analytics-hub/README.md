# Analytics Hub Module

This module sets up the necessary infrastructure for Masthead Data to monitor Analytics Hub operations in your Google Cloud project.

## Resources Created

- **IAM Bindings**: Grants the following roles to Masthead service accounts:
  - `roles/analyticshub.viewer` — Read-only access to Analytics Hub resources
  - `mastheadAnalyticsHubCustomRole` (custom) — See **Custom IAM Role** below
- **Custom IAM Role**: Grants the following custom permissions:
  - `analyticshub.listings.viewSubscriptions` — View subscriptions for Analytics Hub listings

## Requirements

- **Organization Mode**: `organization_id` must be provided to create the organization-level custom IAM role.
