output "bucket_name" {
  description = "Name of the created bucket."
  value       = oci_objectstorage_bucket.state_bucket.name
}

output "bucket_namespace" {
  description = "Namespace of the bucket."
  value       = oci_objectstorage_bucket.state_bucket.namespace
}

output "bucket_id" {
  description = "OCID of the bucket."
  value       = oci_objectstorage_bucket.state_bucket.id
}
