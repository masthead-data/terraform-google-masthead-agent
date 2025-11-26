output "pubsub_topic_id" {
  description = "The full ID of the Pub/Sub topic"
  value       = module.logging_infrastructure.pubsub_topic_id
}

output "pubsub_subscription_id" {
  description = "The full ID of the Pub/Sub subscription"
  value       = module.logging_infrastructure.pubsub_subscription_id
}

output "logging_sink_id" {
  description = "The ID of the logging sink(s)"
  value = local.has_folders ? module.logging_infrastructure.folder_sink_ids : module.logging_infrastructure.project_sink_ids
}

output "logging_sink_writer_identity" {
  description = "The writer identity of the logging sink(s)"
  value = local.has_folders ? module.logging_infrastructure.folder_sink_writer_identities : module.logging_infrastructure.project_sink_writer_identities
}
