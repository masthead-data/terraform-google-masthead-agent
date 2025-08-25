output "pubsub_topic_id" {
  description = "ID of the Pub/Sub topic created for Dataplex logs"
  value       = google_pubsub_topic.masthead_dataplex_topic.id
}

output "pubsub_subscription_id" {
  description = "ID of the Pub/Sub subscription for the Masthead Dataplex agent"
  value       = google_pubsub_subscription.masthead_dataplex_subscription.id
}

output "logging_sink_id" {
  description = "ID of the logging sink for Dataplex audit logs"
  value       = google_logging_project_sink.masthead_dataplex_sink.id
}

output "logging_sink_writer_identity" {
  description = "Writer identity of the logging sink"
  value       = google_logging_project_sink.masthead_dataplex_sink.writer_identity
}
