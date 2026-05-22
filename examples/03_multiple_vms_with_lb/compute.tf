module "compute" {
  count  = var.vm_number

  source = "github.com/mlinxfeld/terraform-az-fk-compute"

  name                = "${var.vm_name}${count.index + 1}"
  location            = azurerm_resource_group.foggykitchen_rg.location
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name

  deployment_mode = "vm"
  subnet_id        = module.vnet.subnet_ids["fk-subnet-private"]

  attach_nsg_to_nic = false

  admin_username = var.admin_username
  ssh_public_key = tls_private_key.public_private_key_pair.public_key_openssh
  vm_size        = var.vm_size

  lb_attachment = {
    backend_pool_id = module.loadbalancer.backend_pool_id
  }

  tags = var.tags

custom_data = base64encode(<<EOF
#cloud-config
package_update: true
package_upgrade: true

packages:
  - nginx

write_files:
  - path: /var/www/html/index.html
    owner: root:root
    permissions: '0644'
    content: |
      <html>
      <head><title>FoggyKitchen LB Demo</title></head>
      <body>
        <h1>It works ✅</h1>
        <p>Served by: <b>__HOSTNAME__</b></p>
        <p>Time: <b>__TIME__</b></p>
      </body>
      </html>

runcmd:
  # Replace placeholders with real values
  - sed -i "s/__HOSTNAME__/$(hostname)/g" /var/www/html/index.html
  - sed -i "s/__TIME__/$(date -Is)/g" /var/www/html/index.html

  # Ensure nginx is enabled and running
  - systemctl enable nginx
  - systemctl restart nginx

  # Optional: allow through UFW if it ever gets enabled later
  - ufw allow 'Nginx Full' || true
EOF
)


}
