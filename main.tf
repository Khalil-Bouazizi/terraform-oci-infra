resource "oci_identity_compartment" "oci_identity_compartment_details" {
  compartment_id = var.tenancy_ocid
  name           = var.compartment_name
  description    = var.compartment_description
  enable_delete  = var.compartment_enable_delete

  freeform_tags = var.compartment_freeform_tags
  defined_tags  = var.compartment_defined_tags
}

locals {
  sorted_vcn_keys = sort(keys(var.vcns)) # gets VCN map keys

  vcns_resolved = { # build vcns values based on input variables (.tfvars) and defaults
    for name, vcn in var.vcns :
    name => {
      role = lower(try(vcn.role, "spoke"))

      index_resolved = coalesce(try(vcn.vcn_index, null), index(local.sorted_vcn_keys, name))

      cidr_block = coalesce(
        try(vcn.cidr_block, null),
        cidrsubnet(var.network_supernet_cidr, var.vcn_newbits, coalesce(try(vcn.vcn_index, null), index(local.sorted_vcn_keys, name)))
      )

      dns_label = coalesce(
        try(vcn.dns_label, null),
        substr(regexreplace(lower(format("vcn%s", name)), "[^a-z0-9]", ""), 0, 15)
      )

      freeform_tags = try(vcn.freeform_tags, {})
      defined_tags  = try(vcn.defined_tags, {})
    }
  }

  subnets_resolved = { # For each subnet, computes final CIDR and behavior flags.
    for name, subnet in var.subnets :
    name => {
      vcn_key = subnet.vcn_key

      subnet_cidr = coalesce(
        try(subnet.subnet_cidr, null),
        cidrsubnet(
          local.vcns_resolved[subnet.vcn_key].cidr_block,
          var.subnet_newbits,
          try(subnet.subnet_netnum, 1)
        )
      )

      subnet_dns_label = coalesce(
        try(subnet.subnet_dns_label, null),
        substr(regexreplace(lower(format("sub%s", name)), "[^a-z0-9]", ""), 0, 15)
      )

      assign_public_ip_on_vnic = try(subnet.assign_public_ip_on_vnic, false)
      internet_access          = try(subnet.internet_access, false)
      ingress_cidrs            = try(subnet.ingress_cidrs, [])
      ingress_tcp_ports        = try(subnet.ingress_tcp_ports, [])
      freeform_tags            = try(subnet.freeform_tags, {})
      defined_tags             = try(subnet.defined_tags, {})
    }
  }

  default_availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  default_fault_domain        = try(data.oci_identity_fault_domains.default_ad_fds.fault_domains[0].name, null)

  instances_resolved = {
    for name, instance in var.instances :
    name => {
      availability_domain = coalesce(try(instance.availability_domain, null), local.default_availability_domain)
      subnet_id           = oci_core_subnet.workload[instance.subnet_key].id

      image_ocid = instance.image_ocid
      ssh_authorized_keys = length(try(instance.ssh_authorized_keys, [])) > 0 ? instance.ssh_authorized_keys : [
        trimspace(file(instance.ssh_public_key_path))
      ]
      shape                   = try(instance.shape, "VM.Standard.E2.1.Micro")
      assign_public_ip        = coalesce(try(instance.assign_public_ip, null), local.subnets_resolved[instance.subnet_key].assign_public_ip_on_vnic)
      boot_volume_size_in_gbs = try(instance.boot_volume_size_in_gbs, null)
      fault_domain = coalesce(
        try(instance.fault_domain, null),
        coalesce(try(instance.availability_domain, null), local.default_availability_domain) == local.default_availability_domain ? local.default_fault_domain : null
      )
      metadata                = try(instance.metadata, {})
      freeform_tags           = try(instance.freeform_tags, {})
      defined_tags            = try(instance.defined_tags, {})
    }
  }
}

module "vcn" {
  source = "./modules/vcn"

  for_each = local.vcns_resolved

  compartment_id = oci_identity_compartment.oci_identity_compartment_details.id
  label_prefix   = var.compartment_name

  create_internet_gateway  = each.value.role == "dmz" # only create internet gateway for DMZ VCN
  create_nat_gateway       = false
  create_service_gateway   = false
  lockdown_default_seclist = true
  enable_ipv6              = false

  vcn_name      = each.key
  vcn_cidrs     = [each.value.cidr_block]
  vcn_dns_label = each.value.dns_label

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

module "drg_hub" {
  source = "./modules/drg"

  compartment_id = oci_identity_compartment.oci_identity_compartment_details.id
  label_prefix   = var.compartment_name

