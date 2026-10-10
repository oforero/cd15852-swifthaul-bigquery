-- SwiftHaul Logistics: Task 7, answer the business questions

-- Q1.
SELECT
  carrier,
  SUM(shipments)                                              AS shipments,
  ROUND(SAFE_DIVIDE(SUM(on_time_shipments), SUM(shipments)), 4) AS on_time_rate,
  ROUND(MIN(on_time_rate), 4)                                 AS worst_month_rate,
  ROUND(MAX(on_time_rate), 4)                                 AS best_month_rate
FROM swifthaul.v_carrier_ontime_monthly
GROUP BY carrier
ORDER BY on_time_rate DESC;

-- Q2.
SELECT
  lane,
  shipments,
  ROUND(avg_freight_cost_usd, 2) AS avg_freight_cost_usd
FROM swifthaul.v_lane_cost
ORDER BY avg_freight_cost_usd DESC
LIMIT 5;

-- Q2b.
SELECT
  lane,
  shipments,
  ROUND(avg_freight_cost_usd, 2) AS avg_freight_cost_usd
FROM swifthaul.v_lane_cost
ORDER BY avg_freight_cost_usd ASC
LIMIT 5;

-- Q3.
SELECT
  carrier,
  mode,
  COUNT(*)                                                     AS shipments,
  ROUND(SAFE_DIVIDE(COUNTIF(on_time), COUNT(*)), 4)            AS on_time_rate,
  ROUND(AVG(freight_cost_usd), 2)                              AS avg_cost_per_shipment_usd,
  ROUND(AVG(SAFE_DIVIDE(freight_cost_usd, weight_kg)), 4)      AS avg_cost_per_kg_usd
FROM swifthaul.v_shipments_enriched
GROUP BY carrier, mode
ORDER BY avg_cost_per_kg_usd;
