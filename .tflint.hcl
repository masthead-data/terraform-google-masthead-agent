config {
  # Enable module inspection
  call_module_type = "all"

  # Force tflint to return an error code when issues are found
  force = false

  # Disable color output for CI environments
  disabled_by_default = false
}

# Enable the Terraform plugin
plugin "terraform" {
  enabled = true
  version = "0.12.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"

  preset = "recommended"
}

# Enable the Google Cloud Platform plugin
plugin "google" {
  enabled = true
  version = "0.34.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"

  # Deep check analyzes resource configurations more thoroughly
  deep_check = true
}

# Terraform core rules
rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format = "snake_case"
}

rule "terraform_standard_module_structure" {
  enabled = true
}
