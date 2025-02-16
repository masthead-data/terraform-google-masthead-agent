terraform {
  required_version = ">= 1.9.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.13.0"
    }
  }
}

variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

module "app" {
  source = "./app"

  project_id     = var.project_id
  project_number = var.project_number
}

module "dataform" {
  source = "./dataform"

  project_id     = var.project_id
  project_number = var.project_number
}

module "dataplex" {
  source = "./dataplex"

  project_id     = var.project_id
  project_number = var.project_number
}
