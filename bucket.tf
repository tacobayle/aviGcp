resource "google_storage_bucket" "bucket" {
  name          = var.gcp.bucket.name
  location      = "EU"
  force_destroy = true
}
