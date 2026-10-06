variable "name" {
  description = "Base name for compute resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "deployment_mode" {
  description = "Compute deployment mode: vm or vmss"
  type        = string
  default     = "vm"

  validation {
    condition     = contains(["vm", "vmss"], var.deployment_mode)
    error_message = "deployment_mode must be either 'vm' or 'vmss'."
  }
}

variable "subnet_id" {
  description = "Subnet ID where compute resources will be deployed"
  type        = string
  default     = null
}

variable "enable_ip_forwarding" {
  description = "Enable IP forwarding on the VM/VMSS NIC. Required for router or NVA-style workloads."
  type        = bool
  default     = false
}

variable "private_ip_address_allocation" {
  description = "Private IP allocation mode for the primary NIC on a single VM deployment."
  type        = string
  default     = "Dynamic"

  validation {
    condition     = contains(["Dynamic", "Static"], var.private_ip_address_allocation)
    error_message = "private_ip_address_allocation must be either 'Dynamic' or 'Static'."
  }
}

variable "private_ip_address" {
  description = "Static private IP address for the primary NIC on a single VM deployment. Used only when private_ip_address_allocation is set to Static."
  type        = string
  default     = null
}

variable "network_interfaces" {
  description = "Optional multi-NIC definition for VM deployments. When null, the module uses the existing single-NIC inputs."
  type = map(object({
    subnet_id                     = string
    private_ip_address_allocation = optional(string, "Dynamic")
    private_ip_address            = optional(string)
    enable_ip_forwarding          = optional(bool, false)
    attach_nsg_to_nic             = optional(bool, false)
    nsg_id                        = optional(string)
    primary                       = optional(bool, false)
  }))
  default = null
}

variable "admin_username" {
  description = "Admin username for Linux VM/VMSS"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "image_reference" {
  description = "Linux image reference"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "lb_attachment" {
  description = "Optional Load Balancer backend pool attachment"
  type = object({
    backend_pool_id = string
  })
  default = null
}

variable "app_gateway_attachment" {
  description = "Optional Application Gateway backend pool attachment (single-NIC VM or VMSS), independent of lb_attachment"
  type = object({
    backend_pool_id = string
  })
  default = null
}

# -------- VMSS / Autoscale --------

variable "enable_autoscale" {
  description = "Enable autoscaling (VMSS only)"
  type        = bool
  default     = false
}

variable "instance_count" {
  description = "Default number of instances (VMSS)"
  type        = number
  default     = 1
}

variable "autoscale_min_instances" {
  type    = number
  default = 1
}

variable "autoscale_max_instances" {
  type    = number
  default = 3
}

variable "autoscale_cpu_scale_out_threshold" {
  type    = number
  default = 70
}

variable "autoscale_cpu_scale_in_threshold" {
  type    = number
  default = 30
}

variable "autoscale_cooldown" {
  type    = string
  default = "PT5M"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "attach_nsg_to_nic" {
  description = "Whether to associate an NSG to the VM NIC (NIC-level NSG)."
  type        = bool
  default     = false
}

# Attach an NSG at NIC level (preferred for 'compute' module)
variable "nsg_id" {
  description = "Optional NSG ID to associate to the NIC (single VM). If null, no NIC-level NSG association is made."
  type        = string
  default     = null
}

variable "custom_data" {
  description = "Base64-encoded custom_data (cloud-init). Null disables custom_data."
  type        = string
  default     = null
}

variable "identity_type" {
  description = "Managed identity type for compute resources. Use None to disable or SystemAssigned to enable a system-assigned managed identity."
  type        = string
  default     = "None"

  validation {
    condition     = contains(["None", "SystemAssigned"], var.identity_type)
    error_message = "identity_type must be either 'None' or 'SystemAssigned'."
  }
}
