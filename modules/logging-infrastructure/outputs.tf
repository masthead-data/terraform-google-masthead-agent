output "pubsub_topic_id" {
  description = "The full ID of the Pub/Sub topic"
  value       = google_pubsub_topic.logs_topic.id
}

output "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic"
  value       = google_pubsub_topic.logs_topic.name
}

output "pubsub_subscription_id" {
  description = "The full ID of the Pub/Sub subscription"
  value       = google_pubsub_subscription.logs_subscription.id
}

output "pubsub_subscription_name" {
  description = "The name of the Pub/Sub subscription"
  value       = google_pubsub_subscription.logs_subscription.name
}

output "folder_sink_id" {
  description = "The ID of the folder-level logging sink (if created)"
  value       = length(google_logging_folder_sink.folder_sink) > 0 ? google_logging_folder_sink.folder_sink[0].id : null
}

output "folder_sink_writer_identity" {
  description = "The writer identity of the folder-level logging sink (if created)"
  value       = length(google_logging_folder_sink.folder_sink) > 0 ? google_logging_folder_sink.folder_sink[0].writer_identity : null
}

output "project_sink_ids" {
  description = "Map of project IDs to their logging sink IDs"
  value = {
    for project_id, sink in google_logging_project_sink.project_sinks :
    project_id => sink.id
  }
}

output "project_sink_writer_identities" {
  description = "Map of project IDs to their logging sink writer identities"
  value = {
    for project_id, sink in google_logging_project_sink.project_sinks :
    project_id => sink.writer_identity
  }
}
