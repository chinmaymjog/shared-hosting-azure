output "hub_rg_name" {
  value = azurerm_resource_group.hub.name
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "fd_name" {
  value = azurerm_cdn_frontdoor_profile.fd.name
}

output "prod_endpoint_id" {
  value = azurerm_cdn_frontdoor_endpoint.prod-endpoint.id
}

output "prod_origin_group_id" {
  value = azurerm_cdn_frontdoor_origin_group.prod_origin_group.id
}

output "preprod_endpoint_id" {
  value = azurerm_cdn_frontdoor_endpoint.preprod-endpoint.id
}

output "preprod_origin_group_id" {
  value = azurerm_cdn_frontdoor_origin_group.preprod_origin_group.id
}

output "netapp_account_name" {
  value = azurerm_netapp_account.netapp_account.name
}

output "netapp_pool_name" {
  value = azurerm_netapp_pool.netapp_pool.name
}

output "dns_zone_name" {
  value = azurerm_private_dns_zone.dns-zone.name
}

output "dns_zone_id" {
  value = azurerm_private_dns_zone.dns-zone.id
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "vm_ip" {
  value = azurerm_public_ip.pip-vm.ip_address
}

output "vm_private_ip" {
  value = azurerm_linux_virtual_machine.vm.private_ip_address
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "container_registry_admin_username" {
  value = azurerm_container_registry.acr.admin_username
}
