# 🛠️ Jenkins-Ansible Control Plane
> **Solution Pillar**: Phase 2 — Self-Service Management & Post-Provisioning.

This repository provides the UI-driven control plane for the **[Enterprise LAMP Hosting infrastructure](../azure-lamp-hosting)**. Once the infrastructure is provisioned via Terraform, this dashboard allows you to manage the server lifecycle, deploy sites, and perform database operations without touching the CLI.

---

## 🏗️ The Shared Hosting Journey

1.  **Phase 1 (Infra)**: Deploy the Azure backbone using **[azure-lamp-hosting](../azure-lamp-hosting)**.
2.  **Phase 2 (Control Plane)**: Configure the servers and launch this dashboard (You are here).

---

## 📋 Installation

### 1️⃣ The DevOps Handoff (Prerequisites)

Before starting the control plane, you must have the outputs from the **Phase 1** Terraform deployment. 

Copy the following files from your `azure-lamp-hosting/terraform/` directory into this repository's `ansible/` directory:

| Filename | Destination Path | Purpose |
| :--- | :--- | :--- |
| `hosts` | `ansible/hosts` | Ansible inventory of your Azure VMs. |
| `database_vars.yml` | `ansible/playbooks/var_files/database_vars.yml` | MySQL connection details. |
| `webadmin_rsa` | `ansible/webadmin_rsa` | Private key for SSH access to the VMs. |

**Other Requirements:**
- **Docker:** Installed on the control node.
- **Backup Storage:** NFS or Azure Files mount must be available at `/backup`.
- **Vault Secret:** Ensure your Ansible vault password is at `/etc/ansible/vault.txt` (if using encrypted vars).

### 2️⃣ Backup Directory Structure

Prepare the storage volume for site and database backups:

```bash
mkdir -p /backup/new-shared01/{production,preproduction}/{apache_conf_backup,database_backup,site_config_backup}
```

### Jenkins Setup

1. **Clone the Repository and Start Jenkins:**
   ```bash
   cd /data/jenkins-ansible
   mkdir jenkins-home site-data
   git clone https://github.com/chinmaymjog/jenkins-ansible.git .
   chmod 777 jenkins-home
   docker compose up -d
   ```
