#!/usr/bin/env bash
# ============================================================
# setup-oidc.sh
# Run ONCE to create the managed identity + federated OIDC
# credential that GitHub Actions uses — no stored secrets.
# ============================================================
set -euo pipefail

SUBSCRIPTION_ID="<your-subscription-id>"
TENANT_ID="<your-tenant-id>"
RESOURCE_GROUP="rg-github-identity"
LOCATION="eastus"
IDENTITY_NAME="id-github-actions"
GITHUB_ORG="<your-github-org>"
GITHUB_REPO="<your-repo-name>"

echo "▶ Logging in..."
az login --tenant "$TENANT_ID"
az account set --subscription "$SUBSCRIPTION_ID"

echo "▶ Creating resource group for identity..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "▶ Creating user-assigned managed identity..."
az identity create \
  --name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"

IDENTITY_CLIENT_ID=$(az identity show \
  --name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query clientId -o tsv)

IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query principalId -o tsv)

echo "  Client ID    : $IDENTITY_CLIENT_ID"
echo "  Principal ID : $IDENTITY_PRINCIPAL_ID"

echo "▶ Granting Contributor + User Access Administrator at subscription scope..."
# Contributor — needed to deploy resources
az role assignment create \
  --assignee "$IDENTITY_PRINCIPAL_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# User Access Administrator — needed to assign roles (IAM module)
az role assignment create \
  --assignee "$IDENTITY_PRINCIPAL_ID" \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --condition "$(cat <<'EOF'
@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidEquals {
  7f951dda-4ed3-4680-a7ca-43fe172d538d,
  4633458b-17de-408a-b874-0445c86b69e6,
  b86a8fe4-44ce-4948-aee5-eccb2c155cd7,
  ba92f5b4-2d11-453d-a403-e96b0029c9fe,
  2a2b9908-6ea1-4ae2-8e65-a410df84e7d1,
  8311e382-0749-4cb8-b61a-304f252e45ec
}
EOF
)" \
  --condition-version "2.0"

echo "▶ Creating federated credentials (OIDC)..."

# main branch
az identity federated-credential create \
  --name "github-main" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange"

# develop branch
az identity federated-credential create \
  --name "github-develop" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/develop" \
  --audiences "api://AzureADTokenExchange"

# Pull requests
az identity federated-credential create \
  --name "github-prs" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${GITHUB_ORG}/${GITHUB_REPO}:pull_request" \
  --audiences "api://AzureADTokenExchange"

echo ""
echo "════════════════════════════════════════════════════"
echo "✅ Done! Add these GitHub Actions secrets:"
echo ""
echo "  AZURE_TENANT_ID              = $TENANT_ID"
echo "  AZURE_SUBSCRIPTION_ID        = $SUBSCRIPTION_ID"
echo "  AZURE_CLIENT_ID              = $IDENTITY_CLIENT_ID"
echo "  GITHUB_ACTIONS_PRINCIPAL_ID  = $IDENTITY_PRINCIPAL_ID"
echo "════════════════════════════════════════════════════"