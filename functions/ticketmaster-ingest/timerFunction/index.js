const axios = require("axios");
const { DataLakeServiceClient, StorageSharedKeyCredential } = require("@azure/storage-file-datalake");

module.exports = async function (context, myTimer) {
    context.log("Ticketmaster ingestion started");

    try {
        const apiKey = process.env.TICKETMASTER_API_KEY;

        let page = 0;
        let totalPages = 1;
        let allEvents = [];

        // --- Fetch all pages ---
        while (page < totalPages) {
            const url = `https://app.ticketmaster.com/discovery/v2/events.json?countryCode=CH&size=200&page=${page}&apikey=${apiKey}`;

            const response = await axios.get(url);
            const data = response.data;

            totalPages = data.page.totalPages;

            if (data._embedded?.events) {
                allEvents.push(...data._embedded.events);
            }

            context.log(`Fetched page ${page + 1} of ${totalPages}`);
            page++;
        }

        context.log(`Total events fetched: ${allEvents.length}`);

        // --- Data Lake config ---
        const accountName = process.env.DATALAKE_ACCOUNT_NAME;
        const accountKey  = process.env.DATALAKE_ACCOUNT_KEY;
        const fileSystemName = process.env.EVENTS_CONTAINER_NAME;

        const credential = new StorageSharedKeyCredential(accountName, accountKey);
        const serviceClient = new DataLakeServiceClient(
            `https://${accountName}.dfs.core.windows.net`,
            credential
        );

        const fileSystemClient = serviceClient.getFileSystemClient(fileSystemName);

        // --- File name ---
        const date = new Date().toISOString().split("T")[0];
        const fileName = `raw/events/events_${date}.json`;

        const fileClient = fileSystemClient.getFileClient(fileName);

        const dataBuffer = Buffer.from(JSON.stringify(allEvents));

        await fileClient.create({ overwrite: true });
        await fileClient.append(dataBuffer, 0, dataBuffer.length);
        await fileClient.flush(dataBuffer.length);

        context.log(`Uploaded ${allEvents.length} events to ${fileName}`);

    } catch (error) {
        context.log.error("Ingestion failed:", error.message || error);
    }
};
