# Advanced Example

This example demonstrates a comprehensive production-ready setup of the `terraform-google-masthead-agent` module with enhanced labeling.

## What This Example Does

- Deploys all modules with production-grade configuration
- Implements comprehensive resource labeling for governance and cost management
- Provides detailed configuration options for production environments

## Key Features

- **Comprehensive Labeling**
- **All Modules Enabled**: BigQuery, Dataform, Dataplex, and Analytics Hub
- **Enhanced Security**: Choose between enabling Private Log Viewer role or [exporting retrospective logs](https://docs.mastheadata.com/set-up/saas-manual-resource-creation-google-cloud-+-bigquery#export-retrospective-logs)
- **Governance Ready**: Compliance and monitoring labels for enterprise environments
- **Cost Management**: Cost center and business unit labels for billing allocation

## Prerequisites

1. **Google Cloud Project**: A production GCP project with appropriate governance
2. **Terraform**: Version >= 1.5.7
3. **Google Provider**: Version >= 6.13.0
4. **Authentication**: Production-grade authentication (service account recommended)
5. **Permissions**: Full set of IAM permissions for all modules

## Required Permissions

Your service account or user needs the following IAM permissions:

- `resourcemanager.projects.setIamPolicy`
- `iam.roles.create`
- `pubsub.topics.create`
- `pubsub.subscriptions.create`
- `logging.sinks.create`

## Usage

1. **Edit terraform.tfvars with your production configuration**

2. **Initialize Terraform**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Outputs

The example provides detailed outputs including:

- All module-specific resource IDs and configurations
- Production configuration summary
- Applied resource labels
- List of enabled modules
- Target project information

## Production Considerations

### Security

- Use service account authentication for automation
- Enable audit logging for all operations
- Review IAM permissions regularly

### Monitoring

- Set up alerts for resource creation/modification
- Monitor costs and usage patterns

### Governance

- Regularly review and update labels
- Implement compliance checks

## Cleanup

**Warning**: This will destroy production resources. Ensure you have proper backups and approvals.

```bash
terraform destroy
```
