output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "mysql_name" {
  value = azurerm_mysql_flexible_server.mysql.name
}

output "lb_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_admin_user" {
  value = azurerm_mysql_flexible_server.mysql.administrator_login
}

output "mysql_admin_password" {
  value     = random_password.dbadminpassword.result
  sensitive = true
}

output "web_vms" {
  value = azurerm_linux_virtual_machine.web[*].name
}

output "web_vms_private_ips" {
  value = azurerm_linux_virtual_machine.web[*].private_ip_address
}
