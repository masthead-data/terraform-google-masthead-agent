output "bigquery" {
  description = "BigQuery module outputs"
  value = var.enable_modules.bigquery ? {
    pubsub_topic_id              = module.bigquery[0].pubsub_topic_id
    pubsub_topic_name            = module.bigquery[0].pubsub_topic_name
    pubsub_subscription_id       = module.bigquery[0].pubsub_subscription_id
    pubsub_subscription_name     = module.bigquery[0].pubsub_subscription_name
    logging_sink_id              = module.bigquery[0].logging_sink_id
    logging_sink_writer_identity = module.bigquery[0].logging_sink_writer_identity
  } : null
}

output "dataform" {
  description = "Dataform module outputs"
  value = var.enable_modules.dataform ? {
    pubsub_topic_id              = module.dataform[0].pubsub_topic_id
    pubsub_topic_name            = module.dataform[0].pubsub_topic_name
    pubsub_subscription_id       = module.dataform[0].pubsub_subscription_id
    pubsub_subscription_name     = module.dataform[0].pubsub_subscription_name
    logging_sink_id              = module.dataform[0].logging_sink_id
    logging_sink_writer_identity = module.dataform[0].logging_sink_writer_identity
  } : null
}

output "dataplex" {
  description = "Dataplex module outputs"
  value = var.enable_modules.dataplex ? {
    pubsub_topic_id              = module.dataplex[0].pubsub_topic_id
    pubsub_topic_name            = module.dataplex[0].pubsub_topic_name
    pubsub_subscription_id       = module.dataplex[0].pubsub_subscription_id
    pubsub_subscription_name     = module.dataplex[0].pubsub_subscription_name
    logging_sink_id              = module.dataplex[0].logging_sink_id
    logging_sink_writer_identity = module.dataplex[0].logging_sink_writer_identity
    custom_role_id               = module.dataplex[0].custom_role_id
    custom_role_name             = module.dataplex[0].custom_role_name
  } : null
}

output "analytics_hub" {
  description = "Analytics Hub module outputs"
  value = var.enable_modules.analytics_hub ? {
    service_account_member = module.analytics_hub[0].service_account_member
    granted_role           = module.analytics_hub[0].granted_role
  } : null
}

output "enabled_modules" {
  description = "List of enabled modules"
  value = [
    for module_name, enabled in var.enable_modules : module_name if enabled
  ]
}

output "project_id" {
  description = "The GCP project ID where resources were created"
  value       = var.project_id
}

output "region" {
  description = "The GCP region where resources were created"
  value       = var.region
}
