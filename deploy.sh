#!/bin/bash

# ==============================================================================
# deployments.sh
# Agnostic wrapper script to safely trigger Terraform deployments locally or via CI
# Centralized State Management in Azure Storage Account
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
    echo "Note: If ARM_* environment variables are missing, the script will attempt"
    echo "      to use your existing Azure CLI login session."
}

# Function to extract variables from terraform.tfvars robustly
get_tf_var() {
    local var_name=$1
    local file_path=$2
    # Matches: var_name = "value" (with optional spaces and comments)
    # Using a simpler grep + sed for better compatibility
    grep -E "^\s*${var_name}\s*=" "$file_path" | head -n 1 | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/'
}

# Auto-load variables from .env if present (useful for local execution)
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    # Filters out comments and empty lines, then exports
    set -a
    [ -f .env ] && . .env
    set +a
fi

# Verify the script is run from the root
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "ERROR: Please run this script from the root of the repository."
    exit 1
fi

# Verify/Generate SSH Keys
if [ ! -f "${TERRAFORM_DIR}/webadmin_rsa" ] || [ ! -f "${TERRAFORM_DIR}/webadmin_rsa.pub" ]; then
    echo "=> SSH keys not found in ${TERRAFORM_DIR}. Generating them now..."
    ssh-keygen -t rsa -f "${TERRAFORM_DIR}/webadmin_rsa" -N "" -q
    echo "   - Generated webadmin_rsa and webadmin_rsa.pub"
fi

COMMAND=$1
if [[ "$COMMAND" != "plan" && "$COMMAND" != "apply" && "$COMMAND" != "destroy" ]]; then
    print_usage
    exit 1
fi

project=$(get_tf_var "project" "$TERRAFORM_DIR/terraform.tfvars")
p_short=$(get_tf_var "p_short" "$TERRAFORM_DIR/terraform.tfvars")
location=$(get_tf_var "location" "$TERRAFORM_DIR/terraform.tfvars")
l_short=$(get_tf_var "l_short" "$TERRAFORM_DIR/terraform.tfvars")

if [ -z "$project" ] || [ -z "$p_short" ] || [ -z "$location" ] || [ -z "$l_short" ]; then
    echo "ERROR: Could not parse project naming variables from $TERRAFORM_DIR/terraform.tfvars"
    echo "Make sure they are defined like: project = \"webhost\""
    exit 1
fi

