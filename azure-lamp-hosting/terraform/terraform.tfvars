## Common Variables for Project: webhost
project        = "webhost"
p_short        = "host"
location       = "centralindia"
l_short        = "inc"
preferred_zone = "1" # Preferred Availability Zone (for VMs & NetApp volumes)
vm_user        = "webadmin"
ip_allow       = ["152.59.63.84"] # IP(s) to whitelist for access

## Hub Environment Configuration
hub_vnet_space        = ["10.0.0.0/24"]
hub_snet_web          = ["10.0.0.0/26"]
bastion_size          = "Standard_B1s" # Bastion VM SKU (reduced for testing)
bastion_osdisk        = 32              # Bastion OS disk (in GB)
netapp_sku            = "Standard"      # NetApp Storage SKU
netapp_pool_size_intb = 1               # NetApp Pool size (in TB)
file_share_quota      = 100             # File share quota (in GB)

## Web Environment (Shared Across PreProd & Prod)
webvm_size          = "Standard_B1s"         # Web Server VM SKU (reduced for testing)
webvm_count         = "1"                    # Number of Web VMs (reduced for testing)
webvm_osdisk        = 32                     # OS Disk Size (in GB)
dbsku               = "B_Standard_B1s"       # Azure MySQL Flexible Server SKU (cheapest burstable)
dbsize              = 20                     # Database storage (in GB)
netapp_volume_sku   = "Standard"
storage_quota_in_gb = 100 # NetApp Volume quota (in GB)

## PreProduction Environment Network
preprod_vnet_space  = ["10.0.2.0/24"]
preprod_snet_web    = ["10.0.2.0/26"]
preprod_snet_db     = ["10.0.2.64/26"]
preprod_snet_netapp = ["10.0.2.128/26"]

## Production Environment Network
prod_vnet_space  = ["10.0.1.0/24"]
prod_snet_web    = ["10.0.1.0/26"]
prod_snet_db     = ["10.0.1.64/26"]
prod_snet_netapp = ["10.0.1.128/26"]

# ## Production-Grade Hardening (Set to true/Standard for production)
db_ha_enabled            = false
storage_replication_type = "LRS"
waf_enabled              = false
logging_enabled          = false
backup_enabled           = false
acr_sku                  = "Basic"
