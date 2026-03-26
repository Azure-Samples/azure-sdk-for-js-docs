import { SecretClient } from "@azure/keyvault-secrets";
import { RestError } from "@azure/core-rest-pipeline";
import { AuthenticationError } from "@azure/identity";

// <BROKER>
import { useIdentityPlugin, InteractiveBrowserCredential } from "@azure/identity";
import { nativeBrokerPlugin } from "@azure/identity-broker";

// Register the native broker plugin for brokered authentication
useIdentityPlugin(nativeBrokerPlugin);

// Use InteractiveBrowserCredential with broker for interactive or silent authentication

// On Windows: Uses Windows Authentication Manager (WAM) - you'll be prompted to sign in
// On macOS: Opens a browser window for authentication, since the broker flow isn't currently supported.
// On Linux: Uses Microsoft Single Sign-on (SSO) for Linux.

const credential = new InteractiveBrowserCredential({
    brokerOptions: {
        enabled: true,
        useDefaultBrokerAccount: true,
        // For Node.js console apps, we need to provide an empty buffer for parentWindowHandle
        parentWindowHandle: new Uint8Array(0),
    },
});
// </BROKER>

try {
    // Configure Key Vault client
    // Set AZURE_KEY_VAULT_URL environment variable or update this line with your vault URL
    const vaultUri = process.env.AZURE_KEY_VAULT_URL! || "https://<your-key-vault-name>.vault.azure.net/";
    console.log(`Using Key Vault URL: ${vaultUri}`);

    if (vaultUri.includes("<your-key-vault-name>")) {
        console.error("❌ Please set the AZURE_KEY_VAULT_URL environment variable or update the vaultUri in the code.");
        console.error("   Example: export AZURE_KEY_VAULT_URL=\"https://your-vault-name.vault.azure.net/\"");
        process.exit(4);
    }

    const client = new SecretClient(vaultUri, credential);

    console.log("Retrieving secret 'MySecret' from Key Vault...");

    // Retrieve the secret
    const secret = await client.getSecret("MySecret");

    console.log(`✅ Secret 'MySecret' retrieved successfully!`);
    console.log(`🔑 Value: ${secret.value}`);
    console.log(`📅 Created: ${secret.properties.createdOn?.toISOString()}`);
    console.log("✅ Done");
    
    process.exit(0);
} catch (error) {
    if (error instanceof AuthenticationError) {
        console.error(`🔐 Authentication failed: ${error.message}`);
        process.exit(2);
    } else if (error instanceof RestError) {
        if (error.statusCode) {
            const errorMessage = error.statusCode === 401
                ? "❌ Authentication failed. Please ensure you're signed in to Azure and have the correct permissions."
                : error.statusCode === 403
                    ? "🚫 Access denied. Please check your Azure Key Vault access policies."
                    : error.statusCode === 404
                        ? "🔍 Secret 'MySecret' not found in the Key Vault. Please verify the secret name and Key Vault URL."
                        : `⚠️ Azure Key Vault error (${error.statusCode}): ${error.message}`;

            console.error(errorMessage);
            process.exit(3);
        }
    } else if (error instanceof Error && error.message.includes("Invalid URL")) {
        console.error("🌐 Invalid Key Vault URL. Please update the vaultUri in the code with your actual Key Vault URL.");
        process.exit(4);
    }

    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`💥 An unexpected error occurred: ${errorMessage}`);
    process.exit(1);
}