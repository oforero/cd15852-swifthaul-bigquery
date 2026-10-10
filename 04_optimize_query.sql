-- SwiftHaul Logistics Task 4,
--
-- 4a. BEFORE (wasteful): every column, no filter.
-- Dry-run estimate: This query will process 200.47 MB when run.
SELECT *
FROM swifthaul.shipments;

-- 4b. AFTER (optimized): only the columns the question needs, plus a WHERE filter.
-- Question: on-time performance and cost for OceanLink shipments to EU-Central in March 2025.
-- Dry-run estimate: This query will process 93.22 MB when run.
-- BigQuery is columnar and bills by bytes in the columns read, so dropping from
-- 14 to 6 columns is what cuts the bytes here. On this unpartitioned table the
-- WHERE filter reduces rows returned but not bytes scanned; Task 5 fixes that.
SELECT
  shipment_id,
  ship_date,
  carrier,
  destination_region,
  on_time,
  freight_cost_usd
FROM swifthaul.shipments
WHERE ship_date BETWEEN '2025-03-01' AND '2025-03-31'
  AND carrier = 'OceanLink'
  AND destination_region = 'EU-Central';
