# Required: Your GCP project ID
project_id = "your-production-project-id"

# Module enablement - all enabled by default for production
enable_bigquery      = true
enable_dataform      = true
enable_dataplex      = true
enable_analytics_hub = true

# BigQuery specific configuration
enable_privatelogviewer_role = true

# Production environment configuration
environment        = "production"
team               = "data-platform"
cost_center        = "engineering"
monitoring_enabled = "enabled"

# Module and business information
module_version = "0.2.2"
business_unit  = "analytics"
project_owner  = "data-team@yourcompany.com"
