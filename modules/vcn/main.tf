module "this" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"

  compartment_id = var.compartment_id
  label_prefix   = var.label_prefix

  create_internet_gateway  = var.create_internet_gateway
  create_nat_gateway       = var.create_nat_gateway
  create_service_gateway   = var.create_service_gateway
  lockdown_default_seclist = var.lockdown_default_seclist
  enable_ipv6              = var.enable_ipv6

  vcn_name      = var.vcn_name
  vcn_cidrs     = var.vcn_cidrs
  vcn_dns_label = var.vcn_dns_label

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}