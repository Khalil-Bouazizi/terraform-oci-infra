variable "compartment_id" {
  description = "Compartment OCID where instances are created."
  type        = string
}

variable "instances" {
  description = "Map of instances to create."
  type = map(object({
    availability_domain     = string
    subnet_id               = string
    image_ocid              = string
    ssh_authorized_keys     = list(string)
    shape                   = string
    assign_public_ip        = bool
    boot_volume_size_in_gbs = optional(number)
    fault_domain            = optional(string)
    metadata                = optional(map(string), {})
    freeform_tags           = optional(map(string), {})
    defined_tags            = optional(map(string), {})
  }))
}
