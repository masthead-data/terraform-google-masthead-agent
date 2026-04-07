# Masthead Data Terraform Module for Google Cloud

[![Terraform Module](https://img.shields.io/badge/Terraform-Module-blue.svg)](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)

[![Open in Google Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FMasthead-Data%2Fterraform-google-masthead-agent)

This Terraform module deploys infrastructure for Masthead Data to monitor Google Cloud services (BigQuery, Dataform, Dataplex, Analytics Hub) using Pub/Sub topics, Cloud Logging sinks, and IAM bindings.

## Deployment Modes

The module supports two deployment modes:

### 📦 Project Mode

For single-project setups. All resources (logs, Pub/Sub, IAM) are created in a monitored project.

**Use when:** You have a single project or a few projects to monitor.

### 🏢 Organization Mode

For multi-project or folder-level monitoring. Creates centralized Pub/Sub infrastructure in a dedicated deployment project with folder-level and/or project-level log sinks.

**Supports:**
- One or more GCP folders (monitors all child projects)
- Additional individual projects (outside of folders)
- Any combination of folders and projects

**Use when:** You want to monitor multiple projects, use GCP folders, or need centralized log collection.

## Usage Examples

### Project Mode

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.1"

  # Project mode: single project
  project_id = "project-1"
}
```

### Organization Mode

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.1"

  # Organization mode: folders + additional projects
  monitored_folder_ids  = [
    "folders/111111111",
    "folders/222222222"
  ]
  monitored_project_ids = [
    "project-1",
    "project-2"
  ]
  deployment_project_id = "project-3"
  organization_id       = "123456789"  # Required for custom IAM roles on folders

  labels = {
    environment = "production"
  }
}
```

## Required GCP Permissions

### For Project Mode

You need these permissions in the target project:

- `logging.sinks.create`
- `pubsub.topics.create`
- `pubsub.subscriptions.create`
- `iam.serviceAccounts.setIamPolicy`
- `resourcemanager.projects.setIamPolicy`

### For Organization Mode

**When using folders**, you need these permissions at the folder level:

- `logging.sinks.create` (on folder)
- `resourcemanager.folders.setIamPolicy` (on folder)

**When using folders**, you need these permissions at the organization level:

- `iam.roles.create` (on organization) - Required for creating custom IAM roles

**Always required** for the deployment project:

- `pubsub.topics.create`
- `pubsub.subscriptions.create`
- `iam.serviceAccounts.setIamPolicy`
- `resourcemanager.projects.setIamPolicy`

### Documentation

- [Configuration](docs/configuration.md)
- [Architecture](docs/architecture.md)

## References

- [Masthead Data Documentation](https://docs.mastheadata.com/get-started/integrate-using-iac)
- [Module in Terraform Registry](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)
