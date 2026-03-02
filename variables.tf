# variables are like rules : Defines WHAT VALUES are expected and their TYPE - read values from .tvars file.

variable "tenancy_ocid" {
  description = "OCID of the tenancy root compartment."
  type        = string
}

variable "region" {
  description = "OCI region where resources are deployed (required by bastion module)."
  type        = string
}

variable "compartment_name" {
  description = "Name of the root-level compartment to create."
  type        = string
  default     = "oci-infra-test"
}

variable "compartment_description" {
  description = "Description for the created compartment."
  type        = string
  default     = "Terraform-managed compartment for OCI infrastructure testing"
}

variable "compartment_enable_delete" {
  description = "Allow compartment deletion via Terraform destroy."
  type        = bool
  default     = false
}

variable "compartment_freeform_tags" {
  description = "Freeform tags to set on the compartment."
  type        = map(string)
  default     = {}
}

variable "compartment_defined_tags" {
  description = "Defined tags to set on the compartment."
  type        = map(string)
  default     = {}
}

variable "network_supernet_cidr" {
  description = "Global address pool used for dynamic VCN CIDR allocation."
  type        = string
  default     = "10.0.0.0/8"
}

variable "vcn_newbits" {
  description = "Additional CIDR bits to allocate each VCN from network_supernet_cidr."
  type        = number
  default     = 8
}

variable "subnet_newbits" {
  description = "Additional CIDR bits to allocate subnet CIDR from each VCN CIDR."
  type        = number
  default     = 8
}

variable "vcns" {
  description = "Map of hub/spoke VCN definitions. VCN CIDR and DNS can be generated dynamically."
  type = map(object({
    role          = optional(string, "spoke")
    vcn_index     = optional(number)
    cidr_block    = optional(string)
    dns_label     = optional(string)
    freeform_tags = optional(map(string), {})
    defined_tags  = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for vcn in values(var.vcns) : contains(["dmz", "spoke"], lower(try(vcn.role, "spoke")))
    ])
    error_message = "Each vcns[*].role must be either 'dmz' or 'spoke'."
  }

  validation {
    condition = length([
      for vcn in values(var.vcns) : vcn # loop through the objects of map
      if lower(try(vcn.role, "spoke")) == "dmz" ]) == 1
    error_message = "Exactly one DMZ VCN must be defined (vcns[*].role = 'dmz')."
  }

  validation {
    condition = alltrue([
      for vcn in values(var.vcns) : try(vcn.vcn_index, null) == null || try(vcn.vcn_index, -1) >= 0
    ])
    error_message = "vcns[*].vcn_index must be >= 0 when provided."
  }
}

variable "subnets" {
  description = "Map of explicit subnets to create across VCNs (for example dmz-services, spoke-a-workload, spoke-b-workload)."
  type = map(object({
    vcn_key                  = string
    subnet_netnum            = optional(number, 1)
    subnet_cidr              = optional(string)
    subnet_dns_label         = optional(string)
    assign_public_ip_on_vnic = optional(bool, false)
    internet_access          = optional(bool, false)
    ingress_cidrs            = optional(list(string), [])
    ingress_tcp_ports        = optional(list(number), [])
    freeform_tags            = optional(map(string), {})
    defined_tags             = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) : contains(keys(var.vcns), subnet.vcn_key)
    ])
    error_message = "Each subnets[*].vcn_key must reference an existing key from vcns."
  }
}

variable "instances" {
  description = "Map of compute instances to create. Each instance is attached to the subnet referenced by subnet_key."
  type = map(object({
    subnet_key              = string
    availability_domain     = optional(string)
    image_ocid              = string
    ssh_authorized_keys     = optional(list(string), [])
    ssh_public_key_path     = optional(string)
    shape                   = optional(string, "VM.Standard.E2.1.Micro")
    assign_public_ip        = optional(bool)
    boot_volume_size_in_gbs = optional(number)
    fault_domain            = optional(string)
    metadata                = optional(map(string), {})
    freeform_tags           = optional(map(string), {})
    defined_tags            = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for instance in values(var.instances) : contains(keys(var.subnets), instance.subnet_key)
    ])
    error_message = "Each instances[*].subnet_key must reference an existing key from subnets."
  }

  validation {
    condition = alltrue([
      for instance in values(var.instances) : length(try(instance.ssh_authorized_keys, [])) > 0 || try(instance.ssh_public_key_path, null) != null
    ])
    error_message = "Each instance must define at least one SSH key via ssh_authorized_keys or ssh_public_key_path."
  }
}

variable "create_state_bucket" {
  description = "Whether to create an OCI Object Storage bucket for Terraform remote state."
  type        = bool
  default     = true
}

variable "state_bucket_name" {
  description = "Name of the Object Storage bucket for Terraform state."
  type        = string
  default     = null
}

variable "state_bucket_prefix" {
  description = "Prefix/path inside the state bucket for this stack state file."
  type        = string
  default     = "oci-infra/state"
}
