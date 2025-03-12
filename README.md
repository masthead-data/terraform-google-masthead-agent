# masthead-deployment

Tools for Masthead deployment into customer's environment.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FMasthead-Data%2Fmasthead-deployment)

## Overview

This repository contains Terraform configurations to deploy the integration resources for Masthead Data in Google Cloud.

## Modules

### Masthead Data Application

- Enables required Google Cloud services: Pub/Sub, IAM, Logging.
- Creates Pub/Sub topic and subscription.
- Creates a custom IAM role for BigQuery schema reading.
- Grants Pub/Sub Subscriber and custom BigQuery schema reading roles to the Masthead service account.
- Creates a log sink for BigQuery operations.
- Grants Pub/Sub Publisher role to the Cloud Logging service account.
- Grants a Private Logs Viewer role to the Masthead Retro service account.

### Dataform

- Enables required Google Cloud services: Pub/Sub, IAM, Logging.
- Creates Pub/Sub topic and subscription.
- Grants Pub/Sub Subscriber and Dataform Viewer roles to the Masthead service account.
- Creates a log sink for Dataform operations.
- Grants Pub/Sub Publisher role to the Cloud Logging service account.

### Dataplex

- Enables required Google Cloud services: Pub/Sub, IAM, Logging.
- Creates Pub/Sub topic and subscription.
- Creates a custom IAM role for Dataplex locations.
- Grants
  - Pub/Sub Subscriber,
  - BigQuery Job User,
  - Dataplex DataScan Administrator,
  - Dataplex Storage Data Reader,
  - and custom Dataplex locations
  roles to the Masthead service account.
- Creates a log sink for Dataplex operations.
- Grants Pub/Sub Publisher role to the Cloud Logging service account.

## Usage

1. Ensure you have [Terraform installed](https://developer.hashicorp.com/terraform/install).
2. Configure your [gcloud CLI](https://cloud.google.com/sdk/gcloud#download_and_install_the) with your Google Cloudcredentials.
3. Run `terraform init` to initialize the configuration.
4. Run `terraform plan` to create an execution plan.
5. Run `terraform apply` to deploy the infrastructure.

! Important

The credentials used in Terraform must have the following roles:

- `roles/logging.configWriter` - Access to manage configuration of logging resources.


The deployment process requires the following variables to be set:

- `project_id` - Google Cloud project ID where the resources will be deployed.
- `project_number` - Google Cloud project number.

### Complete Deployment Example

To run a full deployment, use the following commands:

```bash
# Initialize Terraform configuration
terraform init

# Create an execution plan and save it to a file
terraform plan -out=tfplan

# Apply the planned changes to deploy the complete infrastructure
terraform apply tfplan
```

### Partial Deployment Example

To deploy only the Masthead Data application, use the following commands:

```bash
# Initialize Terraform configuration
terraform init

# Create an execution plan and save it to a file
terraform plan -out=tfplan -target=module.app

# Apply the planned changes to deploy the Masthead Data application
terraform apply tfplan
```

For step-by-step guide, refer to the [manual integration documentation](https://docs.mastheadata.com/saas-manual-resource-creation-google-cloud-+-bigquery).
