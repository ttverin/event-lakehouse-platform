from pyspark.sql import SparkSession
from pyspark.sql.functions import col, explode, to_date, current_date

spark = SparkSession.builder.getOrCreate()

# Secrets
storage_account_key = dbutils.secrets.get(scope="ticketmaster-secrets", key="storage_account_key")
ticketmaster_api_key = dbutils.secrets.get(scope="ticketmaster-secrets", key="ticketmaster_api_key")
file_system_name     = "events"

spark.conf.set(
    f"fs.azure.account.key.{storage_account_name}.dfs.core.windows.net",
    storage_account_key
)

# Read raw JSON
raw_path = f"abfss://{file_system_name}@{storage_account_name}.dfs.core.windows.net/raw/"
df = spark.read.json(raw_path)

# Flatten
events_df = df.select(
    col("name").alias("event_name"),
    col("dates.start.dateTime").alias("event_date"),
    explode(col("venues")).alias("venue_info")
).select(
    "event_name",
    "event_date",
    col("venue_info.name").alias("venue_name"),
    col("venue_info.city.name").alias("city")
)

events_df = events_df.withColumn("event_date", to_date(col("event_date")))

# Filter future events and save as Delta
future_events = events_df.filter(col("event_date") >= current_date())
output_path = f"abfss://{file_system_name}@{storage_account_name}.dfs.core.windows.net/processed/"
future_events.write.format("delta").mode("overwrite").save(output_path)
