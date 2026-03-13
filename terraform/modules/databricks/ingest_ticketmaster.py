from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, to_date, current_date

# --------------------------
# Initialize Spark
# --------------------------
spark = SparkSession.builder.getOrCreate()

# --------------------------
# Secrets and parameters
# --------------------------
storage_account_name = "eventhousest21gp7"  # hardcoded for testing
file_system_name     = "events"

storage_account_key  = dbutils.secrets.get(scope="ticketmaster-secrets", key="storage_account_key")
ticketmaster_api_key = dbutils.secrets.get(scope="ticketmaster-secrets", key="ticketmaster_api_key")

# --------------------------
# Configure Spark to access Azure Data Lake
# --------------------------
spark.conf.set(
    f"fs.azure.account.key.{storage_account_name}.dfs.core.windows.net",
    storage_account_key
)

# --------------------------
# Read raw JSON
# --------------------------
raw_path = f"abfss://{file_system_name}@{storage_account_name}.dfs.core.windows.net/raw/"
df = spark.read.json(raw_path)
print("Raw JSON preview:")
df.show(5, truncate=False)

# --------------------------
# Flatten nested Ticketmaster JSON
# --------------------------
# Explode top-level events array
events_array = df.select(explode(col("_embedded.events")).alias("event"))

# Flatten each event and its venues
events_df = events_array.select(
    col("event.name").alias("event_name"),
    col("event.dates.start.dateTime").alias("event_date"),
    explode(col("event._embedded.venues")).alias("venue_info")
).select(
    "event_name",
    "event_date",
    col("venue_info.name").alias("venue_name"),
    col("venue_info.city.name").alias("city")
)

# Convert event_date to date type
events_df = events_df.withColumn("event_date", to_date(col("event_date")))

# --------------------------
# Filter for future events
# --------------------------
future_events = events_df.filter(col("event_date") >= current_date())
print("Future events preview:")
future_events.show(5, truncate=False)

# --------------------------
# Write to Delta
# --------------------------
output_path = f"abfss://{file_system_name}@{storage_account_name}.dfs.core.windows.net/processed/"
future_events.write.format("delta").mode("overwrite").save(output_path)

print(f"Processed events written to {output_path}")
