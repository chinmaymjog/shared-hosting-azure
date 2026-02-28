output "web_details" {
  value = <<CUSTOM_OUTPUT

Hub Resource Group Name = ${module.hub.hub_rg_name}
Front Door Name = ${module.hub.fd_name}
Netapp Account Name = ${module.hub.netapp_account_name}
Netapp Pool Name = ${module.hub.netapp_pool_name}
DNS Zone Name = ${module.hub.dns_zone_name}
Key Vault Name = ${module.hub.key_vault_name}
Container Registry Login Server = ${module.hub.container_registry_login_server}
Container Registry Admin Username = ${module.hub.container_registry_admin_username}

Bastion VM Public IP = ${module.hub.vm_ip}
Bastion VM Private IP = ${module.hub.vm_private_ip}

Production Resource Group Name = ${module.prod-web.resource_group_name}
Production MySQL server Name = ${module.prod-web.mysql_name}
Production Load Balancer IP = ${module.prod-web.lb_ip}
  Production Web Server Private IPs:
  %{for vmidx, vmname in module.prod-web.web_vms~}
  ${vmname} = ${module.prod-web.web_vms_private_ips[vmidx]}
  %{endfor~}

PreProduction Resource Group Name = ${module.preprod-web.resource_group_name}
PreProduction MySQL server Name = ${module.preprod-web.mysql_name}
PreProduction Load Balancer IP = ${module.preprod-web.lb_ip}
  PreProduction Web Server Private IPs:
  %{for vmidx, vmname in module.preprod-web.web_vms~}
  ${vmname} = ${module.preprod-web.web_vms_private_ips[vmidx]}
  %{endfor~}

CUSTOM_OUTPUT  
}

resource "local_file" "hosts" {
  content  = <<EOF
[production]
%{for vmidx, vmname in module.prod-web.web_vms~}
${vmname} ansible_host=${module.prod-web.web_vms_private_ips[vmidx]}
%{endfor~}

[preproduction]
%{for vmidx, vmname in module.preprod-web.web_vms~}
${vmname} ansible_host=${module.preprod-web.web_vms_private_ips[vmidx]}
%{endfor~}
EOF
  filename = "${path.module}/hosts"
}

resource "local_file" "database_vars" {
  content  = <<EOF
preproduction:
  db_host: ${module.preprod-web.mysql_fqdn}
  db_port: 3306
  db_user: ${module.preprod-web.mysql_admin_user}
  db_pass: ${module.preprod-web.mysql_admin_password}

production:
  db_host: ${module.prod-web.mysql_fqdn}
  db_port: 3306
  db_user: ${module.prod-web.mysql_admin_user}
  db_pass: ${module.prod-web.mysql_admin_password}
EOF
  filename = "${path.module}/database_vars.yml"
}

resource "null_resource" "upload_vars" {
  depends_on = [
    local_file.hosts,
    local_file.database_vars,
    module.hub
  ]

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.vm_user}/semaphore/vars"
    ]

    connection {
      type        = "ssh"
      user        = var.vm_user
      private_key = file("${path.root}/webadmin_rsa")
      host        = module.hub.vm_ip
    }
  }

  provisioner "file" {
    source      = "${path.module}/hosts"
    destination = "/home/${var.vm_user}/semaphore/vars/hosts"

    connection {
      type        = "ssh"
      user        = var.vm_user
      private_key = file("${path.root}/webadmin_rsa")
      host        = module.hub.vm_ip
    }
  }

  provisioner "file" {
    source      = "${path.module}/database_vars.yml"
    destination = "/home/${var.vm_user}/semaphore/vars/database_vars.yml"

    connection {
      type        = "ssh"
      user        = var.vm_user
      private_key = file("${path.root}/webadmin_rsa")
      host        = module.hub.vm_ip
    }
  }
}
