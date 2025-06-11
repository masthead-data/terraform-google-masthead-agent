output "pubsub_topic_id" {
  description = "ID of the Pub/Sub topic created for BigQuery logs"
  value       = google_pubsub_topic.masthead_topic.id
}

output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic created for BigQuery logs"
  value       = google_pubsub_topic.masthead_topic.name
}

output "pubsub_subscription_id" {
  description = "ID of the Pub/Sub subscription for the Masthead agent"
  value       = google_pubsub_subscription.masthead_agent_subscription.id
}

output "pubsub_subscription_name" {
  description = "Name of the Pub/Sub subscription for the Masthead agent"
  value       = google_pubsub_subscription.masthead_agent_subscription.name
}

output "logging_sink_id" {
  description = "ID of the logging sink for BigQuery audit logs"
  value       = google_logging_project_sink.masthead_sink.id
}

output "logging_sink_writer_identity" {
  description = "Writer identity of the logging sink"
  value       = google_logging_project_sink.masthead_sink.writer_identity
}
