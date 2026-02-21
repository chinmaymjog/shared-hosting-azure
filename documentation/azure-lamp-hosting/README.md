# ☁️ Enterprise LAMP Hosting Platform (IaC)
> **Solution Pillar**: Infrastructure as Code (IaC) for the Shared Hosting Solution.

This repository is the **primary entry point** for deploying a multi-tier Azure infrastructure. It uses **Terraform** to provision the foundation and is designed to work seamlessly with the **[jenkins-ansible control plane](../jenkins-ansible)** (Phase 2).

---

## 🚀 Quick Start: The 2-Phase Journey

Building your shared hosting platform involves two distinct phases:

### 1️⃣ Phase 1: Infrastructure (In this Repo)
Provision the Azure backbone (VNet, App Gateway, NetApp, MySQL, VMs).
*   **Go to**: [Terraform Deployment Guide](./terraform/README.md)

### 2️⃣ Phase 2: Control Plane (In jenkins-ansible)
Configure the servers and launch the management dashboard.
*   **Go to**: [Post-Provisioning Guide](../jenkins-ansible/README.md)

---

## 🏗️ Technical Architecture

The platform leverages a modern Cloud-Native stack:
- **Compute**: Specialized LAMP-optimized VM Scalesets for high-availability workloads.
- **Storage**: Azure NetApp Files and Azure FileShare for shared persistent assets.
- **Database**: Azure Database for MySQL (Flexible Server).
- **Networking**: Hub-and-Spoke topology with SSL termination at the Application Gateway.
- **Automation**: End-to-end IaC (Terraform) and Configuration Management (Ansible).

Full architectural details can be found in [Part 1: Shared Hosting Platform Architecture](./docs/Part_1.md).

---

## 🧩 Shared Hosting Repositories

This solution consists of two primary repositories that must be used together:

1.  **[azure-lamp-hosting](https://github.com/chinmaymjog/azure-lamp-hosting)** (You are here): Infrastructure as Code.
2.  **[jenkins-ansible](../jenkins-ansible)**: Self-service control plane.

---

## 🤝 The DevOps Handoff (Plug-and-Play)

To link the infrastructure with the control plane immediately after Terraform finishes, follow these steps:

1.  **Generate Keys**: Run `ssh-keygen -t rsa -f webadmin_rsa` in the `terraform/` directory.
2.  **Deploy**: Run `terraform apply`.
3.  **Handoff to Control Plane**: Copy the following files from `terraform/` to the `../jenkins-ansible/ansible/` directory:
    - `hosts` → `../jenkins-ansible/ansible/hosts`
    - `database_vars.yml` → `../jenkins-ansible/ansible/playbooks/var_files/database_vars.yml`
    - `webadmin_rsa` → `../jenkins-ansible/ansible/webadmin_rsa`
4.  **Launch Dashboard**: Continue at the **[jenkins-ansible setup guide](../jenkins-ansible/README.md)**.

---

## 🛡️ License
Distributed under the MIT License. See `LICENSE` for more information.
