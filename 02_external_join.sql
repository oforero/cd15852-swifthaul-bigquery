-- SwiftHaul Logistics: Task 2, external table over carrier_rates.csv and join to shipments

-- 2a
CREATE OR REPLACE EXTERNAL TABLE swifthaul.carrier_rates_ext (
  carrier              STRING,
  mode                 STRING,
  base_rate_per_kg_usd NUMERIC,
  fuel_surcharge_pct   NUMERIC,
  min_charge_usd       NUMERIC,
  effective_date       DATE
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://swifthaul-oforero-2026/carrier_rates.csv'],
  skip_leading_rows = 1
);

-- 2b
SELECT COUNT(*) AS unmatched_shipments
FROM swifthaul.shipments AS s
LEFT JOIN swifthaul.carrier_rates_ext AS r
  ON s.carrier = r.carrier
WHERE r.carrier IS NULL;

-- 2c.
CREATE OR REPLACE VIEW swifthaul.v_shipments_enriched AS
SELECT
  s.*,
  r.mode,
  r.base_rate_per_kg_usd,
  r.fuel_surcharge_pct,
  r.min_charge_usd
FROM swifthaul.shipments AS s
LEFT JOIN swifthaul.carrier_rates_ext AS r
  ON s.carrier = r.carrier;

-- 2d
SELECT shipment_id, carrier, mode, base_rate_per_kg_usd, weight_kg, freight_cost_usd
FROM swifthaul.v_shipments_enriched
LIMIT 10;
