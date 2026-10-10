-- SwiftHaul Logistics: Task 5, partition and cluster the fact table

-- 5a. Optimized copy: partitioned by ship_date (daily), clustered by carrier, destination_region
CREATE OR REPLACE TABLE swifthaul.shipments_optimized
PARTITION BY ship_date
CLUSTER BY carrier, destination_region
AS
SELECT *
FROM swifthaul.shipments;

-- 5b. Same filtered query on the NATIVE (unpartitioned) table
-- Dry-run estimate: This query will process 93.22 MB when run.
-- Bytes processed after run: 93.22 MB
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

-- 5c. Same filtered query on the OPTIMIZED table
-- Dry-run estimate: This query will process 3.98 MB when run.
-- Bytes processed after run: 3.98 MB, billed 10MB
SELECT
  shipment_id,
  ship_date,
  carrier,
  destination_region,
  on_time,
  freight_cost_usd
FROM swifthaul.shipments_optimized
WHERE ship_date BETWEEN '2025-03-01' AND '2025-03-31'
  AND carrier = 'OceanLink'
  AND destination_region = 'EU-Central';

-- Why the optimized table processes fewer bytes (93.22 MB -> 3.98 MB, -95.7%):
-- Partition pruning: the table is stored as one partition per ship_date. The
-- WHERE filter on ship_date lets BigQuery read only the 31 March 2025
-- partitions and skip the other ~700 days entirely. March holds 64,006 of the
-- 1,500,000 rows (4.27%), and 93.22 MB x 0.0427 = 3.98 MB, so pruning accounts
-- for the whole saving. The native table has no partitions, so every value of
-- each referenced column is read regardless of the filter.
-- Cluster skipping: inside each partition rows are sorted into storage blocks
-- by carrier, then destination_region, and block metadata records the value
-- range, so blocks that cannot contain carrier = 'OceanLink' or
-- destination_region = 'EU-Central' can be skipped at run time. Here the bytes
-- processed after running equal the dry run (3.98 MB): each daily partition is
-- only ~2,000 rows, small enough to fit in a single block, so there is nothing
-- inside it to skip. Cluster skipping pays off once partitions grow large
-- (hundreds of MB), e.g. with more history or coarser partitions.
