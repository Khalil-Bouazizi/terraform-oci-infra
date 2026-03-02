output "compartment_id" {
  description = "Created compartment OCID."
  value       = oci_identity_compartment.oci_identity_compartment_details.id
}

output "drg_id" {
  description = "Hub-and-spoke DRG OCID."
  value       = module.drg_hub.drg_id
}

output "vcn_ids" {
  description = "VCN OCIDs by VCN key."
  value = {
    for name, vcn_module in module.vcn :
    name => vcn_module.vcn_id
  }
}

output "subnet_ids" {
  description = "Subnet OCIDs by VCN key."
  value = {
    for name, subnet in oci_core_subnet.workload :
    name => subnet.id
  }
}

output "drg_attachment_ids" {
  description = "DRG attachment OCIDs by VCN key."
  value = {
    for name, attachment in module.drg_hub.drg_attachment_all_attributes :
    name => attachment.id
  }
}

output "instance_ids" {
  description = "Compute instance OCIDs by instance key."
  value       = module.compute.instance_ids
}

output "bastion_host_instance_id" {
  description = "Bastion host VM instance OCID in DMZ management subnet."
  value       = try(module.compute.instance_ids["bastion-host"], null)
}

output "state_bucket_name" {
  description = "Object Storage bucket name used for Terraform remote state."
  value       = var.create_state_bucket ? module.object_storage_bucket[0].bucket_name : null
}

output "state_bucket_namespace" {
  description = "Object Storage namespace for state bucket."
  value       = var.create_state_bucket ? module.object_storage_bucket[0].bucket_namespace : null
}

output "terraform_backend_init_command" {
  description = "Run this command after initial apply to migrate local state to OCI Object Storage backend."
  value = var.create_state_bucket ? format(
    "terraform init -migrate-state -reconfigure -backend-config=\"address=https://objectstorage.%s.oraclecloud.com/n/%s/b/%s/o/%s\"",
    "<your-region>",
    module.object_storage_bucket[0].bucket_namespace,
    module.object_storage_bucket[0].bucket_name,
    var.state_bucket_prefix
  ) : null
}
