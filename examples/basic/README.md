# Basic Usage Example

This example demonstrates minimal configuration for the `terraform-google-masthead-agent` module using default settings.

What this example does:

- Deploys all modules (BigQuery, Dataform, Dataplex, Analytics Hub) with defaults
- Uses minimal required variables
- No custom labeling applied
- Simplest way to get started

## Prerequisites

1. **Google Cloud Project** where you have appropriate roles

    - `roles/resourcemanager.projectIamAdmin`
    - `roles/pubsub.admin`
    - `roles/logging.admin`
    - `roles/iam.roleAdmin`

2. **Authentication** to Google Cloud (e.g. with `gcloud auth application-default login`)

## Usage

1. **Edit terraform.tfvars with your project ID**

2. **Run Terraform:**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Cleanup

To destroy all resources created by this example:

```bash
terraform destroy
```

## Next Steps

Once you're comfortable with this basic example, consider exploring a [full example](../full/).
