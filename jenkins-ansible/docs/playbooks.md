# Administrative Tools

## backup_apache_config

**Description:** Backs up Apache and PHP-FPM configuration files using Ansible, including core configs, virtual hosts, auth settings, and PHP pools, with timestamped archives for recovery and auditing.

```bash
sudo ansible-playbook --extra-vars "web_environment=preproduction" /etc/ansible/playbooks/backup_apache_config.yml
sudo ansible-playbook --extra-vars "web_environment=production" /etc/ansible/playbooks/backup_apache_config.yml
```

## backup_databases

**Description:** Backs up MySQL databases from preproduction and production using Ansible, with timestamped dumps for disaster recovery and auditing.

```bash
sudo ansible-playbook --extra-vars "web_environment=preproduction" --vault-password-file /etc/ansible/vault.txt /etc/ansible/playbooks/backup_databases.yml
sudo ansible-playbook --extra-vars "web_environment=production" --vault-password-file /etc/ansible/vault.txt /etc/ansible/playbooks/backup_databases.yml
```

## backup_site_config

**Description:** Backs up site-specific configuration files (.env, .htaccess, wp-config.php) using Ansible, with timestamped copies for recovery and auditing.

```bash
sudo ansible-playbook --extra-vars "web_environment=preproduction" /etc/ansible/playbooks/backup_site_config.yml
sudo ansible-playbook --extra-vars "web_environment=production" /etc/ansible/playbooks/backup_site_config.yml
```

## configure_web_server

**Description:** Configures the Apache web server using Ansible by applying virtual host settings, authentication rules, and PHP-FPM integration for the target environment.

```bash
sudo ansible-playbook /etc/ansible/playbooks/server_web_configuration.yml
```

## site_remove

**Description:** Removes a website configuration from the Apache server using Ansible, including virtual host files, auth settings, and associated PHP-FPM configs.

**Parameters:**
| Parameter Type | Parameter | Groovy Script | Referenced parameters |
| --- | --- | --- | --- |
| String Parameter | site_url | | |
| Active Choices Parameter | web_environment | `return['preproduction', 'production']` | |
| Active Choices Parameter | site_type | `return['html', 'php']` | |
| Active Choices Reactive Param| php_version | `if (site_type == 'php') return ['php8.3']; else return ['NA']`| site_type |

**Build Steps:** Execute shell

```bash
if [ -z "$site_url" ]; then
echo "URL cannot be empty"
exit 1
fi

# Handle HTML site deployment
if [ "${site_type}" = "html" ]; then
echo Deleting html site ${site_url} on ${web_environment}
    sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/html_site_remove.yml
fi

# Handle PHP site deployment
if [ "${site_type}" = "php" ]; then
echo Deleting php ${php_version} site ${site_url} on ${web_environment}
    sudo ansible-playbook --extra-vars "site_url=${site_url} php_version=${php_version} web_environment=${web_environment}" --vault-password-file /etc/ansible/vault.txt /etc/ansible/playbooks/php_site_remove.yml
fi
```

## php_install

**Description:** Installs and configures PHP and required extensions using Ansible based on the selected PHP version and site type.

**Parameters:**
| Parameter Type | Parameter |
| --- | --- |
| String Parameter | php_version |

**Build Steps:** Execute shell

```bash
sudo ansible-playbook --extra-vars "php_version=${php_version}" /etc/ansible/playbooks/php_install.yml
```

## server_hardening

**Description:** Applies OS-level security hardening using Ansible, including SSH configuration, firewall rules, package restrictions, and CIS benchmark settings.

**Build Steps:** Execute shell

```bash
sudo ansible-playbook /etc/ansible/playbooks/server_hardening.yml
```

# Hosting Management Portal

## db_dump

**Description:** Creates a timestamped MySQL database dump using Ansible for backup, migration, or troubleshooting purposes.

**Parameters:**
| Parameter Type | Parameter | Groovy Script |
| --- | --- | --- |
| String Parameter | site_url | |
| Active Choices Parameter | web_environment| `return['preproduction', 'production']` |

**Build Steps:** Execute shell

```bash
if [ -z "$site_url" ]; then
echo "URL cannot be empty"
exit 1
fi

sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/db_dump.yml
```

## generate_csr

**Description:** Generates a Certificate Signing Request (CSR) and private key using Ansible for SSL certificate provisioning.

**Parameters:**
| Parameter Type | Parameter |
| --- | --- |
| String Parameter | commonName |
| String Parameter | countryName |
| String Parameter | localityName |
| String Parameter | stateOrProvinceName |
| String Parameter | organizationName |
| String Parameter | organizationalUnitName |
| String Parameter | emailAddress |
| String Parameter | subjectAltName|

```bash
sudo ansible-playbook --extra-vars "commonName=${commonName} countryName=${countryName} localityName=${localityName} stateOrProvinceName=${stateOrProvinceName} organizationName=${organizationName} organizationalUnitName=${organizationalUnitName} emailAddress=${emailAddress} subjectAltName=${subjectAltName}" /etc/ansible/playbooks/generate_csr.yml
sudo cat /site-data/csr/${commonName}/${commonName}*$(date '+%Y-%m-%d').csr
sudo ls -ltr /site-data/csr/${commonName}/
```

## http_auth_add

**Description:** Adds HTTP basic authentication users to the Apache auth-files using Ansible, supporting secure access control for protected sites.

