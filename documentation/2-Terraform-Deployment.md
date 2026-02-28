# Part 2: Terraform – Deploying Azure Infrastructure

## 📘 Introduction

In this section, we automate the provisioning of the shared hosting platform’s Azure infrastructure using **Terraform**. The setup emphasizes modularity, scalability, security, and zone-aware deployment strategies.

![Terraform Flow](./images/terraform-flow.png)

---

## 🧱 Prerequisites

1. An active [Azure account](https://azure.microsoft.com/en-us/free/)
2. A [**Service Principal**](https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) with the **Contributor** role assigned to your [Azure subscription](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
3. **Provider Registration**: Ensure the `Microsoft.NetApp` provider is registered in your subscription:
   ```bash
   az provider register --namespace Microsoft.NetApp
   ```

---

## 📁 Project Structure

```bash
azure-lamp-hosting/terraform/
├── modules/
│   ├── hub/              # Shared components
│   └── web/              # Environment-specific components
├── .env                  # Azure credentials (not committed)
├── main.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars      # Variable values
├── variables.tf          # Variable definitions
├── webadmin_rsa          # Private SSH key (Auto-generated)
└── webadmin_rsa.pub      # Public SSH key (Auto-generated)
```

---

The `.env` file is automatically detected and loaded by the `deploy.sh` script.

> 💡 **Developer Tip:** If you are running this locally and do not wish to use a Service Principal, simply ensure you are logged in via the Azure CLI (`az login`). The `deploy.sh` script will detect your active session and use it automatically.

> ⚠️ **Important:** Never commit `.env` to version control.

---

## ⚙️ Configure `terraform.tfvars`

Customize your infrastructure by editing the `azure-lamp-hosting/terraform/terraform.tfvars` file. Sample values:

```hcl
project             = "webhost"
p_short             = "host"
location            = "centralindia"
l_short             = "inc"
preferred_zone      = "1"
vm_user             = "webadmin"
ip_allow            = ["152.58.XX.XX", "X.X.X.X"] # ADD YOUR PUBLIC IP HERE

> ⚠️ **Warning:** If you do not include your current public IP in `ip_allow`, you will be unable to access the Key Vault and Storage Account from your local machine, which may cause `deploy.sh` to fail during firewall punching.

hub_vnet_space        = ["10.0.0.0/24"]
hub_snet_web          = ["10.0.0.0/26"]
bastion_size          = "Standard_B2s"
bastion_osdisk        = 64
netapp_sku            = "Standard"
netapp_pool_size_intb = 1
file_share_quota      = 100

webvm_size            = "Standard_B2s"
webvm_count           = 2
webvm_osdisk          = 64
dbsku                 = "GP_Standard_D2ads_v5"
dbsize                = 20
netapp_volume_sku     = "Standard"
storage_quota_in_gb   = 100

preprod_vnet_space    = ["10.0.2.0/24"]
preprod_snet_web      = ["10.0.2.0/26"]
preprod_snet_db       = ["10.0.2.64/26"]
preprod_snet_netapp   = ["10.0.2.128/26"]

prod_vnet_space       = ["10.0.1.0/24"]
prod_snet_web         = ["10.0.1.0/26"]
prod_snet_db          = ["10.0.1.64/26"]
prod_snet_netapp      = ["10.0.1.128/26"]
```

> 💡 **Zone Awareness & Enforcement**
> To guarantee sub-millisecond latency and avoid cross-zone data transfer costs, our Terraform configuration **strictly enforces** that all VMs and NetApp volumes are deployed in the exact same Availability Zone. You only need to define the `preferred_zone` variable (valid options: `"1"`, `"2"`, or `"3"`). Terraform will validate this input and automatically collocate all compute and storage resources within that specific specified zone.

---

## 🔑 SSH Access – Key Pair

The `deploy.sh` script requires an SSH key pair to provision and manage the VMs. 

**You do not need to generate these manually.** If the keys are missing from `azure-lamp-hosting/terraform/`, the script will automatically generate them for you using `ssh-keygen` during the first run. The public key is then injected into the VMs and uploaded to the Azure Key Vault for use by Ansible Semaphore.

---

## 🚀 Terraform Deployment Steps

```bash
# From the root of the shared-hosting-azure repository
# Ensure your local .env file is populated with Azure credentials

# (Optional) Review execution plan
./deploy.sh plan

# Apply infrastructure
./deploy.sh apply
```

> 🛡️ **Agnostic State Management:** Whether running locally or in a GitHub Actions pipeline, `deploy.sh` ensures your Terraform state is securely stored in a centralized Azure Storage Account. This eliminates the "lost local state" problem and allows multiple team members (or CI runners) to manage the same infrastructure safely.

---

## ✅ Sample Output

Once complete, Terraform will display key outputs:

```
Hub Resource Group Name = rg-host-hub-inc
Front Door Name = fd-host-hub-inc
Netapp Account Name = netapp-host-hub-inc
Netapp Pool Name = pool-host-hub-inc
DNS Zone Name = host.mysql.database.azure.com
Key Vault Name = kv-host-hub-inc
Container Registry Login Server = acrhosthubinc.azurecr.io
Container Registry Admin Username = acrhosthubinc

Bastion VM Public IP = 135.235.XX.0
Bastion VM Private IP = 10.0.0.4

Production Resource Group Name = rg-host-prd-inc
Production MySQL server Name = mysql-host-prd-inc
Production Load Balancer IP = 135.235.XX.22
  Production Web Server Private IPs
  web-host-prd-inc-0 = 10.0.1.5
  web-host-prd-inc-1 = 10.0.1.4

PreProduction Resource Group Name = rg-host-pprd-inc
PreProduction MySQL server Name = mysql-host-pprd-inc
PreProduction Load Balancer IP = 52.172.195.226
  PreProduction Web Server Private IPs
  web-host-pprd-inc-0 = 10.0.2.4
  web-host-pprd-inc-1 = 10.0.2.5
```

> 📁 A `hosts` file will also be generated—this is your **Ansible inventory**.
>
> **Link to Automation**: Once provisioned, Azure will expose the public IP for the **Bastion Host**. You will use the generated `webadmin_rsa` key to SSH into the Bastion Host, where the next phase (`ansible-control-plane/`) resides.

---

## 🔧 Terraform Modules Overview

### `module "hub"` – Shared Core Resources

- Azure Front Door
- Hub VNet & Subnets
- Bastion VM with disks and IPs
- Azure NetApp Account, Pool, and Share
- Key Vault & DNS Zone
- Azure Container Registry (ACR)

### `module "web"` – Per-Environment Resources (Prod & Preprod)

- VNet and subnets for Web, DB, and NetApp
- Web Server VMs with disks and NSGs
- Load Balancer
- Azure Database for MySQL (Flexible Server)
- NetApp Volumes (one per environment)
- Peering with Hub Network

All per-environment modules consume outputs from the `hub` module for seamless integration.

---

🔜 **Next:** [Part 3: Ansible Configuration Management](./3-Ansible-Playbooks.md)
