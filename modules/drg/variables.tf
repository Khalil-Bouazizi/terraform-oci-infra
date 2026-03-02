variable "compartment_id" {
  description = "Compartment OCID where DRG is created."
  type        = string
}

variable "label_prefix" {
  description = "Prefix for OCI resource display names."
  type        = string
}

variable "drg_display_name" {
  description = "DRG display name."
  type        = string
}

variable "drg_vcn_attachments" {
  description = "Map of VCN attachments for DRG module."
  type        = map(any)
}
