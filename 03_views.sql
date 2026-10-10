-- SwiftHaul Logistics: Task 3, model the data with views and a materialized view

-- 3a.
CREATE OR REPLACE VIEW swifthaul.v_carrier_ontime_monthly AS
SELECT
  carrier,
  DATE_TRUNC(ship_date, MONTH)                     AS ship_month,
  COUNT(*)                                         AS shipments,
  COUNTIF(on_time)                                 AS on_time_shipments,
  SAFE_DIVIDE(COUNTIF(on_time), COUNT(*))          AS on_time_rate
FROM swifthaul.shipments
GROUP BY carrier, ship_month;

-- 3b. Cost per lane
CREATE OR REPLACE VIEW swifthaul.v_lane_cost AS
SELECT
  origin_region,
  destination_region,
  CONCAT(origin_region, ' -> ', destination_region) AS lane,
  COUNT(*)                                          AS shipments,
  AVG(freight_cost_usd)                             AS avg_freight_cost_usd
FROM swifthaul.shipments
GROUP BY origin_region, destination_region;

-- 3c. Materialized view: daily shipment volume.
-- Why it is worth the storage: dashboards query daily volume many times a day.
-- A normal view would re-scan all 1.5M shipment rows on every refresh; the
-- materialized view stores one row per day (~730 rows), so each
-- dashboard query reads kilobytes instead of a full-table aggregation.
-- BigQuery refreshes it incrementally when new shipments load, so it stays
-- current, and the extra storage for ~730 small rows is negligible.
CREATE MATERIALIZED VIEW IF NOT EXISTS swifthaul.mv_daily_volume AS
SELECT
  ship_date,
  COUNT(*)              AS shipments,
  COUNTIF(on_time)      AS on_time_shipments,
  SUM(freight_cost_usd) AS total_freight_cost_usd
FROM swifthaul.shipments
GROUP BY ship_date;

-- 3d. Checks
SELECT * FROM swifthaul.v_carrier_ontime_monthly ORDER BY carrier, ship_month LIMIT 12;
SELECT * FROM swifthaul.v_lane_cost ORDER BY avg_freight_cost_usd DESC LIMIT 10;
SELECT * FROM swifthaul.mv_daily_volume ORDER BY ship_date LIMIT 10;
