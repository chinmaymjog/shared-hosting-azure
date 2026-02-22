# Part 3: Ansible – Configuration Management (Semaphore Guide)

This guide details how to configure and run the project's Ansible playbooks using the **Ansible Semaphore** UI.

## Semaphore Project Structure

All playbooks are located in `ansible-control-plane/ansible/playbooks/`. Group your Task Templates into **Views** for better organization.

### Shared Prerequisites
For all templates, ensure the following are selected:
- **Key Store**: `BastionKey`
- **Inventory**: `Azure Dynamic Inventory`
- **Repository**: `GitHub Repo`

### Variable Management in Semaphore
- **Survey Variables**: These are dynamic inputs prompted at runtime. Per user requirements, **all variables below should be defined as Survey Variables** in your Task Templates.
- **Pro Tip**: To avoid re-defining the same Survey Variables multiple times, use the **Clone** feature in the Task Template view to duplicate an existing template and simply change the playbook path.

---

## View: Server Administration
Core tasks for initial server setup and base configurations.

### 1. Hardening (server_hardening.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/server_hardening.yml`
- **Description**: Applies security best practices.

### 2. Install PHP (php_install.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/php_install.yml`
- **Survey Variables**:
  - `php_version`: e.g., `php8.3`

### 3. Base Web Configuration (server_web_configuration.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/server_web_configuration.yml`
- **Description**: Sets up Apache base settings. Requires `web_vars.yml`.

---

## View: Website Management
Daily operations for managing hosted sites.

### 1. Add Website (site_add.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/php_site_add.yml` (or `html_site_add.yml`)
- **Survey Variables**:
  - `web_environment`: `production` or `preproduction`
  - `site_url`: e.g., `www.example.com`
  - `php_version`: e.g., `php8.3` (only for PHP sites)

### 2. Remove Website (site_remove.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/php_site_remove.yml` (or `html_site_remove.yml`)
- **Survey Variables**:
  - `web_environment`: `production` or `preproduction`
  - `site_url`: e.g., `www.example.com`

### 3. Enable/Disable Site
- **Playbook Paths**: `...site_enable.yml` / `...site_disable.yml`
- **Survey Variables**: Same as Remove Website.

### 4. Database Operations (db_dump.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/db_dump.yml`
- **Survey Variables**:
  - `web_environment`: `production` or `preproduction`
  - `site_url`: Matches the site name.

---

## View: Security & Auth
Management of SSL certificates and access controls.

### 1. Add HTTP Auth (http_auth_add.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/http_auth_add.yml`
- **Survey Variables**:
  - `web_environment`: `production` or `preproduction`
  - `site_url`: The target site.

### 2. Generate CSR (generate_csr.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/generate_csr.yml`
- **Survey Variables**:
  - `commonName`: The domain name.
  - `countryName`, `localityName`, `organizationName`, etc.
  - `subjectAltName`: Optional DNS SANs.

### 3. Upload Cert & Generate PFX (generate_pfx.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/generate_pfx.yml`
- **Description**: Generates a PFX certificate and imports it into Azure Key Vault.
- **Survey Variables**:
  - `commonName`: The domain name.
  - `csrDate`: The date suffix used in files (e.g., `2024-02-22`).
  - `private_key_file`: Filename of the existing private key.
  - `azure_keyvault_uri`: The target Key Vault URL.
  - `azure_keyvault_cert_name`: Name for the cert in Key Vault.

---

## View: Backups
Maintenance tasks for disaster recovery.

### 1. Database Backups (backup_databases.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/backup_databases.yml`
- **Survey Variables**:
  - `web_environment`: `production` or `preproduction`

### 2. Infrastructure Backups (backup_apache_config.yml)
- **Playbook Path**: `ansible-control-plane/ansible/playbooks/backup_apache_config.yml`
- **Survey Variables**:
  - `web_environment`: `production` or `preproduction`
