# ## Common variables for project webhost
variable "project" {
  description = "Project name"
}

variable "p_short" {
  description = "Project short name"
}

variable "location" {
  description = "Azure region to deploy"
}

variable "l_short" {
  description = "Location short name"
}

variable "preferred_zone" {
  description = "Preferred availability zone"
}
# variable "env" {
#   description = "Define environment to deploy"
# }

# variable "e_short" {
#   description = "Environment short name"
# }

variable "vm_user" {
  description = "Username for vm user"
}

variable "ip_allow" {
  description = "List of IPs to whitelist"
}

# ## Environment variables for hub

variable "hub_vnet_space" {
  description = "Address space for vnet"
}

variable "hub_snet_web" {
  description = "Address space for web subnet"
}

variable "bastion_size" {
  description = "Size for VM"
}

variable "bastion_osdisk" {
  description = "Os disk size for VM in GB"
}

variable "bastion_datadisk" {
  description = "Data disk size for VM in GB"
}

variable "netapp_sku" {
  description = "Netapp SKU"
}

variable "netapp_pool_size_intb" {
  description = "Netapp pool size in TB"
}


# ## Environment variables for web environments
variable "webvm_size" {
  description = "Size for VM"
}

variable "webvm_count" {
  description = "Count of Web VMs"
}

variable "webvm_osdisk" {
  description = "OS disk size for Web VM in GB"
}

variable "webvm_datadisk" {
  description = "Data disk size for Web VM in GB"
}

variable "dbsku" {
  description = "SKU for Azure Database for MySQL"
}

variable "dbsize" {
  description = "Database size in GB"
}

variable "netapp_volume_sku" {
  description = "SKU for netapp volume"
}

variable "storage_quota_in_gb" {
  description = "Netapp volume size in GB"
}

variable "file_share_quota" {
  description = "File share quota in GB"
}

# ## Environment variables for preproduction
variable "preprod_vnet_space" {
  description = "Address space for vnet"
}

variable "preprod_snet_web" {
  description = "Address space for web subnet"
}

variable "preprod_snet_db" {
  description = "Address space for db subnet"
}

variable "preprod_snet_netapp" {
  description = "Address space for netapp subnet"
}

# ## Environment variables for production
variable "prod_vnet_space" {
  description = "Address space for vnet"
}

variable "prod_snet_web" {
  description = "Address space for web subnet"
}

variable "prod_snet_db" {
  description = "Address space for db subnet"
}

variable "prod_snet_netapp" {
  description = "Address space for netapp subnet"
}
