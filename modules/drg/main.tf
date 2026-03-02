module "this" {
  source  = "oracle-terraform-modules/drg/oci"
  version = "1.0.6"

  compartment_id = var.compartment_id
  label_prefix   = var.label_prefix

  drg_display_name    = var.drg_display_name
  drg_vcn_attachments = var.drg_vcn_attachments
}
