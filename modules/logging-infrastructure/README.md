# Logging Infrastructure Module

This module creates the shared logging infrastructure for Masthead Agent, including:

- Pub/Sub topics and subscriptions
- Logging sinks (folder-level or project-level)
- IAM bindings for log delivery

## Features

- **Folder-level logging**: Create a single sink at the folder level to capture logs from all projects under the folder
- **Project-level logging**: Create individual sinks for specific projects
- **Mixed mode**: Use both folder-level and project-level sinks together
- **Centralized Pub/Sub**: All logs are published to a single topic in the deployment project

## Usage

### Folder-level (Organization)

```hcl
module "bigquery_logging" {
  source = "./modules/logging-infrastructure"

  pubsub_project_id       = "my-deployment-project"
  monitored_folder_ids    = ["folders/123456789"] # or ["123456789"]
  component_name          = "bigquery"
  topic_name              = "masthead-topic"
  subscription_name       = "masthead-agent-subscription"
  sink_name               = "masthead-agent-sink"
  log_filter              = "..."
  masthead_service_account = "masthead-data@masthead-prod.iam.gserviceaccount.com"
}
```

### Project-level (Project)

```hcl
module "bigquery_logging" {
  source = "./modules/logging-infrastructure"

  pubsub_project_id        = "my-project"
  monitored_project_ids    = ["my-project"]
  component_name           = "bigquery"
  topic_name               = "masthead-topic"
  subscription_name        = "masthead-agent-subscription"
  sink_name                = "masthead-agent-sink"
  log_filter               = "..."
  masthead_service_account = "masthead-data@masthead-prod.iam.gserviceaccount.com"
}
```

### Mixed (Folder + Additional Projects)

```hcl
module "bigquery_logging" {
  source = "./modules/logging-infrastructure"

  pubsub_project_id       = "my-deployment-project"
  monitored_folder_ids    = ["folders/123456789"] # or ["123456789"]
  monitored_project_ids   = ["special-project-1", "special-project-2"]
  component_name          = "bigquery"
  topic_name              = "masthead-topic"
  subscription_name       = "masthead-agent-subscription"
  sink_name               = "masthead-agent-sink"
  log_filter              = "..."
  masthead_service_account = "masthead-data@masthead-prod.iam.gserviceaccount.com"
}
```
