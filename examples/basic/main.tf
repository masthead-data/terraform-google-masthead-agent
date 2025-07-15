terraform {
  required_version = ">= 1.5.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.13.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created"
}

provider "google" {
  project = var.project_id
}

module "masthead_agent" {
  source = "masthead-data/masthead-agent/google"

  project_id = var.project_id
}