# Sanitize storage account name (Azure requires lowercase alphanumeric, max 24 chars)
# We'll strip hyphens/underscores and convert to lowercase for the TF state SA
SANITI_P_SHORT=$(echo "${p_short}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
SANITI_L_SHORT=$(echo "${l_short}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-5)

TF_RG_NAME="rg-tfstate-${project}-${l_short}"
TF_SA_NAME="sttfstate${SANITI_P_SHORT}${SANITI_L_SHORT}"
TF_CONTAINER_NAME="tfstate-${project}"
TF_STATE_KEY="${project}-${l_short}.tfstate"

echo "=> Verifying Azure Authentication..."
if [ -n "$ARM_CLIENT_ID" ] && [ -n "$ARM_CLIENT_SECRET" ] && [ -n "$ARM_TENANT_ID" ]; then
    echo "   - Logging in via Service Principal..."
    az login --service-principal \
      --username "$ARM_CLIENT_ID" \
      --password "$ARM_CLIENT_SECRET" \
      --tenant "$ARM_TENANT_ID" > /dev/null
else
    echo "   - Service Principal variables missing. Checking for active CLI session..."
    if ! az account show > /dev/null 2>&1; then
        echo "   - No active session found. Please run 'az login' first or provide Service Principal credentials in .env"
        exit 1
    fi
fi

if [ -n "$ARM_SUBSCRIPTION_ID" ]; then
    az account set -s "$ARM_SUBSCRIPTION_ID" > /dev/null
fi

echo "=> Ensuring Terraform Remote State Infrastructure in Azure..."
if ! az group show -n "$TF_RG_NAME" &>/dev/null; then
    echo "   - Creating resource group: $TF_RG_NAME"
    az group create -n "$TF_RG_NAME" -l "$location" -o none
fi

if ! az storage account show -n "$TF_SA_NAME" -g "$TF_RG_NAME" &>/dev/null; then
    echo "   - Creating storage account: $TF_SA_NAME (State storage)"
    az storage account create -n "$TF_SA_NAME" -g "$TF_RG_NAME" -l "$location" --sku Standard_LRS --encryption-services blob -o none
fi

if ! az storage container show --account-name "$TF_SA_NAME" -n "$TF_CONTAINER_NAME" &>/dev/null; then
    echo "   - Creating storage container: $TF_CONTAINER_NAME"
    az storage container create -n "$TF_CONTAINER_NAME" --account-name "$TF_SA_NAME" -o none
fi

echo "=> Fetching current execution IP for firewall punching..."
CURRENT_IP=$(curl -s --max-time 5 https://ifconfig.me || curl -s --max-time 5 https://api.ipify.org)
if [ -z "$CURRENT_IP" ]; then
    echo "WARNING: Could not detect public IP. Firewall rules might not be updated correctly."
else
    echo "   - Current IP detected as: $CURRENT_IP"
    # Parse existing ip_allow from terraform.tfvars
    # This handles both spaces and different quote types
    EXISTING_IPS_RAW=$(grep "ip_allow" ${TERRAFORM_DIR}/terraform.tfvars | sed -E 's/.*= *\[(.*)\].*/\1/' | tr -d '"' | tr -d "'")
    
    # Rebuild the list with the current IP
    if [ -n "$EXISTING_IPS_RAW" ]; then
        # Create comma separated quoted list
        NEW_IP_ALLOW="["
        IFS=',' read -ra ADDR <<< "$EXISTING_IPS_RAW"
        for i in "${ADDR[@]}"; do
            trimmed=$(echo $i | xargs)
            if [ -n "$trimmed" ]; then NEW_IP_ALLOW+="\"$trimmed\", "; fi
        done
        NEW_IP_ALLOW+="\"$CURRENT_IP\"]"
    else
        NEW_IP_ALLOW="[\"$CURRENT_IP\"]"
    fi

    cat <<EOF > ${TERRAFORM_DIR}/dynamic_ip.auto.tfvars
ip_allow = $NEW_IP_ALLOW
EOF

    # Punch Firewalls for KeyVault/Storage if they exist
    # Using project and location variables for resource discovery
    HUB_RG="rg-${p_short}-hub-${l_short}"
    KV_NAME="kv-${p_short}-hub-${l_short}"
    ST_NAME="st${p_short}hub${l_short}"

    if az keyvault show --name "$KV_NAME" --resource-group "$HUB_RG" > /dev/null 2>&1; then
      echo "   - Whitelisting $CURRENT_IP in Key Vault: $KV_NAME"
      az keyvault network-rule add --name "$KV_NAME" --resource-group "$HUB_RG" --ip-address "$CURRENT_IP" > /dev/null
    fi

    if az storage account show --name "$ST_NAME" --resource-group "$HUB_RG" > /dev/null 2>&1; then
      echo "   - Whitelisting $CURRENT_IP in Storage Account: $ST_NAME"
      az storage account network-rule add --account-name "$ST_NAME" --resource-group "$HUB_RG" --ip-address "$CURRENT_IP" > /dev/null
    fi
fi

# Ensure backend.tf exists
cat <<EOF > ${TERRAFORM_DIR}/backend.tf
terraform {
  backend "azurerm" {}
}
EOF

TF_INIT="terraform init \
    -backend-config=resource_group_name=${TF_RG_NAME} \
    -backend-config=storage_account_name=${TF_SA_NAME} \
    -backend-config=container_name=${TF_CONTAINER_NAME} \
    -backend-config=key=${TF_STATE_KEY} \
    -reconfigure"

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
esac