2. **Access Jenkins:**  
   Visit [http://1.2.3.4:8082](http://1.2.3.4:8082) after starting the container.

3. **Retrieve the Initial Admin Password:**
   ```bash
   docker exec jenkins-ansible cat /var/lib/jenkins/initialAdminPassword
   ```
4. **Complete Initial Setup:**  
   Follow the setup wizard and install the following plugins:
   - Active Choices Plug-in
   - Environment Injector
   - ThinBackup

## Jenkins Configuration

The Jenkins UI provides an interactive interface for running Ansible playbooks by letting you choose parameters.

### Example: Creating a Freestyle Project

1. **New Item Creation:**
   - From the **Administrative Tools** folder, click **New Item**.
   - Enter a name (e.g., `ping_test`) and select **Freestyle project**.
2. **Project Configuration:**
   - Add a project description.
   - Enable **This project is parameterized**.
   - Add an **Active Choices Parameter** with:
     - **Parameter Name:** `web_environment`
     - **Groovy Script:** `return ['preproduction','production']`
   - ![Parameter Screenshot](./images/parameter.png)
3. **Build Step:**
   - Under **Build Steps**, select **Execute shell**.
   - Enter the command:
     ```bash
     sudo ansible-playbook --extra-vars "web_environment=${web_environment}" /etc/ansible/playbooks/ping.yml
     ```
4. **Post-build Actions:**
   - Add **Editable Email Notification**.
   - In the advanced settings, change the trigger from default to **Always**.
   - ![Post Build Screenshot 1](./images/post_build_1.png)
   - ![Post Build Screenshot 2](./images/post_build_2.png)
5. **Running the Job:**
   - From **Administrative Tools**, choose **Build with Parameters**.
   - Select an environment (e.g., `preproduction`) and click **Build**.
   - Check the console output via the green build button.
   - ![Build Run Screenshot](./images/build_run.png)

The job will execute a command similar to:

```bash
sudo ansible-playbook --extra-vars "web_environment=preproduction" /etc/ansible/playbooks/ping.yml
```

## Playbooks

Below is a list of available playbooks and their corresponding Jenkins jobs, along with key configuration details like parameter types, Groovy scripts, and a brief description of each job.

| Playbook                                                                         | Usage                                                                    |
| :------------------------------------------------------------------------------- | :----------------------------------------------------------------------- |
| [server_hardening.yml](./ansible/playbooks/server_hardening.yml)                 | [server_hardening](./docs/playbooks.md#server_hardening)                 |
| [server_web_configuration.yml](./ansible/playbooks/server_web_configuration.yml) | [configure_web_server](./docs/playbooks.md#configure_web_server)         |
| [php_install.yml](./ansible/playbooks/php_install.yml)                           | [php_install](./docs/playbooks.md#php_install)                           |
| [php_site_add.yml](./ansible/playbooks/php_site_add.yml)                         | [site_add](./docs/playbooks.md#site_add)                                 |
| [php_site_enable.yml](./ansible/playbooks/php_site_enable.yml)                   | [site_enable](./docs/playbooks.md#site_enable)                           |
| [php_site_disable.yml](./ansible/playbooks/php_site_disable.yml)                 | [site_disable](./docs/playbooks.md#site_disable)                         |
| [php_site_remove.yml](./ansible/playbooks/php_site_remove.yml)                   | [site_remove](./docs/playbooks.md#site_remove)                           |
| [html_site_add.yml](./ansible/playbooks/html_site_add.yml)                       | [site_add](./docs/playbooks.md#site_add)                                 |
| [html_site_enable.yml](./ansible/playbooks/html_site_enable.yml)                 | [site_enable](./docs/playbooks.md#site_enable)                           |
| [html_site_disable.yml](./ansible/playbooks/html_site_disable.yml)               | [site_disable](./docs/playbooks.md#site_disable)                         |
| [html_site_remove.yml](./ansible/playbooks/html_site_remove.yml)                 | [site_remove](./docs/playbooks.md#site_remove)                           |
| [http_auth_add.yml](./ansible/playbooks/http_auth_add.yml)                       | [http_auth_add](./docs/playbooks.md#http_auth_add)                       |
| [http_auth_enable.yml](./ansible/playbooks/http_auth_enable.yml)                 | [http_auth_enable](./docs/playbooks.md#http_auth_enable)                 |
| [http_auth_disable.yml](./ansible/playbooks/http_auth_disable.yml)               | [http_auth_disable](./docs/playbooks.md#http_auth_disable)               |
| [site_list.yml](./ansible/playbooks/site_list.yml)                               | [site_list](./docs/playbooks.md#site_list)                               |
| [backup_apache_config.yml](./ansible/playbooks/backup_apache_config.yml)         | [backup_apache_config](./docs/playbooks.md#backup_apache_config)         |
| [backup_site_config.yml](./ansible/playbooks/backup_site_config.yml)             | [backup_site_config](./docs/playbooks.md#backup_site_config)             |
| [backup_databases.yml](./ansible/playbooks/backup_databases.yml)                 | [backup_databases](./docs/playbooks.md#backup_databases)                 |
| [db_dump.yml](./ansible/playbooks/db_dump.yml)                                   | [db_dump](./docs/playbooks.md#db_dump)                                   |
| [generate_csr.yml](./ansible/playbooks/generate_csr.yml)                         | [generate_csr](./docs/playbooks.md#generate_csr)                         |
| [generate_pfx.yml](./ansible/playbooks/generate_pfx.yml)                         | [generate_pfx](./docs/playbooks.md#generate_pfx)                         |
| [ping.yml](./ansible/playbooks/ping.yml)                                         | [ping](./docs/playbooks.md#ping)                                         |
