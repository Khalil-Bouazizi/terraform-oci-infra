variable "compartment_id" {
  description = "Compartment OCID where VCN resources are created."
  type        = string
}

variable "label_prefix" {
  description = "Prefix for OCI resource display names."
  type        = string
}

variable "vcn_name" {
  description = "VCN display name."
  type        = string
}

variable "vcn_cidrs" {
  description = "List of VCN CIDR blocks."
  type        = list(string)
}

variable "vcn_dns_label" {
  description = "DNS label for VCN."
  type        = string
}

variable "create_internet_gateway" {
  description = "Create Internet Gateway."
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Create NAT Gateway."
  type        = bool
  default     = false
}

variable "create_service_gateway" {
  description = "Create Service Gateway."
  type        = bool
  default     = false
}

variable "lockdown_default_seclist" {
  description = "Lock down default security list in VCN."
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 on VCN."
  type        = bool
  default     = false
}

variable "freeform_tags" {
  description = "Freeform tags for VCN resources."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags for VCN resources."
  type        = map(string)
  default     = {}
}
