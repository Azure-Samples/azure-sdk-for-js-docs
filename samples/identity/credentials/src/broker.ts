import { useIdentityPlugin, InteractiveBrowserCredential, AuthenticationError } from "@azure/identity";
import { nativeBrokerPlugin } from "@azure/identity-broker";
import { SecretClient } from "@azure/keyvault-secrets";

// Register the native broker plugin for brokered authentication
useIdentityPlugin(nativeBrokerPlugin);

async function main(): Promise<number> {
    try {
        // Use InteractiveBrowserCredential with broker for interactive authentication
        // On Windows: Uses Windows Authentication Manager (WAM) - you'll be prompted to sign in
        // On macOS/Linux: Opens a browser window for authentication
        const credential = new InteractiveBrowserCredential({
            tenantId: process.env.AZURE_TENANT_ID!, // Specify your tenant ID
            brokerOptions: {
                enabled: true,
                useDefaultBrokerAccount: true,
                // For Node.js console apps, we need to provide an empty buffer for parentWindowHandle
                parentWindowHandle: new Uint8Array(0),
            },
        });

        // Configure Key Vault client
        // Set AZURE_KEY_VAULT_URL environment variable or update this line with your vault URL
        const vaultUri = process.env.AZURE_KEY_VAULT_URL! || "https://<your-key-vault-name>.vault.azure.net/";
        console.log(`Using Key Vault URL: ${vaultUri}`);

        if (vaultUri.includes("<your-key-vault-name>")) {
            console.error("❌ Please set the AZURE_KEY_VAULT_URL environment variable or update the vaultUri in the code.");
            console.error("   Example: export AZURE_KEY_VAULT_URL=\"https://your-vault-name.vault.azure.net/\"");
            return 4;
        }

        const client = new SecretClient(vaultUri, credential);

        console.log("Retrieving secret 'MySecret' from Key Vault...");

        // Retrieve the secret
        const secret = await client.getSecret("MySecret");

        console.log(`✅ Secret 'MySecret' retrieved successfully!`);
        console.log(`🔑 Value: ${secret.value}`);
        console.log(`📅 Created: ${secret.properties.createdOn?.toISOString()}`);

        return 0;
    } catch (error) {
        if (error instanceof AuthenticationError) {
            console.error(`🔐 Authentication failed: ${error.message}`);
            return 2;
        } else if (error instanceof Error && error.name === "RestError") {
            const restError = error as any;
            if (restError.statusCode) {
                const errorMessage = restError.statusCode === 401
                    ? "❌ Authentication failed. Please ensure you're signed in to Azure and have the correct permissions."
                    : restError.statusCode === 403
                        ? "🚫 Access denied. Please check your Azure Key Vault access policies."
                        : restError.statusCode === 404
                            ? "🔍 Secret 'MySecret' not found in the Key Vault. Please verify the secret name and Key Vault URL."
                            : `⚠️ Azure Key Vault error (${restError.statusCode}): ${restError.message}`;

                console.error(errorMessage);
                return 3;
            }
        } else if (error instanceof Error && error.message.includes("Invalid URL")) {
            console.error("🌐 Invalid Key Vault URL. Please update the vaultUri in the code with your actual Key Vault URL.");
            return 4;
        }

        const errorMessage = error instanceof Error ? error.message : String(error);
        console.error(`💥 An unexpected error occurred: ${errorMessage}`);
        return 1;
    }
}

main().then(() => {
    console.log("✅ Done");
    process.exit(0);
}).catch((error) => {
    console.error(`💥 An unexpected error occurred: ${error.message}`);
    process.exit(1);
});