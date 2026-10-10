-- SwiftHaul Logistics: Task 1, create the dataset and load the native shipments table

-- 1a.
CREATE SCHEMA IF NOT EXISTS swifthaul
OPTIONS (location = 'US');

-- 1b. Load shipments.csv from GCS into a native table.
-- Explicit schema instead of autodetect, so dates are DATE and on_time is BOOL
-- by declaration, not by sampling guess. Money uses NUMERIC (exact decimal).
LOAD DATA OVERWRITE swifthaul.shipments (
  shipment_id        STRING,
  customer_id        STRING,
  order_date         DATE,
  ship_date          DATE,
  delivery_date      DATE,
  origin_region      STRING,
  destination_region STRING,
  carrier            STRING,
  service_level      STRING,
  weight_kg          FLOAT64,
  distance_km        INT64,
  freight_cost_usd   NUMERIC,
  on_time            BOOL,
  status             STRING
)
FROM FILES (
  format = 'CSV',
  uris = ['gs://swifthaul-oforero-2026/shipments.csv'],
  skip_leading_rows = 1
);

-- 1c. Confirm row count (~1.5M) and that dates / on_time typed correctly
SELECT
  COUNT(*)                     AS row_count,
  COUNTIF(on_time)             AS on_time_true,
  COUNTIF(NOT on_time)         AS on_time_false,
  MIN(ship_date)               AS first_ship_date,
  MAX(ship_date)               AS last_ship_date
FROM swifthaul.shipments;

SELECT column_name, data_type
FROM swifthaul.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'shipments'
ORDER BY ordinal_position;