**Parameters:**
| Parameter Type | Parameter | Groovy Script |
| --- | --- | --- |
| String Parameter | site_url | |
| Active Choices Parameter | web_environment| `return['preproduction', 'production']` |

**Build Steps:** Execute shell

```bash
if [ -z "$site_url" ]; then
echo "URL cannot be empty"
exit 1
fi

sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/http_auth_add.yml
```

## http_auth_disable

**Description:** Disables HTTP basic authentication for a site by updating Apache configuration and auth settings using Ansible.

**Parameters:**
| Parameter Type | Parameter | Groovy Script |
| --- | --- | --- |
| String Parameter | site_url | |
| Active Choices Parameter | web_environment| `return['preproduction', 'production']` |

**Build Steps:** Execute shell

```bash
if [ -z "$site_url" ]; then
echo "URL cannot be empty"
exit 1
fi

sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/http_auth_disable.yml
```

## http_auth_enable

**Description:** Enables HTTP basic authentication for a site by configuring Apache and linking the appropriate auth-files using Ansible.

**Parameters:**
| Parameter Type | Parameter | Groovy Script |
| --- | --- | --- |
| String Parameter | site_url | |
| Active Choices Parameter | web_environment| `return['preproduction', 'production']` |

**Build Steps:** Execute shell

```bash
if [ -z "$site_url" ]; then
echo "URL cannot be empty"
exit 1
fi

sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/http_auth_enable.yml
```

## site_add

**Description:** Deploys a new website by configuring Apache virtual hosts, setting up authentication, and applying PHP settings using Ansible.

**Parameters:**
| Parameter Type | Parameter | Groovy Script | Referenced parameters |
| --- | --- | --- | --- |
| String Parameter | site_url | | |
| Active Choices Parameter | web_environment | `return['preproduction', 'production']` | |
| Active Choices Parameter | site_type | `return['html', 'php']` | |
| Active Choices Reactive Param| php_version | `if (site_type == 'php') return ['php8.3']; else return ['NA']`| site_type |

**Build Steps:** Execute shell

```bash
if [ -z "$site_url" ]; then
echo "URL cannot be empty"
exit 1
fi

# Transform site_url for Preprod environment
#if [ "$env" = "preproduction" ]; then
# site_url=$(echo "${site_url}" | tr '.' '-').chinmaymjog.com
#fi

# Handle HTML site deployment
if [ "${site_type}" = "html" ]; then
echo Adding html site ${site_url} on ${web_environment}
    sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/html_site_add.yml
fi

# Handle PHP site deployment
if [ "${site_type}" = "php" ]; then
echo Adding php ${php_version} site ${site_url} on ${web_environment}
    sudo ansible-playbook --extra-vars "site_url=${site_url} php_version=${php_version} web_environment=${web_environment}" --vault-password-file /etc/ansible/vault.txt /etc/ansible/playbooks/php_site_add.yml
fi
```

## site_disable

**Description:** Disables an existing website by unlinking its Apache virtual host configuration and reloading the web server using Ansible.

**Parameters:**
| Parameter Type | Parameter | Groovy Script | Referenced parameters |
| --- | --- | --- | --- |
| String Parameter | site_url | | |
| Active Choices Parameter | web_environment | `return['preproduction', 'production']` | |
| Active Choices Parameter | site_type | `return['html', 'php']` | |

**Build Steps:** Execute shell

```bash
if [ -z "$site_url" ]; then
echo "URL cannot be empty"
exit 1
fi

# Handle HTML site
if [ "${site_type}" = "html" ]; then
echo Disabling html site ${site_url} on ${web_environment}
    sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/html_site_disable.yml
fi

# Handle PHP site
if [ "${site_type}" = "php" ]; then
echo Disabling php ${php_version} site ${site_url} on ${web_environment}
    sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/php_site_disable.yml
fi
```

## site_enable

**Description:** Enables a website by linking its Apache virtual host configuration and reloading the web server using Ansible.

**Parameters:**
| Parameter Type | Parameter | Groovy Script | Referenced parameters |
| --- | --- | --- | --- |
| String Parameter | site_url | | |
| Active Choices Parameter | web_environment | `return['preproduction', 'production']` | |
| Active Choices Parameter | site_type | `return['html', 'php']` | |

**Build Steps:** Execute shell

```bash
if [ -z "$site_url" ]; then
echo "URL cannot be empty"
exit 1
fi

# Handle HTML site
if [ "${site_type}" = "html" ]; then
echo Enabling html site ${site_url} on ${web_environment}
    sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/html_site_enable.yml
fi

# Handle PHP site
if [ "${site_type}" = "php" ]; then
echo Enabling php ${php_version} site ${site_url} on ${web_environment}
    sudo ansible-playbook --extra-vars "site_url=${site_url} web_environment=${web_environment}" /etc/ansible/playbooks/php_site_enable.yml
fi
```

## site_list

**Description:** Lists all available and enabled websites on the Apache server by retrieving virtual host configuration details using Ansible.

**Parameters:**
| Parameter Type | Parameter | Groovy Script |
| --- | --- | --- |
| Active Choices Parameter | web_environment | `return['preproduction', 'production']` |

**Build Steps:** Execute shell

```bash
sudo ansible-playbook --extra-vars "web_environment=${web_environment}" /etc/ansible/playbooks/site_list.yml
```
