resource "google_storage_bucket" "bucket" {
  name          = var.gcp.bucketName
  location      = "EU"
  force_destroy = true
}
