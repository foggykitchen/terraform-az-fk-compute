# Azure Compute with Terraform/OpenTofu – Training Examples

This directory contains all progressive examples used with the **terraform-az-fk-compute** module.
The examples are designed as **incremental building blocks**, starting from a single Azure Virtual Machine and gradually evolving toward scalable, load-balanced compute architectures.

These examples are part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses-2/)** and are used across Azure
and multicloud courses (Azure Fundamentals, AKS, and advanced networking scenarios).

---

## 🧭 Example Overview

| Example | Title | Key Topics |
|:-------:|:------|:-----------|
| 01 | **Single Virtual Machine** | Minimal Linux VM, NIC attachment, compute basics |
| 02 | **Single VM with NSG** | Network Security Groups and inbound/outbound control |
| 03 | **Multiple VMs with Load Balancer** | Azure Load Balancer, backend pools, health probes |
| 04 | **VM Scale Set with Autoscaling** | VMSS, autoscale rules, backend integration |
| 05 | **Dual-NIC NVA VM** | Multi-NIC VM, primary/secondary NICs, static IPs, NIC-level NSGs |
| 06 | **VM Managed Identity To Blob** | System-assigned managed identity, Blob upload via `az login --identity`, compute-to-storage integration |

Each example builds on the **concepts** introduced in the previous one, but can be applied
independently for learning and experimentation.

---

## ⚙️ How to Use

Each example directory contains:
- Terraform/OpenTofu configuration (`.tf`)
- A focused `README.md` explaining the goal of the example
- A minimal, runnable architecture (no placeholder resources)

To run an example:

```bash
cd examples/01_single_vm
tofu init
tofu plan
tofu apply
```

You can apply examples independently, but the **recommended approach is sequential**:
01 → 02 → 03 → 04 → 05 → 06

This mirrors real-world compute design, where complexity is introduced only when required.

---

## 🧩 Design Principles

- One example = one architectural goal
- No unused or placeholder resources
- Clear separation of concerns (networking vs compute)
- Compute designed to integrate with other modules (VNet, LB, NSG)
- Advanced networking stays compute-centric unless the example explicitly targets a routing module

These examples intentionally avoid:
- Full landing zones
- Opinionated enterprise frameworks
- Hidden dependencies between examples

---

## 🧩 Related Resources

- [FoggyKitchen Azure Compute Module (terraform-az-fk-compute)](../)
- [FoggyKitchen Azure VNet Module (terraform-az-fk-vnet)](https://github.com/foggykitchen/terraform-az-fk-vnet)
- [FoggyKitchen Azure NSG Module (terraform-az-fk-nsg)](https://github.com/mlinxfeld/terraform-az-fk-nsg)
- [FoggyKitchen Azure Load Balancer Module (terraform-az-fk-loadbalancer)](https://github.com/mlinxfeld/terraform-az-fk-loadbalancer)
- [FoggyKitchen Azure Bastion Module (terraform-az-fk-bastion)](https://github.com/mlinxfeld/terraform-az-fk-bastion)
- [FoggyKitchen Azure NAT Gateway Module (terraform-az-fk-natgw)](https://github.com/mlinxfeld/terraform-az-fk-natgw)
- [FoggyKitchen Azure Disk Module (terraform-az-fk-disk)](https://github.com/foggykitchen/terraform-az-fk-disk)
- [FoggyKitchen Azure Storage Module (terraform-az-fk-storage)](https://github.com/foggykitchen/terraform-az-fk-storage)
- [FoggyKitchen AKS Module (terraform-az-fk-aks)](https://github.com/mlinxfeld/terraform-az-fk-aks)
- [OCI OKE Module (terraform-oci-fk-oke)](https://github.com/foggykitchen/terraform-oci-fk-oke)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../LICENSE) for details.

---

© 2026 FoggyKitchen.com — *Cloud. Code. Clarity.*
