# Part 4: Production Hardening Guide

This guide explains how to transition your shared hosting platform from a minimal-cost testing setup to a **Production-Grade** environment.

> 💡 **Tip:** You do not have to wait until after deployment to use these settings. If you are ready for production now, you can configure these variables in `terraform.tfvars` **before** running your initial `./deploy.sh apply`.

## ⚖️ Comparison: Testing vs. Production

| Feature | Testing (Default) | Production (Recommended) |
| :--- | :--- | :--- |
| **Compute Size** | `Standard_B1s` | `Standard_D2s_v5` (or higher) |
| **Database SKU** | `B_Standard_B1s` (Burst) | `GP_Standard_D2ds_v5` (General Purpose) |
| **Database HA** | Disabled (`db_ha_enabled = false`) | **Enabled** (`db_ha_enabled = true`) |
| **Storage Redundancy**| `LRS` (Local) | **ZRS** (Zone Redundant) |
| **Security (WAF)** | Disabled (`waf_enabled = false`) | **Enabled** (`waf_enabled = true`) |
| **Central Logging**| Disabled (`logging_enabled = false`)| **Enabled** (`logging_enabled = true`) |
| **Backups** | Disabled (`backup_enabled = false`) | **Enabled** (`backup_enabled = true`) |
| **ACR SKU** | `Basic` | `Standard` or `Premium` |

---

## 🛠️ How to Enable Production Features

Edit your `terraform.tfvars` file and adjust the following toggles:

### 1. High Availability & Redundancy
To ensure your platform survives a data center outage, enable Zone Redundancy.

```hcl
# terraform.tfvars
db_ha_enabled            = true
storage_replication_type = "ZRS"
preferred_zone           = "1" # Resources strictly collocated here
```

### 2. Security (WAF)
Enable the Web Application Firewall for Azure Front Door to protect against common web attacks (SQLi, XSS, etc.).

```hcl
waf_enabled = true
```

### 3. Observability & Backups
Enable centralized logging to Log Analytics and automated daily backups for your Web VMs.

```hcl
logging_enabled = true
backup_enabled  = true
```

---

## 🚀 Scaling for Performance

Beyond the toggles, you should scale up the compute and storage resources for production traffic:

```hcl
# Compute Scaling
webvm_size  = "Standard_D2s_v5"
webvm_count = 3                   # Increase for better load distribution

# Database Scaling
dbsku  = "GP_Standard_D2ds_v5"
dbsize = 128                      # GB

# NetApp Performance
netapp_sku            = "Premium"
netapp_pool_size_intb = 4         # Minimum 4TB for Premium/Ultra
```

---

## 🔒 Post-Deployment Security

1. **Rotate Key Vault Secrets**: Regularly update DB passwords.
2. **Review NSG Rules**: Audit `ip_allow` to ensure only necessary administrative IPs are whitelisted.
3. **WAF in Prevention Mode**: The built-in WAF policy is set to `Prevention` mode by default when enabled. Monitor logs to ensure legitimate traffic isn't blocked.
