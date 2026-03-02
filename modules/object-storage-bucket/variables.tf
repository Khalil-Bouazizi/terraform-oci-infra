variable "compartment_id" {
  description = "Compartment OCID where the bucket is created."
  type        = string
}

variable "namespace" {
  description = "Object storage namespace (tenancy-specific)."
  type        = string
}

variable "bucket_name" {
  description = "Name of the object storage bucket."
  type        = string
}

variable "access_type" {
  description = "Bucket access type (NoPublicAccess, ObjectRead, ObjectReadWithoutList)."
  type        = string
  default     = "NoPublicAccess"
}

variable "versioning" {
  description = "Enable versioning for the bucket."
  type        = string
  default     = "Enabled"
}

variable "freeform_tags" {
  description = "Freeform tags for the bucket."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags for the bucket."
  type        = map(string)
  default     = {}
}
