# Masthead Data Terraform Module for Google Cloud

[![Terraform Module](https://img.shields.io/badge/Terraform-Module-blue.svg)](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)

[![Open in Google Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FMasthead-Data%2Fterraform-google-masthead-agent)

This Terraform module deploys infrastructure for Masthead Data to monitor Google Cloud services (BigQuery, Dataform, Dataplex, Analytics Hub) using Pub/Sub topics, Cloud Logging sinks, and IAM bindings.

## Deployment Modes

The module supports three deployment modes to fit different organizational structures:

### 📦 Project Mode (Single Project)

For single-project setups. All resources (logs, Pub/Sub, IAM) are created in one project.

### 🏢 Folder Mode (Folder/Multi-Project)

For organizations using GCP folders or monitoring multiple projects. Creates centralized Pub/Sub infrastructure in a dedicated deployment project with folder-level or project-level log sinks.

### 🔄 Hybrid Mode (Folder + Project)

Combines folder-level monitoring with project-level Pub/Sub. Useful for specific use cases requiring both configurations.

## Usage Examples

### Project Mode - Single Project

Simplest setup for single-project deployments:

```hcl
variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created"
}

provider "google" {
  project = var.project_id
}

module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  # Project mode: single project
  project_id = var.project_id
}
```

### Folder Mode - Folder-Level Monitoring

For organizations using GCP folders:

```hcl
variable "folder_id" {
  type        = string
  description = "GCP folder ID to monitor"
}

variable "deployment_project_id" {
  type        = string
  description = "Project where Pub/Sub will be deployed"
}

provider "google" {
  project = var.deployment_project_id
}

module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  # Folder mode: folder + deployment project
  folder_id             = var.folder_id  # e.g., "folders/123456789" or "123456789"
  deployment_project_id = var.deployment_project_id

  enable_apis                  = true
  enable_privatelogviewer_role = true

  labels = {
    environment = "production"
    mode        = "folder"
  }
}
```

### Hybrid Mode - Folder + Additional Projects

Monitor a folder plus specific additional projects:

```hcl
variable "folder_id" {
  type        = string
  description = "GCP folder ID to monitor"
}

variable "deployment_project_id" {
  type        = string
  description = "Project where Pub/Sub will be deployed"
}

provider "google" {
  project = var.deployment_project_id
}

module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  # Hybrid mode: folder + additional projects
  folder_id              = var.folder_id
  deployment_project_id  = var.deployment_project_id
  monitored_project_ids  = [
    "special-project-1",
    "external-data-project"
  ]

  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }

  labels = {
    environment = "production"
    mode        = "hybrid"
  }
}
```

### Full Configuration Example

Complete configuration with all options:

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.0"

  # Choose ONE mode:
  # PROJECT: Set project_id only
  project_id = var.project_id

  # FOLDER: Set folder_id + deployment_project_id
  # folder_id             = var.folder_id
  # deployment_project_id = var.deployment_project_id

  # HYBRID: Set folder_id + deployment_project_id + monitored_project_ids
  # folder_id             = var.folder_id
  # deployment_project_id = var.deployment_project_id
  # monitored_project_ids = ["project-1", "project-2"]

  # Module configuration
  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }

  # Optional features
  enable_apis                  = true
  enable_privatelogviewer_role = true  # For retrospective log export
  enable_datascan_editing      = false # Dataplex DataScan editing permissions

  # Custom service accounts (optional, uses defaults if not specified)
  masthead_service_accounts = {
    bigquery_sa = "masthead-data@masthead-prod.iam.gserviceaccount.com"
    dataform_sa = "masthead-dataform@masthead-prod.iam.gserviceaccount.com"
    dataplex_sa = "masthead-dataplex@masthead-prod.iam.gserviceaccount.com"
    retro_sa    = "retro-data@masthead-prod.iam.gserviceaccount.com"
  }

  # Labels for governance and cost management
  labels = {
    environment = "production"
    team        = "data"
    cost_center = "engineering"
    monitoring  = "masthead"
  }
}
```

## Architecture

### Project Mode

```text
┌─────────────────────────────────────┐
│        Single GCP Project           │
│                                     │
│  ┌──────────────┐  ┌─────────────┐ │
│  │ Log Sinks    │→ │  Pub/Sub    │ │
│  │ (Project)    │  │  Topics     │ │
│  └──────────────┘  └─────────────┘ │
│         ↓                ↓          │
│  ┌──────────────────────────────┐  │
│  │      IAM Bindings            │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Folder Mode

```text
┌────────────────────────────────────────┐
│         GCP Folder                     │
│  ┌──────────────────────────────────┐  │
│  │  All Child Projects (captured)   │  │
│  └──────────────────────────────────┘  │
│              ↓                         │
│  ┌──────────────────────────────────┐  │
│  │  Folder-Level Log Sink           │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│    Deployment Project                  │
│  ┌──────────────────────────────────┐  │
│  │     Pub/Sub Topics & Subs        │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### Hybrid Mode

```text
┌────────────────────────────────────────┐
│         GCP Folder                     │
│  ┌──────────────────────────────────┐  │
│  │  All Child Projects (captured)   │  │
│  └──────────────────────────────────┘  │
│              ↓                         │
│  ┌──────────────────────────────────┐  │
│  │  Folder-Level Log Sink           │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│ Additional Projects (outside folder)   │
│  ┌──────────────────────────────────┐  │
│  │  Project-Level Log Sinks         │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│    Deployment Project                  │
│  ┌──────────────────────────────────┐  │
│  │     Pub/Sub Topics & Subs        │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

## IAM Permissions

### Project Mode

- IAM bindings applied at the **project level**
- Log sinks created at the **project level**

### Folder Mode

- IAM bindings applied at the **folder level** (inherited by all child projects)
- Log sinks created at the **folder level** with `include_children = true`

### Hybrid Mode

- IAM bindings applied at both **folder level** and **project level** (for additional projects)
- Log sinks created at both **folder level** and **project level**

## Required GCP Permissions

### For Project Mode

You need these permissions in the target project:

- `logging.sinks.create`
- `pubsub.topics.create`
- `pubsub.subscriptions.create`
- `iam.serviceAccounts.setIamPolicy`
- `resourcemanager.projects.setIamPolicy`

### For Folder/Hybrid Mode

You need these permissions at the folder level:

- `logging.sinks.create` (on folder)
- `resourcemanager.folders.setIamPolicy` (on folder)
- Plus project-level permissions for the deployment project (Pub/Sub)

## Examples

See the `examples/` directory for complete configuration examples:

- `project-mode.tfvars.example` - Single project setup
- `folder-mode.tfvars.example` - Folder-level setup
- `hybrid-mode.tfvars.example` - Folder + additional projects

## References

- [Masthead Data Documentation](https://docs.mastheadata.com/saas-manual-resource-creation-google-cloud-+-bigquery)
- [Module in Terraform Registry](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)
