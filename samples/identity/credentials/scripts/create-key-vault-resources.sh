#!/bin/bash

# Azure Key Vault Setup Script for Brokered Authentication Sample
# This script creates a resource group and Key Vault with RBAC permissions
# for the current user to manage secrets

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration variables
RESOURCE_PREFIX="kvbroker"  # Prefix for all resources
LOCATION="eastus"           # Azure region
RANDOM_SUFFIX=$(openssl rand -hex 3)  # Generate 6-character random string

# Derived resource names
RESOURCE_GROUP_NAME="${RESOURCE_PREFIX}rg${RANDOM_SUFFIX}"
KEY_VAULT_NAME="${RESOURCE_PREFIX}kv${RANDOM_SUFFIX}"

print_status "Starting Azure Key Vault setup for brokered authentication sample..."

# Check if user is logged into Azure CLI
print_status "Checking Azure CLI authentication..."
if ! az account show &> /dev/null; then
    print_error "You are not logged into Azure CLI. Please run 'az login' first."
    exit 1
fi

# Get current subscription and user information
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id --output tsv)
CURRENT_USER_UPN=$(az ad signed-in-user show --query userPrincipalName --output tsv)

print_success "Authenticated as: ${CURRENT_USER_UPN}"
print_status "Using subscription: ${SUBSCRIPTION_NAME} (${SUBSCRIPTION_ID})"
print_status "Resource prefix: ${RESOURCE_PREFIX}"
print_status "Random suffix: ${RANDOM_SUFFIX}"
print_status "Location: ${LOCATION}"

# Display resource names that will be created
echo ""
print_status "Resources to be created:"
echo "  - Resource Group: ${RESOURCE_GROUP_NAME}"
echo "  - Key Vault: ${KEY_VAULT_NAME}"
echo ""

# Prompt for confirmation
read -p "Do you want to continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Operation cancelled by user."
    exit 0
fi

# Create resource group
print_status "Creating resource group: ${RESOURCE_GROUP_NAME}..."
az group create \
    --name "${RESOURCE_GROUP_NAME}" \
    --location "${LOCATION}" \
    --output none

if [ $? -eq 0 ]; then
    print_success "Resource group created successfully."
else
    print_error "Failed to create resource group."
    exit 1
fi

# Create Key Vault with RBAC enabled
print_status "Creating Key Vault: ${KEY_VAULT_NAME}..."
az keyvault create \
    --name "${KEY_VAULT_NAME}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --location "${LOCATION}" \
    --enable-rbac-authorization true \
    --output none

if [ $? -eq 0 ]; then
    print_success "Key Vault created successfully."
else
    print_error "Failed to create Key Vault."
    exit 1
fi

# Wait a moment for the Key Vault to be fully provisioned
print_status "Waiting for Key Vault to be fully provisioned..."
sleep 10

# Get the Key Vault resource ID
KEY_VAULT_ID=$(az keyvault show --name "${KEY_VAULT_NAME}" --resource-group "${RESOURCE_GROUP_NAME}" --query id --output tsv)

# Assign Key Vault Secrets Officer role to current user
print_status "Assigning 'Key Vault Secrets Officer' role to current user..."
az role assignment create \
    --role "Key Vault Secrets Officer" \
    --assignee "${CURRENT_USER_OBJECT_ID}" \
    --scope "${KEY_VAULT_ID}" \
    --output none

if [ $? -eq 0 ]; then
    print_success "Role assignment completed successfully."
else
    print_error "Failed to assign role. You may need to assign permissions manually."
fi

# Create a sample secret for testing with retry logic for RBAC propagation
print_status "Creating sample secret 'MySecret' for testing..."
print_warning "Note: RBAC permissions may take up to 5 minutes to propagate. Retrying if needed..."

MAX_RETRIES=12  # 12 retries = up to 6 minutes total
RETRY_COUNT=0
RETRY_DELAY=10  # Start with 10 seconds

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if [ $RETRY_COUNT -gt 0 ]; then
        print_status "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES - Waiting ${RETRY_DELAY} seconds for RBAC propagation..."
        sleep $RETRY_DELAY
        # Increase delay for next retry (exponential backoff, capped at 30s)
        RETRY_DELAY=$((RETRY_DELAY < 30 ? RETRY_DELAY + 5 : 30))
    fi
    
    # Attempt to create the secret
    if az keyvault secret set \
        --vault-name "${KEY_VAULT_NAME}" \
        --name "MySecret" \
        --value "Hello from Azure Key Vault! This is a test secret for brokered authentication." \
        --output none 2>&1; then
        print_success "Sample secret created successfully!"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            print_warning "Failed to create sample secret after $MAX_RETRIES attempts."
            print_warning "RBAC permissions may still be propagating. You can:"
            print_warning "  1. Wait a few more minutes and try manually:"
            print_warning "     az keyvault secret set --vault-name ${KEY_VAULT_NAME} --name MySecret --value 'test'"
            print_warning "  2. Or proceed - the Key Vault is ready, just permissions need time."
        fi
    fi
done

# Display summary
echo ""
print_success "Setup completed successfully!"
echo ""
echo "=== RESOURCE SUMMARY ==="
echo "Resource Group: ${RESOURCE_GROUP_NAME}"
echo "Key Vault Name: ${KEY_VAULT_NAME}"
echo "Key Vault URL: https://${KEY_VAULT_NAME}.vault.azure.net/"
echo "Location: ${LOCATION}"
echo "User: ${CURRENT_USER_UPN}"
echo "Role: Key Vault Secrets Officer"
echo ""
echo "=== NEXT STEPS ==="
echo "1. Set the Key Vault URL as an environment variable:"
echo "   export AZURE_KEY_VAULT_URL=\"https://${KEY_VAULT_NAME}.vault.azure.net/\""
echo ""
echo "   Or add it to your .env file:"
echo "   echo \"AZURE_KEY_VAULT_URL=https://${KEY_VAULT_NAME}.vault.azure.net/\" >> sample.env"
echo ""
echo "2. Run the brokered authentication sample:"
echo "   npm run build"
echo "   npm run start:broker"
echo ""
echo "3. Clean up resources when done:"
echo "   az group delete --name ${RESOURCE_GROUP_NAME} --yes --no-wait"
echo ""

# Save configuration to a file for reference
CONFIG_FILE="./keyvault-config.txt"
cat > "${CONFIG_FILE}" << EOF
# Azure Key Vault Configuration
# Generated on: $(date)

RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME}"
KEY_VAULT_NAME="${KEY_VAULT_NAME}"
KEY_VAULT_URL="https://${KEY_VAULT_NAME}.vault.azure.net/"
LOCATION="${LOCATION}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"
USER_UPN="${CURRENT_USER_UPN}"

# Environment variable to set:
export AZURE_KEY_VAULT_URL="https://${KEY_VAULT_NAME}.vault.azure.net/"

# To clean up these resources:
# az group delete --name ${RESOURCE_GROUP_NAME} --yes --no-wait
EOF

print_success "Configuration saved to: ${CONFIG_FILE}"
print_status "You can now test the brokered authentication sample!"