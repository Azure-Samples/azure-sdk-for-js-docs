# Azure Identity Brokered Authentication Console App

This sample demonstrates how to use brokered authentication with the Azure Identity library for JavaScript/TypeScript in a Node.js console application. This is the JavaScript equivalent of the .NET console app for brokered authentication.

## Overview

Brokered authentication provides several benefits:

- **Single Sign-On (SSO)**: Enables apps to simplify how users authenticate with Microsoft Entra ID and protects refresh tokens from exfiltration and misuse
- **Enhanced security**: Many security enhancements are delivered with the broker, without needing to update the app logic
- **Enhanced feature support**: With the help of the broker, developers can access rich OS and service capabilities
- **System integration**: Applications that use the broker plug-and-play with the built-in account picker

## Prerequisites

1. **Node.js**: Ensure you have Node.js installed (version 14.x or higher)
2. **Azure subscription**: You need an active Azure subscription
3. **Azure Key Vault**: Create an Azure Key Vault instance and add a secret named "MySecret"
4. **Azure CLI or similar**: You should be signed into Azure using Azure CLI, Visual Studio, or another supported credential
5. **Permissions**: Your user account needs appropriate permissions to access the Key Vault secrets

## Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Build the TypeScript code**:
   ```bash
   npm run build
   ```

3. **Update the Key Vault URL**:
   Edit `src/broker.ts` and replace `<your-key-vault-name>` with your actual Key Vault name:
   ```typescript
   const vaultUri = "https://your-actual-keyvault-name.vault.azure.net/";
   ```

4. **Ensure you have a secret**:
   Create a secret named "MySecret" in your Key Vault, or update the code to use an existing secret name.

## Running the Sample

```bash
npm run start:broker
```

## How It Works

The sample demonstrates the following brokered authentication flow:

1. **Plugin Registration**: Registers the native broker plugin with the Azure Identity library
2. **Credential Configuration**: Creates an `InteractiveBrowserCredential` with broker options:
   - `enabled: true` - Enables brokered authentication
   - `useDefaultBrokerAccount: true` - Attempts silent authentication with the default system account
   - `parentWindowHandle` - Set to empty buffer for console applications
3. **Service Integration**: Uses the credential with Azure Key Vault's `SecretClient`
4. **Error Handling**: Provides comprehensive error handling for authentication and service errors

## Key Features

- **Silent Authentication**: When `useDefaultBrokerAccount` is `true`, the broker attempts to authenticate silently with the default system account
- **Fallback to Interactive**: If silent authentication fails, the credential falls back to interactive authentication
- **Comprehensive Error Handling**: The sample includes specific error handling for:
  - Authentication failures
  - Key Vault access issues
  - Invalid URLs
  - Network and other unexpected errors

## Error Codes

The application returns different exit codes based on the type of error:

- `0`: Success
- `1`: Unexpected error
- `2`: Authentication failed
- `3`: Key Vault request failed
- `4`: Invalid Key Vault URL

## Supported Platforms

Brokered authentication is supported on:
- **Windows**: Uses Windows Authentication Manager (WAM)
- **macOS**: Uses the system authentication broker
- **Linux**: Uses the system authentication capabilities

## Troubleshooting

1. **Authentication Errors**: 
   - Ensure you're signed into Azure via Azure CLI: `az login`
   - Check that your account has access to the Key Vault

2. **Key Vault Access Issues**:
   - Verify the Key Vault URL is correct
   - Ensure your user account has "Key Vault Secrets User" role or equivalent permissions
   - Check that the secret "MySecret" exists in your Key Vault

3. **Build Issues**:
   - Make sure all dependencies are installed: `npm install`
   - Verify TypeScript compilation: `npm run build`

## Related Documentation

- [Azure Identity Brokered Authentication Documentation](https://docs.microsoft.com/en-us/dotnet/api/overview/azure/identity-readme#brokered-authentication)
- [Azure Identity JavaScript SDK](https://github.com/Azure/azure-sdk-for-js/tree/main/sdk/identity/identity)
- [Azure Key Vault JavaScript SDK](https://github.com/Azure/azure-sdk-for-js/tree/main/sdk/keyvault/keyvault-secrets)