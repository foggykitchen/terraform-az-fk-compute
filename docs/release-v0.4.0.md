# v0.4.0 — Application Gateway backend attachments

## Discovery

Read the root module and all six existing examples before implementation. The
single-NIC VM path uses vm_nic and a separate LB association. Nonempty
network_interfaces selects the multi-NIC path; the existing VM lifecycle
precondition rejects LB attachment there. VMSS already accepts lb_attachment
inline. The existing attached_backend_pool_ids output is LB-only.

Live AzureRM documentation and provider source show that the LB NIC association
is not agnostic: it parses Load Balancer pool IDs and updates the LB pool
collection. The dedicated Application Gateway NIC association parses gateway
pool IDs and updates the gateway collection. Both use the NIC-name lock and
preserve the other collection, supporting independent simultaneous attachments.
Simultaneous LB/gateway attachment was verified from schema/source, not deployed.
VMSS has a separate native application_gateway_backend_address_pool_ids list.

Sources:
- https://github.com/hashicorp/terraform-provider-azurerm/blob/main/website/docs/r/network_interface_backend_address_pool_association.html.markdown
- https://github.com/hashicorp/terraform-provider-azurerm/blob/main/internal/services/network/network_interface_backend_address_pool_association_resource.go
- https://github.com/hashicorp/terraform-provider-azurerm/blob/main/website/docs/r/network_interface_application_gateway_backend_address_pool_association.html.markdown
- https://github.com/hashicorp/terraform-provider-azurerm/blob/main/internal/services/network/network_interface_application_gateway_backend_address_pool_association_resource.go
- https://github.com/hashicorp/terraform-provider-azurerm/blob/main/website/docs/r/linux_virtual_machine_scale_set.html.markdown
- https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-networking
- https://learn.microsoft.com/en-us/azure/templates/microsoft.network/networkinterfaces
- https://learn.microsoft.com/en-us/azure/templates/microsoft.compute/virtualmachinescalesets


## Final contract

- app_gateway_attachment: object({ backend_pool_id = string }), default null.
- Single-NIC VM: dedicated Application Gateway NIC association. Multi-NIC VM
  is rejected because the input does not specify a target NIC.
- VMSS: native application_gateway_backend_address_pool_ids alongside LB IDs.
- attached_app_gateway_backend_pool_ids: singleton ID list or empty list.
- Existing LB input, resources and outputs retain their behavior.
- README covers all 27 root inputs and 14 outputs.

## Examples and runtime verification

Examples 07 (VM) and 08 (two-instance VMSS) consume Application Gateway v0.1.2,
which supports initially empty backend pools. Explicitly seeding a pool with the
same IP as its NIC was rejected by Azure as duplicate membership; the seed was
removed. The gateway validation fix was separately authorized and published in
the sibling repository as v0.1.2.

The examples follow the split-file convention: resource_group.tf creates the
Resource Group, while FoggyKitchen modules create networking, NAT, NSG, Public
IP, Application Gateway and compute. Both use fk-subnet-app-gateway and
fk-subnet-private. Their default VM size is Standard_B1s; the root default is
unchanged. NSG permits HTTP from the gateway subnet and denies other inbound.
User-supplied diagrams and screenshots are linked in both READMEs.

On 2026-10-06, authorized apply of 07 added 16 resources. Its backend 10.70.1.4
was Healthy and public HTTP returned 200 with the NGINX welcome page. Authorized
apply of 08 added 14 resources; both instances were Running/Succeeded, both
backends (10.70.1.4 and 10.70.1.5) were Healthy, and HTTP returned 200.

Both labs were subsequently destroyed. VM lab cleanup needed a retry after
Azure rejected concurrent NIC disassociation and VM deletion; the retry removed
all remaining resources. VMSS cleanup destroyed all 14 resources without errors.
Both states were empty and Azure confirmed fk-rg no longer existed.

## Static compatibility verification

Root and all eight examples passed init and validate. All six isolated copies
of the existing examples also passed against the changed local compute module.
Only their compute module source was redirected in temporary copies.

fmt-check passed for root and examples 03, 05, 06, 07 and 08. Pre-existing
formatting failures in 01, 02 and 04 were preserved to keep existing examples
unchanged. Full command output, including failures and successful retries, is
recorded in [validation-v0.4.0.txt](validation-v0.4.0.txt) and its supporting logs.

The existing .gitignore already excludes .terraform.lock.hcl. Generated caches,
locks, states/backups and temporary lab 07/08 tfvars were removed before commit.
Existing unrelated local example 03 edits are excluded from this commit.

## Version

Remote tags confirmed v0.3.5 as the latest release. The additive nullable input
and separate output warrant v0.4.0, following the existing feature-minor and
patch-fix convention. No existing input/output is renamed or removed.
