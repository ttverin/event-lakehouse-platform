from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, to_timestamp, current_timestamp, datediff, current_date

spark = SparkSession.builder.getOrCreate()

# --------------------------
# Config
# --------------------------
storage_account_name = "eventhousest21gp7"
file_system_name     = "events"

storage_account_key  = dbutils.secrets.get(scope="ticketmaster-secrets", key="storage_account_key")

spark.conf.set(
    f"fs.azure.account.key.{storage_account_name}.dfs.core.windows.net",
    storage_account_key
)

# --------------------------
# Read raw JSON
# --------------------------
raw_path = f"abfss://{file_system_name}@{storage_account_name}.dfs.core.windows.net/raw/events/"
df = spark.read.json(raw_path)

# --------------------------
# Flatten events
# --------------------------
events = df.select(
    explode("_embedded.events").alias("event")
)

flat_df = events.select(
    col("event.id").alias("event_id"),
    col("event.name").alias("event_name"),
    col("event.type").alias("event_type"),
    col("event.url").alias("url"),
    col("event.dates.start.dateTime").alias("event_datetime"),
    explode("event._embedded.venues").alias("venue")
)

# --------------------------
# Select venue fields
# --------------------------
clean_df = flat_df.select(
    "event_id",
    "event_name",
    "event_type",
    "url",
    to_timestamp("event_datetime").alias("event_datetime"),
    col("venue.name").alias("venue_name"),
    col("venue.city.name").alias("city"),
    col("venue.country.name").alias("country")
)

# --------------------------
# Add useful columns
# --------------------------
clean_df = clean_df.withColumn(
    "days_until_event",
    datediff(col("event_datetime"), current_date())
)

# --------------------------
# Filter future events
# --------------------------
future_events = clean_df.filter(
    col("event_datetime") >= current_timestamp()
)

# --------------------------
# Write to Delta (structured)
# --------------------------
output_path = f"abfss://{file_system_name}@{storage_account_name}.dfs.core.windows.net/processed/events/"

future_events.write.format("delta").mode("overwrite").save(output_path)

# Optional: register table (recommended for Power BI)
future_events.write.format("delta").mode("overwrite").saveAsTable("events_curated")

print("✅ Processed events ready for dashboard")
