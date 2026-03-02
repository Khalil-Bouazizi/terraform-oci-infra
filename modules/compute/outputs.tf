output "instance_ids" { # this output variable is used in root output.tf file to view
  value = {
    for name, instance in oci_core_instance.oci_instance_details :
    name => instance.id
  }
}
