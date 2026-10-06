# Example 08: VM Scale Set behind Azure Application Gateway

In this compute example, we deploy a **VM Scale Set** behind
**Azure Application Gateway** using **Terraform / OpenTofu**.

The example focuses on the compute module's **explicit backend pool attachment**,
composing it with the dedicated `terraform-az-fk-application-gateway` module.

---

## 🧭 Architecture Overview

<img src="08_app_gateway_backend_attachment_vmss_architecture.jpg" width="900"/>

*Figure 1. HTTP traffic reaches the private VM Scale Set through Application Gateway; NAT Gateway supplies outbound connectivity.*

This deployment creates:

- One **Resource Group**, following the `resource_group.tf` convention in examples 01–06

- One **Virtual Network** via `terraform-az-fk-vnet`
- Two subnets: **`fk-subnet-app-gateway`** (`10.70.0.0/24`) and
  **`fk-subnet-private`** (`10.70.1.0/24`)
- One **Standard Public IP** via `terraform-az-fk-public-ip`
- One **Standard_v2 Application Gateway** via `terraform-az-fk-application-gateway`
- One **Linux VM Scale Set** with two instances and dynamic private IPs via `terraform-az-fk-compute`
- One **Network Security Group** on the compute subnet via `terraform-az-fk-nsg`
- One **NAT Gateway** via `terraform-az-fk-natgw` for compute outbound connectivity
- Cloud-init configuration that installs and starts **NGINX**

Traffic flow:

Internet → Application Gateway HTTP listener → `web` backend pool → VM Scale Set (NGINX)

The gateway and compute share a VNet and use separate subnets.
Networking and compute are composed through **FoggyKitchen modules**.
The Resource Group is created in `resource_group.tf`, as in examples 01–06.

This is a **compute attachment integration example**, not a full production landing zone.

---

## 🎯 Why This Example Exists

The earlier load-balanced examples use Azure Load Balancer.
This example demonstrates the separate **Application Gateway attachment contract**:

- Pass a gateway backend pool ID through `app_gateway_attachment`
- Consume the gateway module's real `backend_address_pool_ids` output
- Keep gateway creation and compute attachment as explicit module composition
- Preserve the existing `lb_attachment` contract, which can be used independently
  or simultaneously with `app_gateway_attachment`

The VMSS joins the gateway pool through its native
`network_interface.ip_configuration.application_gateway_backend_address_pool_ids`
argument, configured inside the compute module. New instances inherit the pool
membership from the scale set model.

---

## ⚙️ Inputs Worth Noting

- `resource_group_name` — name of the Azure Resource Group to create
- `location` — Azure region; defaults to `westeurope`
- `subnets` — purpose-driven subnet map, following examples 01–06
- `ssh_public_key` — your SSH public key; never supply a private key
- `vm_size` — Azure VM size; defaults to `Standard_B1s`, as in examples 01–06

### Backend Pool Initialization

The gateway creates an empty `web` backend pool (`web = {}`). The compute
module then registers the VM NIC or VMSS instances through the pool ID.
No seed IP or external backend is required. Do not also list the attached NIC's
IP in `ip_addresses`: Azure rejects duplicate membership through an explicit
address and a NIC association.

Application Gateway is pinned to **v0.1.2**. Public IP is pinned to **v1.0.0**.
The compute module uses the local repository source (`../..`) so validation
checks the implementation under development.

---

## 🚀 Deployment Steps

From the `examples/08_app_gateway_backend_attachment_vmss` directory:

1. Set `TF_VAR_resource_group_name` to the Resource Group name to create.
2. Set `TF_VAR_ssh_public_key` to the contents of your SSH public key file.

Check the configuration before deployment:

```bash
tofu fmt -check
tofu init -backend=false
tofu validate
```

For a deployment in your own subscription, after reviewing the configuration:

```bash
tofu plan
tofu apply
```

NAT Gateway supplies outbound connectivity for NGINX installation. Check that
any existing routing and policies allow gateway traffic to TCP/80.
The compute NSG allows TCP/80 from `10.70.0.0/24` and denies other inbound
traffic, including SSH. Default outbound rules remain available for cloud-init.
The backend compute has no directly attached public IP.

---

## 🔧 Key Module Pattern

The attachment is configured in `compute.tf`:

```hcl
app_gateway_attachment = {
  backend_pool_id = module.app_gateway.backend_address_pool_ids["web"]
}
```

The compute deployment mode is `"vmss"`.
The `attached_app_gateway_backend_pool_ids` output returns the attached gateway
pool ID as a list. The existing `attached_backend_pool_ids` output remains LB-only.

