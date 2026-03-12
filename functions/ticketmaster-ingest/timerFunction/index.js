const axios = require("axios");
const { DefaultAzureCredential } = require("@azure/identity");
const { DataLakeServiceClient } = require("@azure/storage-file-datalake");

module.exports = async function (context, myTimer) {
    context.log("Ticketmaster ingestion started");

    try {
        // Ticketmaster API
        const apiKey = process.env.TICKETMASTER_API_KEY;
        const url = `https://app.ticketmaster.com/discovery/v2/events.json?city=Zurich&apikey=${apiKey}`;
        const response = await axios.get(url);
        const events = response.data;

        // ADLS client
        const accountName = process.env.DATALAKE_ACCOUNT_NAME;
        const fileSystemName = "events";
        const credential = new DefaultAzureCredential();
        const serviceClient = new DataLakeServiceClient(
            `https://${accountName}.dfs.core.windows.net`,
            credential
        );

        const fileSystemClient = serviceClient.getFileSystemClient(fileSystemName);

        // Ensure filesystem exists
        if (!(await fileSystemClient.exists())) {
            await fileSystemClient.create();
        }

        // Create file
        const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
        const fileName = `raw/events_${timestamp}.json`;
        const fileClient = fileSystemClient.getFileClient(fileName);

        const dataBuffer = Buffer.from(JSON.stringify(events), "utf-8");
        await fileClient.create({ overwrite: true });
        await fileClient.append(dataBuffer, 0, dataBuffer.byteLength);
        await fileClient.flush(dataBuffer.byteLength);

        context.log(`Ticketmaster events uploaded to ${fileName}`);
    } catch (error) {
        context.log.error("Failed to ingest Ticketmaster events:", error.message || error);
    }
};
