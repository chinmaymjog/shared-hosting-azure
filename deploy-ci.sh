#!/bin/bash

# ==============================================================================
# deployments.sh
# Wrapper script to safely trigger Terraform deployments for shared-hosting-azure
# ==============================================================================

set -e

TERRAFORM_DIR="azure-lamp-hosting/terraform"

function print_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  plan      Initialize Terraform and generate an execution plan."
    echo "  apply     Apply the Terraform plan to Azure."
    echo "  destroy   Destroy the deployed Azure infrastructure."
    echo ""
    echo "This script requires Azure Service Principal credentials."
    echo "Ensure the following environment variables are set:"
    echo "  ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID"
    echo "Alternatively, you can provide an '.env' file in the root directory."
}

# Auto-load variables from .env if present (useful for local execution)
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Verify required variables
REQUIRED_VARS=("ARM_CLIENT_ID" "ARM_CLIENT_SECRET" "ARM_TENANT_ID" "ARM_SUBSCRIPTION_ID")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Environment variable $var is required but not set."
        exit 1
    fi
done

# Verify SSH Keys exist
if [ ! -f "${TERRAFORM_DIR}/webadmin_rsa" ] || [ ! -f "${TERRAFORM_DIR}/webadmin_rsa.pub" ]; then
    echo "ERROR: SSH keys (webadmin_rsa and webadmin_rsa.pub) not found in ${TERRAFORM_DIR}."
    echo "Please generate them by running:"
    echo "  ssh-keygen -t rsa -f ${TERRAFORM_DIR}/webadmin_rsa -N \"\""
    exit 1
fi

# Automatically append the current executing machine's IP to the allowed list.
# This ensures that CI/CD pipelines (or your local setup) don't lock themselves out of Key Vault and Bastion SSH.
echo "=> Fetching current execution IP..."
CURRENT_IP=$(curl -s https://ifconfig.me)
echo "Current IP detected as: $CURRENT_IP"

# Create a high-precedence auto.tfvars file to override terraform.tfvars
# This ensures it overrides any hardcoded values in terraform.tfvars
cat <<EOF > ${TERRAFORM_DIR}/ci.auto.tfvars
ip_allow = ["34.74.90.64/28", "34.74.226.0/24", "152.59.63.84", "${CURRENT_IP}"]
EOF

# Dynamic Firewall Punching for GitLab Runner
# This ensures the dynamic runner IP can access Key Vault and Storage Account during Plan/Apply
echo "=> Punching Azure Firewalls for current runner IP..."
az login --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" > /dev/null

echo "   - Whitelisting $CURRENT_IP in Key Vault firewall..."
az keyvault network-rule add \
  --name "kv-host-hub-inc" \
  --resource-group "rg-host-hub-inc" \
  --ip-address "$CURRENT_IP" > /dev/null

echo "   - Whitelisting $CURRENT_IP in Storage Account firewall..."
az storage account network-rule add \
  --account-name "sthosthubinc" \
  --resource-group "rg-host-hub-inc" \
  --ip-address "$CURRENT_IP" > /dev/null

# Define INIT command dynamically based on CI environment
if [ -n "$CI_PROJECT_ID" ]; then
    echo "=> CI/CD Pipeline detected. Configuring Managed HTTP Backend..."
    
    # Create a backend override file dynamically so we don't break local execution
    cat <<EOF > ${TERRAFORM_DIR}/backend.tf
terraform {
  backend "http" {}
}
EOF

    # Ensure CI variables are exported properly for the init phase
    TF_INIT="terraform init \
        -backend-config=address=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default \
        -backend-config=lock_address=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default/lock \
        -backend-config=unlock_address=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/default/lock \
        -backend-config=username=gitlab-ci-token \
        -backend-config=password=${CI_JOB_TOKEN} \
        -backend-config=lock_method=POST \
        -backend-config=unlock_method=DELETE \
        -backend-config=retry_wait_min=5"
else
    echo "=> Local execution detected. Initializing with local/default backend..."
    # Ensure no leftover backend file exists locally to avoid accidental lock-ins
    rm -f ${TERRAFORM_DIR}/backend.tf
    TF_INIT="terraform init"
fi

COMMAND=$1

case "$COMMAND" in
    plan)
        echo "=> Running Terraform Plan..."
        cd "$TERRAFORM_DIR"
        $TF_INIT
        terraform plan
        ;;
    apply)
        echo "=> Running Terraform Apply..."
        cd "$TERRAFORM_DIR"
        $TF_INIT
        terraform apply -auto-approve
        ;;
    destroy)
        echo "=> Running Terraform Destroy..."
        cd "$TERRAFORM_DIR"
        $TF_INIT
        terraform destroy -auto-approve
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
