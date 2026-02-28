module "hub" {
  source = "./modules/hub"

  project               = var.project
  p_short               = var.p_short
  location              = var.location
  l_short               = var.l_short
  zone                  = var.preferred_zone
  env                   = "hub"
  e_short               = "hub"
  vnet_space            = var.hub_vnet_space
  snet_web              = var.hub_snet_web
  vm_user               = var.vm_user
  bastion_size          = var.bastion_size
  bastion_osdisk        = var.bastion_osdisk
  ip_allow              = var.ip_allow
  netapp_sku            = var.netapp_sku
  netapp_pool_size_intb = var.netapp_pool_size_intb
  file_share_quota      = var.file_share_quota
  storage_replication_type = var.storage_replication_type
  waf_enabled              = var.waf_enabled
  logging_enabled          = var.logging_enabled
  acr_sku                  = var.acr_sku
}

module "preprod-web" {
  source = "./modules/web"

  project             = var.project
  p_short             = var.p_short
  location            = var.location
  l_short             = var.l_short
  zone                = var.preferred_zone
  env                 = "Preproduction"
  e_short             = "pprd"
  vnet_space          = var.preprod_vnet_space
  snet_web            = var.preprod_snet_web
  snet_db             = var.preprod_snet_db
  snet_netapp         = var.preprod_snet_netapp
  webvm_size          = var.webvm_size
  webvm_count         = var.webvm_count
  webvm_osdisk        = var.webvm_osdisk
  vm_user             = var.vm_user
  dbsku               = var.dbsku
  dbsize              = var.dbsize
  ip_allow            = var.ip_allow
  netapp_volume_sku   = var.netapp_volume_sku
  storage_quota_in_gb = var.storage_quota_in_gb

  # Hub module outputs

  hub_rg_name         = module.hub.hub_rg_name
  hub_vnet_name       = module.hub.hub_vnet_name
  hub_vnet_id         = module.hub.hub_vnet_id
  endpoint_id         = module.hub.preprod_endpoint_id
  origin_group_id     = module.hub.preprod_origin_group_id
  netapp_account_name = module.hub.netapp_account_name
  netapp_pool_name    = module.hub.netapp_pool_name
  dns_zone_name       = module.hub.dns_zone_name
  dns_zone_id         = module.hub.dns_zone_id
  key_vault_id        = module.hub.key_vault_id

  db_ha_enabled       = var.db_ha_enabled
  backup_enabled      = var.backup_enabled
}

module "prod-web" {
  source = "./modules/web"

  project             = var.project
  p_short             = var.p_short
  location            = var.location
  l_short             = var.l_short
  zone                = var.preferred_zone
  env                 = "Production"
  e_short             = "prd"
  vnet_space          = var.prod_vnet_space
  snet_web            = var.prod_snet_web
  snet_db             = var.prod_snet_db
  snet_netapp         = var.prod_snet_netapp
  webvm_size          = var.webvm_size
  webvm_count         = var.webvm_count
  webvm_osdisk        = var.webvm_osdisk
  vm_user             = var.vm_user
  dbsku               = var.dbsku
  dbsize              = var.dbsize
  ip_allow            = var.ip_allow
  netapp_volume_sku   = var.netapp_volume_sku
  storage_quota_in_gb = var.storage_quota_in_gb

  # Hub module outputs

  hub_rg_name         = module.hub.hub_rg_name
  hub_vnet_name       = module.hub.hub_vnet_name
  hub_vnet_id         = module.hub.hub_vnet_id
  endpoint_id         = module.hub.prod_endpoint_id
  origin_group_id     = module.hub.prod_origin_group_id
  netapp_account_name = module.hub.netapp_account_name
  netapp_pool_name    = module.hub.netapp_pool_name
  dns_zone_name       = module.hub.dns_zone_name
  dns_zone_id         = module.hub.dns_zone_id
  key_vault_id        = module.hub.key_vault_id

  db_ha_enabled       = var.db_ha_enabled
  backup_enabled      = var.backup_enabled
}
