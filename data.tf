# get availability domains from OCI 

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_fault_domains" "default_ad_fds" {
  compartment_id      = var.tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

# You can access: data.oci_identity_availability_domains.ads.availability_domains[0].name

# get object storage namespace for state bucket

data "oci_objectstorage_namespace" "tenancy_namespace" {
  compartment_id = var.tenancy_ocid
}
