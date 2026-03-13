const axios = require("axios");
const { DataLakeServiceClient, StorageSharedKeyCredential } = require("@azure/storage-file-datalake");

module.exports = async function (context, myTimer) {
    context.log("Ticketmaster ingestion started");

    try {
        // --- Fetch Ticketmaster events ---
        const apiKey = process.env.TICKETMASTER_API_KEY;
        const url = `https://app.ticketmaster.com/discovery/v2/events.json?countryCode=CH&apikey=${apiKey}`;
        const response = await axios.get(url);
        const events = response.data;

        // --- Configure Data Lake client using account key ---
        const accountName = process.env.DATALAKE_ACCOUNT_NAME;
        const accountKey  = process.env.DATALAKE_ACCOUNT_KEY;
        const fileSystemName = process.env.EVENTS_CONTAINER_NAME;

        const credential = new StorageSharedKeyCredential(accountName, accountKey);
        const serviceClient = new DataLakeServiceClient(
            `https://${accountName}.dfs.core.windows.net`,
            credential
        );

        const fileSystemClient = serviceClient.getFileSystemClient(fileSystemName);

        // --- Create unique file path ---
        const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
        const fileName = `raw/events_${timestamp}.json`;
        const fileClient = fileSystemClient.getFileClient(fileName);

        // --- Upload data using create + append + flush ---
        const dataBuffer = Buffer.from(JSON.stringify(events));
        await fileClient.create({ overwrite: true });
        await fileClient.append(dataBuffer, 0, dataBuffer.length);
        await fileClient.flush(dataBuffer.length);

        context.log(`Ticketmaster events successfully uploaded to ${fileName}`);
    } catch (error) {
        context.log.error("Failed to ingest Ticketmaster events:", error.message || error);
    }
};
