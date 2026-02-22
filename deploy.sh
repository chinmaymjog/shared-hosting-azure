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
# This ensures that your local setup doesn't lock itself out of Key Vault and Bastion SSH.
echo "=> Fetching current execution IP..."
CURRENT_IP=$(curl -s https://ifconfig.me)
echo "Current IP detected as: $CURRENT_IP"

# Parse existing ip_allow from terraform.tfvars to avoid hardcoding
EXISTING_IPS_RAW=$(grep "ip_allow" ${TERRAFORM_DIR}/terraform.tfvars | sed 's/.*= *\[\(.*\)\].*/\1/')
if [ -n "$EXISTING_IPS_RAW" ]; then
    NEW_IP_ALLOW="[$EXISTING_IPS_RAW, \"$CURRENT_IP\"]"
else
    NEW_IP_ALLOW="[\"$CURRENT_IP\"]"
fi

# Create a high-precedence auto.tfvars file
cat <<EOF > ${TERRAFORM_DIR}/local_dynamic.auto.tfvars
ip_allow = $NEW_IP_ALLOW
EOF

# Dynamic Firewall Punching
# This ensures the current IP can access Key Vault and Storage Account during Plan/Apply
echo "=> Punching Azure Firewalls for current machine IP..."
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

COMMAND=$1

case "$COMMAND" in
    plan)
        echo "=> Running Terraform Plan..."
        cd "$TERRAFORM_DIR"
        terraform init
        terraform plan
        ;;
    apply)
        echo "=> Running Terraform Apply..."
        cd "$TERRAFORM_DIR"
        terraform init
        terraform apply -auto-approve
        ;;
    destroy)
        echo "=> Running Terraform Destroy..."
        cd "$TERRAFORM_DIR"
        terraform init
        terraform destroy -auto-approve
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
