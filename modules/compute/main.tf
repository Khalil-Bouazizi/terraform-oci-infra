resource "oci_core_instance" "oci_instance_details" {
  for_each = var.instances

  availability_domain = each.value.availability_domain
  compartment_id      = var.compartment_id
  display_name        = each.key
  shape               = each.value.shape
  fault_domain        = try(each.value.fault_domain, null)

  source_details {
    source_type = "image"
    source_id   = each.value.image_ocid

    boot_volume_size_in_gbs = try(each.value.boot_volume_size_in_gbs, null)
  }

  create_vnic_details {
    subnet_id        = each.value.subnet_id
    assign_public_ip = each.value.assign_public_ip
  }

  metadata = merge(
    try(each.value.metadata, {}),
    {
      ssh_authorized_keys = join("\n", each.value.ssh_authorized_keys)
    }
  )

  freeform_tags = try(each.value.freeform_tags, {})
  defined_tags  = try(each.value.defined_tags, {})
}
