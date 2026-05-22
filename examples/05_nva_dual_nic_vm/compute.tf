module "compute" {
  source = "github.com/mlinxfeld/terraform-az-fk-compute"

  name                = var.nva_vm_name
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  deployment_mode = "vm"
  vm_size         = var.vm_size

  ssh_public_key = tls_private_key.public_private_key_pair.public_key_openssh
  lb_attachment  = null

  network_interfaces = {
    outside = {
      subnet_id                     = module.vnet.subnet_ids["fk-subnet-outside"]
      private_ip_address_allocation = "Static"
      private_ip_address            = var.outside_private_ip
      enable_ip_forwarding          = true
      attach_nsg_to_nic             = true
      nsg_id                        = module.nsg_outside.id
      primary                       = true
    }
    inside = {
      subnet_id                     = module.vnet.subnet_ids["fk-subnet-inside"]
      private_ip_address_allocation = "Static"
      private_ip_address            = var.inside_private_ip
      enable_ip_forwarding          = true
      attach_nsg_to_nic             = true
      nsg_id                        = module.nsg_inside.id
      primary                       = false
    }
  }

  custom_data = base64encode(<<-EOF
    #cloud-config
    packages:
      - iptables-persistent
      - curl
      - traceroute
    runcmd:
      - sysctl -w net.ipv4.ip_forward=1
      - sed -i '/^net.ipv4.ip_forward/d' /etc/sysctl.conf
      - echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
      - sysctl -w net.ipv4.conf.all.rp_filter=0
      - sysctl -w net.ipv4.conf.default.rp_filter=0
      - sed -i '/^net.ipv4.conf.all.rp_filter/d' /etc/sysctl.conf
      - sed -i '/^net.ipv4.conf.default.rp_filter/d' /etc/sysctl.conf
      - echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
      - echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
    EOF
  )

  tags = var.tags
}
