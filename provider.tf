# activates OCI provider configuration for all OCI resources/modules in this workspace
# It uses the profile block named [DEFAULT] which contains metadata of OCI tenancy, user, region, and auth method (e.g. API key)

provider "oci" {
  config_file_profile = "DEFAULT"
}