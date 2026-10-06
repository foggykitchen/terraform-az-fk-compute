variable "location" {
  type    = string
  default = "westeurope"
}
variable "ssh_public_key" {
  description = "Operator SSH public key; no private key is stored in configuration or state."
  type        = string
}
variable "resource_group_name" {
  description = "Resource group name for this example."
  type        = string
}

variable "subnets" {
  description = "Purpose-driven subnets for Application Gateway and private compute."
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    fk-subnet-app-gateway = {
      address_prefixes = ["10.70.0.0/24"]
    }
    fk-subnet-private = {
      address_prefixes = ["10.70.1.0/24"]
    }
  }
}

variable "vm_size" {
  description = "Azure VM size, following the existing compute examples."
  type        = string
  default     = "Standard_B1s"
}
