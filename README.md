# terraform-az-fk-compute

This repository contains a reusable **Terraform / OpenTofu module** and progressive examples for deploying **Azure Compute resources** — starting from a single Virtual Machine and evolving toward scalable, load-balanced architectures.

It is part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses/azure-fundamentals-terraform-course/)** and is designed as a **clean, composable compute layer** that builds on top of an existing Azure networking foundation (VNet, subnets).

---

## 🎯 Purpose

The goal of this module is to provide a **clear, educational, and architecture-aware reference implementation** for Azure compute:

- Focused on **Virtual Machines and Virtual Machine Scale Sets**
- Explicit inputs and outputs — no hidden dependencies
- Designed to integrate cleanly with:
  - Azure VNets
  - Load Balancers
  - NSGs
  - Autoscaling scenarios

This is **not** a full landing zone or opinionated platform module.  
It is a **learning-first, building-block module**.

---

## ✨ What the module does

Depending on configuration and example used, the module can create:

- Linux Virtual Machines (single or multiple)
- Virtual Machine Scale Sets (VMSS)
- Network Interfaces (NICs)
- OS Disks and basic VM configuration
- Optional system-assigned managed identity
- Optional static private IP assignment
- Optional NIC IP forwarding for router / NVA scenarios
- Optional multi-NIC Virtual Machines
- Optional integration with:
  - Azure Load Balancer backend pools
  - Autoscaling (VMSS)

The module intentionally does **not** create:
- Virtual Networks or subnets
- Network Security Groups
- Load Balancers or LB rules
- NAT Gateway
- Bastion
- Monitoring or backup resources

Each of those concerns belongs in its **own dedicated module**.

---

## 📂 Repository Structure

```bash
terraform-az-fk-compute/
├── examples/
│   ├── 01_single_vm/
│   ├── 02_single_vm_with_nsg/        
│   ├── 03_multiple_vms_with_lb/      
│   ├── 04_vmss_autoscaling/         
│   ├── 05_nva_dual_nic_vm/
│   ├── 06_vm_managed_identity_blob_access/
│   └── README.md
├── main.tf
├── inputs.tf
├── outputs.tf
├── versions.tf
├── LICENSE
└── README.md
```

---

## 🚀 Example Usage

```hcl
module "compute" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-compute.git?ref=v0.1.0"

  name                = "fk-vm-01"
  location            = "westeurope"
  resource_group_name = "fk-rg"

  subnet_id = module.vnet.subnet_ids["public"]

  vm_size = "Standard_B1s"
  identity_type = "SystemAssigned"

  admin_username = "azureuser"
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    project = "foggykitchen"
    env     = "dev"
  }
}
```

When `identity_type = "SystemAssigned"`, the module enables a system-assigned managed identity on the VM or VMSS and exposes its principal ID in outputs such as `vm_principal_id` or `vmss_principal_id`. This is useful when integrating the compute layer with downstream RBAC assignments.

## Router / NVA Usage

The module can also be used to deploy a simple **router VM** or lightweight **network virtual appliance** in a subnet:

```hcl
module "router_vm" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-compute.git"

  name                = "fk-router-vm"
  location            = "westeurope"
  resource_group_name = "fk-rg"
  subnet_id           = module.vnet.subnet_ids["hub"]

  enable_ip_forwarding         = true
  private_ip_address_allocation = "Static"
  private_ip_address            = "10.0.1.4"

  admin_username = "azureuser"
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  custom_data = base64encode(<<EOF
#cloud-config
runcmd:
  - sysctl -w net.ipv4.ip_forward=1
  - sed -i '/^net.ipv4.ip_forward/d' /etc/sysctl.conf
  - echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
EOF
  )
}
```

For a working transit-routing design in Azure, OS-level forwarding must be enabled inside the VM in addition to NIC IP forwarding.

---

## Multi-NIC VM Usage

The module now supports an optional multi-NIC mode for `deployment_mode = "vm"` while preserving the existing single-NIC inputs.

When `network_interfaces` is set:

- the module creates one NIC per map entry
- exactly one NIC must be marked with `primary = true`
- `vm_private_ip` returns the private IP of the primary NIC
- `vm_private_ips` and `vm_nic_ids` return all NICs as maps

Example:

```hcl
module "router_vm" {
  source = "git::https://github.com/mlinxfeld/terraform-az-fk-compute.git"

  name                = "fk-router-vm"
  location            = "westeurope"
  resource_group_name = "fk-rg"
  deployment_mode     = "vm"

  network_interfaces = {
    inside = {
      subnet_id                     = module.vnet.subnet_ids["hub-inside"]
      private_ip_address_allocation = "Static"
      private_ip_address            = "10.0.1.4"
      enable_ip_forwarding          = true
      primary                       = true
      attach_nsg_to_nic             = true
      nsg_id                        = module.nsg_inside.id
    }
    outside = {
      subnet_id                     = module.vnet.subnet_ids["hub-outside"]
      private_ip_address_allocation = "Static"
      private_ip_address            = "10.0.2.4"
      attach_nsg_to_nic             = true
      nsg_id                        = module.nsg_outside.id
    }
  }

  admin_username = "azureuser"
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}
```

Current limitations of multi-NIC mode:

- supported only for `deployment_mode = "vm"`
- `lb_attachment` remains supported only in the single-NIC VM path
- VMSS networking is still single-NIC

See [examples/05_nva_dual_nic_vm](examples/05_nva_dual_nic_vm/README.md) for a minimal dual-NIC NVA-style VM example focused on the compute module itself.

---

## 📤 Outputs

| Output | Description |
|------|-------------|
| `deployment_mode` | Selected deployment mode (`vm` or `vmss`) |
| `vm_id` | VM resource ID |
| `vm_principal_id` | Principal ID of the VM managed identity |
| `vm_tenant_id` | Tenant ID of the VM managed identity |
| `vm_private_ip` | Private IP address of the VM primary NIC |
| `vm_private_ips` | Private IP addresses of all VM NICs |
| `vm_nic_ids` | NIC IDs of the VM |
| `backend_nic_ids` | NIC IDs usable as LB backend targets |
| `vmss_id` | VM Scale Set ID (if used) |
| `vmss_principal_id` | Principal ID of the VMSS managed identity |
| `vmss_tenant_id` | Tenant ID of the VMSS managed identity |
| `autoscale_setting_id` | Autoscale setting ID (if enabled) |
| `attached_backend_pool_ids` | Backend pool IDs this compute instance is attached to |

---

## 🧠 Design Philosophy

- Compute is **stateless infrastructure**, not configuration management
- Networking decisions happen **before** compute
- Load balancing and security are **explicit integrations**
- Backward compatibility matters, so advanced networking features extend the existing API instead of replacing it
- Outputs are first-class citizens

---

## 🧩 Related Modules & Training

- [terraform-az-fk-vnet](https://github.com/foggykitchen/terraform-az-fk-vnet)
- [terraform-az-fk-nsg](https://github.com/foggykitchen/terraform-az-fk-nsg)
- [terraform-az-fk-loadbalancer](https://github.com/foggykitchen/terraform-az-fk-loadbalancer)
- [terraform-az-fk-bastion](https://github.com/mlinxfeld/terraform-az-fk-bastion)
- [terraform-az-fk-natgw](https://github.com/foggykitchen/terraform-az-fk-natgw)
- [terraform-az-fk-disk](https://github.com/foggykitchen/terraform-az-fk-disk)
- [terraform-az-fk-storage](https://github.com/foggykitchen/terraform-az-fk-storage)
- [terraform-az-fk-aks](https://github.com/mlinxfeld/terraform-az-fk-aks)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
