# Terraform OCI Infrastructure (Hub-and-Spoke)

Terraform configuration to deploy a modular Oracle Cloud Infrastructure (OCI) hub-and-spoke environment with:

- A dedicated compartment
- One DMZ VCN and multiple spoke VCNs
- DRG attachments and inter-VCN routing
- Subnets, route tables, and security lists
- Compute instances (including optional bastion host pattern)
- Optional Object Storage bucket for Terraform remote state

## Architecture Summary

This stack provisions:

- **Compartment** under the tenancy root
- **Network topology**:
  - 1 DMZ VCN (Internet Gateway enabled)
  - Spoke VCNs attached to a shared DRG
  - Route rules for DMZ↔Spokes and Spoke↔Spoke via DRG
- **Workload placement**:
  - DMZ management/services subnets
  - Private spoke workload subnets
- **Compute** instances distributed across selected subnets
- **State backend support** with optional OCI Object Storage bucket creation

## Repository Structure

- `main.tf`: root orchestration (compartment, VCNs, DRG, routes, security lists, subnets, instances, state bucket)
- `variables.tf`: all inputs and validations
- `data.tf`: OCI data sources (availability/fault domains, object storage namespace)
- `provider.tf`: OCI provider profile configuration
- `outputs.tf`: exported IDs and backend migration helper output
- `terraform.tf`: OCI provider source/version constraints
- `versions.tf`: Terraform CLI version constraint
- `oci-infra-values.auto.tfvars`: environment-specific values (sample)
- `modules/vcn`: wrapper around `oracle-terraform-modules/vcn/oci`
- `modules/drg`: wrapper around `oracle-terraform-modules/drg/oci`
- `modules/compute`: compute instance module
- `modules/object-storage-bucket`: state bucket module

## Prerequisites

- Terraform `>= 1.14.0`
- OCI provider `oracle/oci` `8.2.0`
- OCI CLI/API credentials configured in `~/.oci/config` (profile `DEFAULT`)
- Required IAM permissions to manage compartment/network/compute/object storage resources

## Quick Start

1. Update input values in `oci-infra-values.auto.tfvars`:
   - `tenancy_ocid`
   - `region`
   - `instances[*].image_ocid`
   - `instances[*].ssh_public_key_path`
2. Initialize and plan:

```bash
terraform init
terraform plan
```

3. Apply:

```bash
terraform apply
```

## Remote State (Optional)

If `create_state_bucket = true`, the stack creates an Object Storage bucket and outputs a backend migration command (`terraform_backend_init_command`) to move local state to OCI Object Storage after the first apply.

## Notes

- Exactly one VCN must be marked as `role = "dmz"`.
- Spoke subnets are private by default unless explicitly configured otherwise.
- DMZ internet egress is controlled per-subnet with `internet_access`.

## Documentation

- `README-OCI.md`: OCI profile setup and deployment guide
- `ROUTING-VERIFICATION.md`: expected routing behavior and validation steps

## Security Reminder

Do not commit real OCIDs, private keys, or other secrets. Keep sensitive values in secure secret management workflows.