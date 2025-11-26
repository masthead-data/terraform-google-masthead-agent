output "bigquery" {
  description = "BigQuery module outputs"
  value = var.enable_modules.bigquery ? {
    pubsub_topic_id              = module.bigquery[0].pubsub_topic_id
    pubsub_subscription_id       = module.bigquery[0].pubsub_subscription_id
    logging_sink_id              = module.bigquery[0].logging_sink_id
    logging_sink_writer_identity = module.bigquery[0].logging_sink_writer_identity
  } : null
}

output "dataform" {
  description = "Dataform module outputs"
  value = var.enable_modules.dataform ? {
    pubsub_topic_id              = module.dataform[0].pubsub_topic_id
    pubsub_subscription_id       = module.dataform[0].pubsub_subscription_id
    logging_sink_id              = module.dataform[0].logging_sink_id
    logging_sink_writer_identity = module.dataform[0].logging_sink_writer_identity
  } : null
}

output "dataplex" {
  description = "Dataplex module outputs"
  value = var.enable_modules.dataplex ? {
    pubsub_topic_id              = module.dataplex[0].pubsub_topic_id
    pubsub_subscription_id       = module.dataplex[0].pubsub_subscription_id
    logging_sink_id              = module.dataplex[0].logging_sink_id
    logging_sink_writer_identity = module.dataplex[0].logging_sink_writer_identity
  } : null
}

output "analytics_hub" {
  description = "Analytics Hub module outputs"
  value = var.enable_modules.analytics_hub ? {
    analyticshub_subscription_viewer_custom_role_id = module.analytics_hub[0].analyticshub_subscription_viewer_custom_role_id
  } : null
}

output "enabled_modules" {
  description = "List of enabled modules"
  value = [
    for module_name, enabled in var.enable_modules : module_name if enabled
  ]
}

output "deployment_mode" {
  description = "Deployment mode (project, folder, or hybrid)"
  value       = local.project_mode ? "project" : (local.hybrid_mode ? "hybrid" : "folder")
}

output "pubsub_project_id" {
  description = "The GCP project ID where Pub/Sub resources are deployed"
  value       = local.pubsub_project_id
}

output "monitored_folder_ids" {
  description = "The GCP folder IDs being monitored (if applicable)"
  value       = local.normalized_folder_ids
}

output "monitored_project_ids" {
  description = "List of project IDs being monitored directly"
  value       = local.all_monitored_projects
}
