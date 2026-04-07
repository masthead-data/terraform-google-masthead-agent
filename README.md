# Masthead Data Terraform Module for Google Cloud

[![Terraform Module](https://img.shields.io/badge/Terraform-Module-blue.svg)](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)

[![Open in Google Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FMasthead-Data%2Fterraform-google-masthead-agent)

This Terraform module deploys infrastructure for Masthead Data to monitor Google Cloud services (BigQuery, Dataform, Dataplex, Analytics Hub) using Pub/Sub topics, Cloud Logging sinks, and IAM bindings.

## 📦 Project Mode

For single-project setups. All resources (logs, Pub/Sub, IAM) are created in a monitored project.

**Use when:** You have a single project or a few projects to monitor.

### Example

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.1"

  # Project mode: single project
  project_id = "project-1"
}
```

### Required Permissions

**Target project:**

- `iam.roles.create`
- `logging.sinks.create`
- `pubsub.subscriptions.create`
- `pubsub.subscriptions.setIamPolicy`
- `pubsub.topics.create`
- `pubsub.topics.setIamPolicy`
- `resourcemanager.projects.setIamPolicy`
- `serviceusage.services.enable`

## 🏢 Organization Mode

For multi-project or folder-level monitoring. Creates centralized Pub/Sub infrastructure in a dedicated deployment project with folder-level and/or project-level log sinks.

**Supports:**

- One or more GCP folders (monitors all child projects)
- Additional individual projects (outside of folders)
- Any combination of folders and projects

**Use when:** You want to monitor multiple projects, use GCP folders, or need centralized log collection.

### Example

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

### Required Permissions

**Deployment project**:

- `pubsub.subscriptions.create`
- `pubsub.subscriptions.setIamPolicy`
- `pubsub.topics.create`
- `pubsub.topics.setIamPolicy`
- `serviceusage.services.enable`

**Each monitored project** (when `monitored_project_ids` is set):

- `iam.roles.create`
- `logging.sinks.create`
- `resourcemanager.projects.setIamPolicy`
- `serviceusage.services.enable`

**Each monitored folder**:

- `logging.sinks.create`
- `resourcemanager.folders.setIamPolicy`

**Organization level** (when `monitored_folder_ids` is set and `organization_id` is provided):

- `iam.roles.create`

## Documentation

- [Configuration](docs/configuration.md)
- [Architecture](docs/architecture.md)

## References

- [Masthead Data Documentation](https://docs.mastheadata.com/get-started/integrate-using-iac)
- [Module in Terraform Registry](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)
