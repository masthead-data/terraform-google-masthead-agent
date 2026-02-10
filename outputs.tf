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
    analyticshub_custom_role_id = module.analytics_hub[0].analyticshub_custom_role_id
  } : null
}

output "enabled_modules" {
  description = "List of enabled modules"
  value = [
    for module_name, enabled in var.enable_modules : module_name if enabled
  ]
}

output "deployment_mode" {
  description = "Deployment mode (project or organization)"
  value       = local.project_mode ? "project" : "organization"
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

output "deployment_project_id" {
  description = "The GCP project ID where Masthead agent is deployed"
  value       = local.pubsub_project_id
}

output "organization_id" {
  description = "The GCP organization ID being monitored (if applicable)"
  value       = local.numeric_organization_id
}

output "vpc_service_controls_config" {
  description = "Informational VPC Service Controls configuration for allowing Masthead access to customer resources; use this output as a reference and manually apply or update your VPC Service Controls perimeters accordingly"
  value = {
    ingress_policies = {
      description = "Ingress policies to allow Masthead service accounts to access customer resources"
      identities = [
        "serviceAccount:${var.masthead_service_accounts.bigquery_sa}",
        "serviceAccount:${var.masthead_service_accounts.dataform_sa}",
        "serviceAccount:${var.masthead_service_accounts.dataplex_sa}",
        "serviceAccount:${var.masthead_service_accounts.retro_sa}",
      ]
      source_projects = [
        "431544431936", # masthead-prod
        "136172083896", # masthead-prod-uk
      ]
      target_resources = ["*"]
      operations = {
        bigquery = {
          service_name = "bigquery.googleapis.com"
          methods = [
            "DatasetService.GetDataset",
            "DatasetService.ListDatasets",
            "JobService.GetJob",
            "ModelService.ListModels",
            "ProjectService.ListProjects",
            "ReservationService.GetBiReservation",
            "ReservationService.GetCapacityCommitment",
            "ReservationService.GetReservation",
            "ReservationService.GetReservationGroup",
            "ReservationService.ListAssignments",
            "ReservationService.ListCapacityCommitments",
            "ReservationService.ListReservationGroups",
            "ReservationService.ListReservations",
            "ReservationService.SearchAllAssignments",
            "RoutineService.GetRoutine",
            "RoutineService.ListRoutines",
            "TableService.GetTable",
            "TableService.ListTables",
          ]
          permissions = [
            "bigquery.capacityCommitments.list",
            "bigquery.datasets.get",
            "bigquery.jobs.get",
            "bigquery.jobs.list",
            "bigquery.jobs.listAll",
            "bigquery.models.getMetadata",
            "bigquery.models.list",
            "bigquery.reservationAssignments.list",
            "bigquery.reservations.list",
            "bigquery.routines.get",
            "bigquery.routines.list",
            "bigquery.tables.get",
            "bigquery.tables.getIamPolicy",
            "bigquery.tables.list",
          ]
        }
        logging = {
          service_name = "logging.googleapis.com"
          methods      = ["LoggingServiceV2.ListLogEntries"]
        }
        pubsub = {
          service_name = "pubsub.googleapis.com"
          methods = [
            "Publisher.GetTopic",
            "Publisher.ListTopics",
            "Publisher.ListTopicSubscriptions",
            "IAMPolicy.GetIamPolicy",
            "IAMPolicy.TestIamPermissions",
            "Subscriber.Acknowledge",
            "Subscriber.ModifyAckDeadline",
            "Subscriber.Pull",
            "Subscriber.StreamingPull",
          ]
        }
        analyticshub = {
          service_name = "analyticshub.googleapis.com"
          methods      = ["*"]
        }
        dataplex = {
          service_name = "dataplex.googleapis.com"
          methods      = ["*"]
        }
      }
    }
    egress_policies = {
      description = "Egress policies to allow Masthead to create BigQuery jobs in customer projects"
      identities  = ["serviceAccount:${var.masthead_service_accounts.bigquery_sa}"]
      target_projects = [
        "431544431936", # masthead-prod
        "136172083896", # masthead-prod-uk
      ]
      operations = {
        bigquery = {
          service_name = "bigquery.googleapis.com"
          permissions  = ["bigquery.jobs.create"]
        }
      }
    }
    reference_documentation = "https://cloud.google.com/vpc-service-controls/docs/supported-method-restrictions"
  }
}
