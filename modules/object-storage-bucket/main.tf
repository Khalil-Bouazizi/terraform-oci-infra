resource "oci_objectstorage_bucket" "state_bucket" {
  compartment_id = var.compartment_id
  namespace      = var.namespace
  name           = var.bucket_name
  access_type    = var.access_type

  versioning = var.versioning

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
