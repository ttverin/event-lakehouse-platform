const axios = require("axios");
const { DefaultAzureCredential } = require("@azure/identity");
const { DataLakeServiceClient } = require("@azure/storage-file-datalake");

module.exports = async function (context, myTimer) {
    context.log("Ticketmaster ingestion started");

    const apiKey = process.env.TICKETMASTER_API_KEY;
    const url = `https://app.ticketmaster.com/discovery/v2/events.json?city=Zurich&apikey=${apiKey}`;

    const response = await axios.get(url);
    const events = response.data;

    const accountName = process.env.DATALAKE_ACCOUNT_NAME;
    const fileSystemName = "events";

    // Use DefaultAzureCredential for managed identity
    const credential = new DefaultAzureCredential();
    const serviceClient = new DataLakeServiceClient(
        `https://${accountName}.dfs.core.windows.net`,
        credential
    );

    const fileSystemClient = serviceClient.getFileSystemClient(fileSystemName);
    const fileName = `raw/events_${new Date().toISOString()}.json`;
    const fileClient = fileSystemClient.getFileClient(fileName);

    await fileClient.uploadData(JSON.stringify(events), {
        overwrite: true
    });

    context.log("Ticketmaster events uploaded");
};
