# Masthead Data Agent Terraform Module for Google Cloud

[![Terraform Module](https://img.shields.io/badge/Terraform-Module-blue.svg)](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)

[![Open in Google Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FMasthead-Data%2Fterraform-google-masthead-agent)

This Terraform module deploys infrastructure for Masthead Data to monitor Google Cloud services (BigQuery, Dataform, Dataplex, Analytics Hub) using Pub/Sub topics, Cloud Logging sinks, and IAM bindings.

## Usage

- [Basic](./basic/) - Minimal configuration with all defaults
- [Full](./full/) - Comprehensive setup with enhanced configurations

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.13.0 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_modules"></a> [enable\_modules](#input\_enable\_modules) | Enable/disable specific modules | <pre>object({<br/>    bigquery      = bool<br/>    dataform      = bool<br/>    dataplex      = bool<br/>    analytics_hub = bool<br/>  })</pre> | <pre>{<br/>  "analytics_hub": true,<br/>  "bigquery": true,<br/>  "dataform": true,<br/>  "dataplex": true<br/>}</pre> | no |
| <a name="input_enable_privatelogviewer_role"></a> [enable\_privatelogviewer\_role](#input\_enable\_privatelogviewer\_role) | Enable Private Log Viewer role for Masthead service account in BigQuery module | `bool` | `true` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to all resources | `map(string)` | <pre>{<br/>  "managed_by": "terraform",<br/>  "module": "masthead-agent"<br/>}</pre> | no |
| <a name="input_masthead_service_accounts"></a> [masthead\_service\_accounts](#input\_masthead\_service\_accounts) | Masthead service account emails for different services | <pre>object({<br/>    bigquery_sa = string<br/>    dataform_sa = string<br/>    dataplex_sa = string<br/>    retro_sa    = string<br/>  })</pre> | <pre>{<br/>  "bigquery_sa": "masthead-data@masthead-prod.iam.gserviceaccount.com",<br/>  "dataform_sa": "masthead-dataform@masthead-prod.iam.gserviceaccount.com",<br/>  "dataplex_sa": "masthead-dataplex@masthead-prod.iam.gserviceaccount.com",<br/>  "retro_sa": "retro-data@masthead-prod.iam.gserviceaccount.com"<br/>}</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project ID where resources will be created | `string` | n/a | yes |
## Resources

No resources.
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_analytics_hub"></a> [analytics\_hub](#output\_analytics\_hub) | Analytics Hub module outputs |
| <a name="output_bigquery"></a> [bigquery](#output\_bigquery) | BigQuery module outputs |
| <a name="output_dataform"></a> [dataform](#output\_dataform) | Dataform module outputs |
| <a name="output_dataplex"></a> [dataplex](#output\_dataplex) | Dataplex module outputs |
| <a name="output_enabled_modules"></a> [enabled\_modules](#output\_enabled\_modules) | List of enabled modules |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | The GCP project ID where resources were created |
<!-- END_TF_DOCS -->

## References

- [Masthead Data Documentation](https://docs.mastheadata.com/saas-manual-resource-creation-google-cloud-+-bigquery)
- [Module in Terraform Registry](https://registry.terraform.io/modules/masthead-data/masthead-agent/google/latest)
