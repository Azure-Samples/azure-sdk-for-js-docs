import { DefaultAzureCredential } from "@azure/identity";
import { ResourceManagementClient } from "@azure/arm-resources";

const subscriptionId = process.env.AZURE_SUBSCRIPTION_ID!;
if (!subscriptionId) {
  throw new Error("AZURE_SUBSCRIPTION_ID environment variable is not set.");
}

console.log(`Using Subscription ID: ${subscriptionId}`);

async function main() {

    const credential = new DefaultAzureCredential();
    const client = new ResourceManagementClient(credential, subscriptionId);

    let i=0;

    for await (const item of client.resourceGroups.list()) {
        console.log(`${++i}: ${item.name}`);
    }
    console.log(`Found ${i} resource group(s).`);
}

main().catch((err) => {
  console.error(err);
});