Configuration follows the repository's split-file convention:

- `resource_group.tf` — Resource Group creation
- `networks.tf` — VNet, subnets and NAT Gateway module composition
- `nsg.tf` — compute subnet NSG, HTTP from gateway subnet only
- `public_ip.tf` — gateway Public IP module
- `application_gateway.tf` — listeners, probes, routing and backend pool
- `compute.tf` — compute module and backend attachment
- `outputs.tf` — compute ID, gateway pool IDs and public IP
- `variables.tf` and `providers.tf` — inputs and provider requirements

---

## ✅ Validation

The configuration consumes Application Gateway **v0.1.2**, which supports
empty backend pools for compute attachments. `tofu fmt -check`, `tofu init`
and `tofu validate` verify the configuration and module contracts; they do not
prove deployed backend health or connectivity.

### Deployment Result

The lab was deployed and tested on 2026-10-06:

```console
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
```

VMSS instances `0` and `1` reported `Succeeded` and `PowerState/running`.

### Backend Health Test

Run from this example directory:

```bash
az network application-gateway show-backend-health \
  --resource-group "$(tofu output -raw resource_group_name)" \
  --name fk-app-gateway \
  --query 'backendAddressPools[].backendHttpSettingsCollection[].servers[].{address:address,health:health,detail:healthProbeLog}' \
  --output json
```

Observed result:

```json
[
  {
    "address": "10.70.1.4",
    "detail": "Success. Received 200 status code",
    "health": "Healthy"
  },
  {
    "address": "10.70.1.5",
    "detail": "Success. Received 200 status code",
    "health": "Healthy"
  }
]
```

### HTTP End-to-End Test

```bash
curl -sS -i --max-time 30 "http://$(tofu output -raw gateway_public_ip)/"
```

The tested frontend was `108.142.242.33`. Its response included:

```console
HTTP/1.1 200 OK
Content-Type: text/html
Server: nginx/1.18.0 (Ubuntu)
```

The HTML contained `<h1>Welcome to nginx!</h1>`. Immediately after provisioning,
the gateway initially returned 502 while the backends did not yet serve HTTP.
A subsequent check after instance initialization returned 200 with both backends
Healthy. Wait for these results before capturing backend-health screenshots.

Both instances serve the same default page, so the browser response verifies
the HTTP path; the health check separately verifies both registered backends.

---

## 🖼️ Azure Portal View

The following screenshots document the deployed lab.

<img src="08_app_gateway_backend_attachment_vmss_portal_overview.jpg" width="900"/>

*Figure 2. Resources in fk-rg, including Application Gateway, VMSS, VNet, NSG, NAT Gateway and public IPs.*

<img src="08_app_gateway_backend_attachment_vmss_instances.jpg" width="900"/>

*Figure 3. Both VMSS instances are Running, with provisioning state Succeeded and the latest model applied.*

<img src="08_app_gateway_backend_attachment_vmss_frontend_ip.jpg" width="900"/>

*Figure 4. Public frontend 108.142.242.33 is associated with the HTTP listener.*

<img src="08_app_gateway_backend_attachment_vmss_backend_pool.jpg" width="900"/>

*Figure 5. The web backend pool references fk-web-vmss as a VMSS target and the web routing rule, without an explicit IP address or FQDN target.*

<img src="08_app_gateway_backend_attachment_vmss_backend_health.jpg" width="900"/>

*Figure 6. Both private backends, 10.70.1.4 and 10.70.1.5, are Healthy on HTTP port 80; probes received status code 200.*

<img src="08_app_gateway_backend_attachment_vmss_network_settings.jpg" width="900"/>

*Figure 7. VMSS network configuration references fk-subnet-private and its subnet NSG.*

<img src="08_app_gateway_backend_attachment_vmss_no_public_ip.jpg" width="900"/>

*Figure 8. Instance fk-web-vmss_0 uses private IP 10.70.1.4 without a public IP; its subnet has fk-private-subnet-nsg attached.*

<img src="08_app_gateway_backend_attachment_vmss_nsg_rules.jpg" width="900"/>

*Figure 9. TCP/80 is allowed from 10.70.0.0/24 at priority 100; other inbound traffic is denied at priority 4096.*

<img src="08_app_gateway_backend_attachment_vmss_web_browser_check.jpg" width="900"/>

*Figure 10. The Application Gateway public frontend serves the NGINX welcome page.*

---

## 🧹 Cleanup

After your own deployment:

```bash
tofu destroy
```

The Resource Group is managed by this example.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
