# GitHub Copilot Instructions for terraform-google-masthead-agent

## Repository Overview

This is a Terraform module that deploys infrastructure for Masthead Data to monitor Google Cloud services. The module manages:
- BigQuery monitoring via Pub/Sub and Cloud Logging
- Dataform monitoring
- Dataplex monitoring and data scanning
- Analytics Hub monitoring

## Code Standards

### Terraform Style
- Use Terraform 1.5.7+ syntax and features
- Follow HashiCorp's official Terraform style guide
- Use `terraform fmt` for consistent formatting
- Prefer `for_each` over `count` for resource creation when managing multiple similar resources
- Use meaningful resource and variable names that clearly indicate their purpose

### File Organization
- Each module should have: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and `README.md`
- Root level should have: `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`
- Keep related resources together in logical blocks with comments

### Variable Conventions
- All variables must include `description` field
- Use validation blocks for critical variables (e.g., project_id format)
- Provide sensible defaults where appropriate
- Use object types for grouped related variables (e.g., `masthead_service_accounts`)
- Use boolean flags for optional features (e.g., `enable_apis`, `enable_privatelogviewer_role`)

### Resource Naming
- Use consistent naming prefixes: `masthead-` for all created resources
- Store resource names in `locals.resource_names` block for easy reference
- Use descriptive names: `masthead-topic`, `masthead-agent-subscription`, `masthead-agent-sink`

### Labels and Tags
- Always apply labels to resources that support them
- Merge user-provided labels with component-specific labels using `merge()`
- Include default labels: `service = "masthead-agent"`, `component = "<module-name>"`

### IAM and Security
- Use `google_project_iam_member` instead of `google_project_iam_binding` to avoid overwriting existing bindings
- Always use service account email format: `serviceAccount:${var.masthead_service_accounts.<sa_name>}`
- Set least-privilege permissions
- Expand permissions of a custom role (or create one if it doesn't exist) when standard roles provide more permissions than needed
- Use `unique_writer_identity = true` for logging sinks

### API Management
- Make API enablement optional via `enable_apis` variable
- Use `for_each` with `toset()` for enabling multiple APIs
- Set `disable_on_destroy = false` to prevent breaking other resources
- Set `disable_dependent_services = false` to avoid unintended disruptions
- Always add `depends_on = [google_project_service.required_apis]` for resources requiring APIs

### Logging and Monitoring
- Use descriptive filters for logging sinks
- Include all relevant methodNames and resource types
- Set reasonable retention periods (e.g., 24 hours for Pub/Sub messages)
- Configure expiration policies to prevent resource deletion
- Use `message_retention_duration` and `ack_deadline_seconds` appropriately

### Module Structure
- Each module should be conditionally enabled via `enable_modules` variable
- Use `count = var.enable_modules.<module_name> ? 1 : 0` pattern
- Modules should be self-contained and reusable
- Pass common variables from root to modules (project_id, service accounts, labels)

## Documentation Requirements

### README Files
- Include usage examples (basic and full configurations)
- Provide links to official Masthead Data documentation
- Show Terraform Registry badge and links
- Include "Open in Google Cloud Shell" button
- Document all input variables and outputs in tables

### Code Comments
- Add block comments before each major resource or resource group
- Explain the purpose of complex filters or conditions
- Document any non-obvious design decisions
- Include references to external documentation where relevant

### Variables Documentation
- Every variable must have a clear description
- Document default values and why they were chosen
- Explain validation rules
- Note any dependencies between variables

## Testing and Validation

### Before Committing
- Run `terraform fmt -recursive` to format all files
- Run `terraform validate` to check syntax
- Verify variable validations work correctly
- Test with both minimal and full configurations
- Check that optional features can be disabled

### Module Testing
- Test each module independently
- Test with `enable_modules` flags in different combinations
- Verify IAM permissions are correctly applied
- Ensure resources are created with proper labels
- Confirm API enablement works as expected

## Common Patterns

### Conditional Resource Creation
```hcl
resource "google_project_iam_member" "optional_role" {
  count   = var.enable_feature ? 1 : 0
  # resource configuration
}
```

### Locals for Resource Names
```hcl
locals {
  resource_names = {
    topic        = "masthead-topic"
    subscription = "masthead-agent-subscription"
    sink         = "masthead-agent-sink"
  }
}
```

### Label Merging
```hcl
locals {
  common_labels = merge(var.labels, {
    component = "module-name"
  })
}
```

### API Enablement
```hcl
resource "google_project_service" "required_apis" {
  for_each = var.enable_apis ? toset([
    "service1.googleapis.com",
    "service2.googleapis.com"
  ]) : toset([])

  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}
```

## Integration Points

### Masthead Service Accounts
The module integrates with pre-existing Masthead service accounts:
- `bigquery_sa`: For BigQuery monitoring
- `dataform_sa`: For Dataform monitoring
- `dataplex_sa`: For Dataplex monitoring and data scanning
- `retro_sa`: For retrospective log access

### Google Cloud APIs
Required APIs per module:
- **BigQuery**: pubsub, iam, logging, bigquery
- **Dataform**: pubsub, iam, logging, dataform
- **Dataplex**: pubsub, iam, logging, dataplex
- **Analytics Hub**: iam, bigquery, analyticshub

## Version Management

- Maintain semantic versioning (MAJOR.MINOR.PATCH)
- Update CHANGELOG.md for all changes
- Keep minimum Terraform version at 1.5.7+
- Keep minimum Google provider version at 6.13.0+
- Test compatibility with latest provider versions

## When Making Changes

1. **Adding a new module**: Follow the existing module structure with main.tf, variables.tf, outputs.tf, versions.tf, and README.md
2. **Adding new variables**: Include description, validation if applicable, and document in README
3. **Adding new IAM roles**: Use project_iam_member, not binding; document why the permission is needed
4. **Adding new resources**: Apply labels, add API dependencies, use resource_names locals
5. **Updating filters**: Test thoroughly; logging filters are critical for data capture
6. **Version bumps**: Update CHANGELOG.md, README.md examples, and version constraints

## Error Handling

- Use validation blocks to catch configuration errors early
- Provide clear error messages in validation blocks
- Document known limitations or constraints
- Handle edge cases in conditional logic
- For resource dependency the best practice is to rely on native Terraform features, alternatively use `depends_on` to ensure correct resource creation order. Avoid using time delays or arbitrary waits.

## Security Considerations

- Never hardcode credentials or sensitive values
- Use minimal required permissions
- Document security implications of each permission
- Follow principle of least privilege for all IAM grants
