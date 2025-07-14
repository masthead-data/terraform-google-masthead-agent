# Basic Usage Example

This example demonstrates the minimal configuration needed to use the `terraform-google-masthead-agent` module with all default settings.

## What This Example Does

- Deploys all modules (BigQuery, Dataform, Dataplex, Analytics Hub) with default configurations
- Uses minimal required variables
- Applies no labeling for resource management
- Demonstrates the simplest way to get started with the module

## Prerequisites

1. **Google Cloud Project**: A GCP project where you have appropriate permissions
2. **Terraform**: Version >= 1.5.7
3. **Google Provider**: Version >= 6.13.0
4. **Authentication**: Configure authentication to Google Cloud via `gcloud auth application-default login`

## Required Permissions

Your account needs the following IAM permissions in the target GCP project:

- `resourcemanager.projects.setIamPolicy`
- `pubsub.topics.create`
- `pubsub.subscriptions.create`
- `logging.sinks.create`
- `iam.roles.create`

## Usage

1. **Edit terraform.tfvars with your project ID:**

   ```hcl
   project_id = "your-actual-project-id"
   ```

2. **Run Terraform:**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## What Gets Created

This example will create:

- **BigQuery Module**: Pub/Sub topic, subscription, and logging sink for BigQuery audit logs
- **Dataform Module**: Pub/Sub topic, subscription, and logging sink for Dataform audit logs
- **Dataplex Module**: Pub/Sub topic, subscription, logging sink, and custom IAM role for Dataplex audit logs
- **Analytics Hub Module**: IAM role binding for Masthead service account

## Cleanup

To destroy all resources created by this example:

```bash
terraform destroy
```

## Next Steps

Once you're comfortable with this basic example, consider exploring:

- [Advanced Example](../advanced/) - production-ready configuration with comprehensive labeling
