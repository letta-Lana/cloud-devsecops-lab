terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
    project = "project-e1d85569-83cf-4800-ab0"
    region = "europe-west2"
}

resource "google_storage_bucket" "site_bucket" {
  name     = "gcp-site-upload-lana-bucket"
  location = "EUROPE-WEST2"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "site_object" {
    bucket = google_storage_bucket.site_bucket.id
    role = "roles/storage.objectViewer"
    member = "allUsers"
}

resource "google_service_account" "gsa" {
  account_id   = "upload-processor-sa"
  display_name = "processor"
}

resource "google_project_iam_member" "member_role" {
  project = "project-e1d85569-83cf-4800-ab0"
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gsa.email}"
}

resource "google_storage_bucket_object" "upload_object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.site_bucket.name
  source = "main.zip"
}

resource "google_cloudfunctions2_function" "upload_processor" {
  name     = "upload-processor"
  location = "europe-west2"

  build_config {
    runtime     = "python312"
    entry_point = "process_upload"
    source {
      storage_source {
        bucket = google_storage_bucket.site_bucket.name
        object = google_storage_bucket_object.upload_object.name
      }
    }
  }

  service_config {
    service_account_email = google_service_account.gsa.email
  }

  event_trigger {
    trigger_region = "europe-west2"
    event_type     = "google.cloud.storage.object.v1.finalized"
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.site_bucket.name
    }
    service_account_email = google_service_account.gsa.email
  }
}

resource "google_project_iam_member" "iam_member" {
  project = "project-e1d85569-83cf-4800-ab0"
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:service-954803236991@gcp-sa-eventarc.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "eventarc_receiver" {
  project = "project-e1d85569-83cf-4800-ab0"
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.gsa.email}"
}
