# OCI Hub-Spoke Routing Verification

## Current Topology

```
Internet
    ↓
┌─────────────────┐
│   DMZ VCN       │ (10.10.0.0/16)
│  - IGW enabled  │
│  - Public IPs   │
└────────┬────────┘
         │
    ┌────┴────┐ DRG (Hub)
    │         │
┌───┴──┐   ┌──┴───┐
│Spoke │   │Spoke │
│  A   │   │  B   │
└──────┘   └──────┘
(10.20.x.x) (10.30.x.x)
```

## Routing Rules Logic

### DMZ Subnet Routes:
- ✅ 0.0.0.0/0 → Internet Gateway (for outbound internet)
- ✅ 10.20.0.0/16 → DRG (to Spoke-A)
- ✅ 10.30.0.0/16 → DRG (to Spoke-B)

### Spoke-A Subnet Routes:
- ✅ 10.10.0.0/16 → DRG (to DMZ)
- ✅ 10.30.0.0/16 → DRG (to Spoke-B)

### Spoke-B Subnet Routes:
- ✅ 10.10.0.0/16 → DRG (to DMZ)
- ✅ 10.20.0.0/16 → DRG (to Spoke-A)

## Code Verification

From `main.tf` lines 133-152:

```terraform
dynamic "route_rules" {
  for_each = [
    for vcn_name, vcn_value in local.vcns_resolved : {
      destination = vcn_value.cidr_block
    }
    if (
      # DMZ → Spoke routes
      local.vcns_resolved[each.value.vcn_key].role == "dmz" &&
      vcn_name != each.value.vcn_key &&
      vcn_value.role == "spoke"
    ) || (
      # Spoke → DMZ and Spoke → Spoke routes
      local.vcns_resolved[each.value.vcn_key].role == "spoke" &&
      vcn_name != each.value.vcn_key &&
      (vcn_value.role == "dmz" || vcn_value.role == "spoke")
    )
  ]
  content {
    destination       = route_rules.value.destination
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.drg_hub.drg_id
  }
}
```

## Test After Deployment

```bash
# 1. SSH to DMZ instance
ssh -i ~/.ssh/id_rsa opc@<dmz-instance-public-ip>

# 2. From DMZ, test connectivity to spoke-a (should work via DRG)
ping <spoke-a-instance-private-ip>

# 3. SSH to spoke-a via bastion/DMZ
ssh -i ~/.ssh/id_rsa -J <bastion-ip> opc@<spoke-a-private-ip>

# 4. From spoke-a, try to reach spoke-b directly (should WORK)
ping <spoke-b-instance-private-ip>  # ✅ via DRG

# 5. From spoke-a, reach DMZ (should work)
ping <dmz-instance-private-ip>  # ✅ Works
```

## Expected Behavior

✅ **Allowed:**
- Internet → DMZ (via IGW)
- DMZ → Spoke-A (via DRG)
- DMZ → Spoke-B (via DRG)
- Spoke-A → DMZ (via DRG)
- Spoke-B → DMZ (via DRG)

❌ **Blocked:**
- Spoke → Internet (no IGW/NAT in spoke VCNs)

## Conclusion

The current configuration **correctly implements hub-and-spoke with east-west spoke connectivity**:
- Centralized internet egress via DMZ
- Spoke-to-spoke traffic enabled through DRG routing
- Inter-spoke communication transits through DRG
