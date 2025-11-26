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
  value = var.folder_id != null ? module.logging_infrastructure.folder_sink_id : {
    for project_id, sink_id in module.logging_infrastructure.project_sink_ids :
    project_id => sink_id
  }
}

output "logging_sink_writer_identity" {
  description = "The writer identity of the logging sink(s)"
  value = var.folder_id != null ? module.logging_infrastructure.folder_sink_writer_identity : {
    for project_id, writer_identity in module.logging_infrastructure.project_sink_writer_identities :
    project_id => writer_identity
  }
}