  drg_display_name = "${var.compartment_name}-drg"
  drg_vcn_attachments = {
    for key, vcn_module in module.vcn :
    key => {
      vcn_id                    = vcn_module.vcn_id
      vcn_transit_routing_rt_id = null
      drg_route_table_id        = null
    }
  }
}

resource "oci_core_route_table" "workload_rt" {
  for_each = local.subnets_resolved

  compartment_id = oci_identity_compartment.oci_identity_compartment_details.id
  vcn_id         = module.vcn[each.value.vcn_key].vcn_id
  display_name   = "${each.key}-rt"

  dynamic "route_rules" {
    for_each = [
      for vcn_name, vcn_value in local.vcns_resolved : {
        destination = vcn_value.cidr_block
      }
      if(
        vcn_name != each.value.vcn_key &&
        local.vcns_resolved[each.value.vcn_key].role == "dmz" &&
        vcn_value.role == "spoke"
        ) || (
        local.vcns_resolved[each.value.vcn_key].role == "spoke" &&
        vcn_name != each.value.vcn_key &&
        (
          vcn_value.role == "dmz" ||
          vcn_value.role == "spoke"
        )
      )
    ]
    content {
      destination       = route_rules.value.destination
      destination_type  = "CIDR_BLOCK"
      network_entity_id = module.drg_hub.drg_id
    }
  }

  dynamic "route_rules" {
    for_each = local.vcns_resolved[each.value.vcn_key].role == "dmz" && each.value.internet_access ? [1] : []
    content {
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      network_entity_id = module.vcn[each.value.vcn_key].internet_gateway_id
    }
  }

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

resource "oci_core_security_list" "workload_sl" {
  for_each = local.subnets_resolved

  compartment_id = oci_identity_compartment.oci_identity_compartment_details.id
  vcn_id         = module.vcn[each.value.vcn_key].vcn_id
  display_name   = "${each.key}-sl"

  dynamic "ingress_security_rules" {
    for_each = {
      for item in flatten([
        for cidr in each.value.ingress_cidrs : [
          for port in each.value.ingress_tcp_ports : {
            cidr = cidr
            port = port
          }
        ]
      ]) : "${item.cidr}-${item.port}" => item
    }
    content {
      protocol = "6"
      source   = ingress_security_rules.value.cidr

      tcp_options {
        min = ingress_security_rules.value.port
        max = ingress_security_rules.value.port
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = [
      for vcn_name, vcn_value in local.vcns_resolved : {
        source_cidr = vcn_value.cidr_block
      }
      if(
        vcn_name != each.value.vcn_key &&
        local.vcns_resolved[each.value.vcn_key].role == "dmz" &&
        vcn_value.role == "spoke"
        ) || (
        local.vcns_resolved[each.value.vcn_key].role == "spoke" &&
        vcn_name != each.value.vcn_key &&
        (
          vcn_value.role == "dmz" ||
          vcn_value.role == "spoke"
        )
      )
    ]
    content {
      source   = ingress_security_rules.value.source_cidr
      protocol = "all"
    }
  }

  ingress_security_rules {
    source   = local.vcns_resolved[each.value.vcn_key].cidr_block
    protocol = "all"
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

resource "oci_core_subnet" "workload" {
  for_each = local.subnets_resolved

  compartment_id             = oci_identity_compartment.oci_identity_compartment_details.id
  vcn_id                     = module.vcn[each.value.vcn_key].vcn_id
  cidr_block                 = each.value.subnet_cidr
  display_name               = each.key
  dns_label                  = each.value.subnet_dns_label
  route_table_id             = oci_core_route_table.workload_rt[each.key].id
  security_list_ids          = [oci_core_security_list.workload_sl[each.key].id]
  prohibit_public_ip_on_vnic = !each.value.assign_public_ip_on_vnic

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags
}

module "compute" {
  source = "./modules/compute"

  compartment_id = oci_identity_compartment.oci_identity_compartment_details.id
  instances      = local.instances_resolved
}

module "object_storage_bucket" {
  source = "./modules/object-storage-bucket"
  count  = var.create_state_bucket ? 1 : 0

  compartment_id = oci_identity_compartment.oci_identity_compartment_details.id
  namespace      = data.oci_objectstorage_namespace.tenancy_namespace.namespace
  bucket_name    = coalesce(var.state_bucket_name, "${var.compartment_name}-tfstate")

  freeform_tags = {
    purpose     = "terraform-state"
    environment = "shared"
  }
}
