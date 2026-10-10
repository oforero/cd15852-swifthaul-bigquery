# Task 6: Data Governance Controls for the SwiftHaul Shipments Data

This note describes how BigQuery protects the `swifthaul` dataset (native table `shipments`, optimized table `shipments_optimized`, external table `carrier_rates_ext`, and the reporting views) and which access controls SwiftHaul should apply.

## 1. Encryption

### At rest

BigQuery encrypts all stored data by default, with no configuration needed. That includes the `shipments` tables, the materialized view `mv_daily_volume`, and the temporary results of each query.

- **Default: Google-managed keys.** Data is encrypted with AES-256 using envelope encryption. Each chunk of data has its own data encryption key (DEK), and the DEKs are themselves encrypted by key encryption keys (KEKs) held in Google's key management service. This is on for every table and costs nothing extra.
- **Option: customer-managed encryption keys (CMEK).** If SwiftHaul's compliance rules require control over the keys, the dataset or individual tables can use a key in Cloud KMS that SwiftHaul owns. SwiftHaul then controls key rotation and can disable or revoke the key, which makes the data unreadable even to BigQuery. Cloud Audit Logs record every key use.
- **Source files in Cloud Storage.** `shipments.csv` and `carrier_rates.csv` in the bucket `swifthaul-oforero-2026` are also encrypted at rest by default. The external table reads them in place, so they are protected by the bucket's encryption and IAM, not BigQuery's.

### In transit

- Traffic between clients (the console, `bq` CLI, client libraries, BI tools) and BigQuery uses **TLS** over HTTPS.
- Traffic inside Google's network, for example between BigQuery and Cloud Storage when the load job or the external table reads the CSV files, is authenticated and encrypted between Google services and data centers (Google's ALTS).

## 2. IAM access control at each level

BigQuery permissions come from IAM roles. A role granted at a higher level is inherited by everything below it, so the rule is to grant at the **lowest level that does the job** (least privilege).

| Level | What a grant there controls | Example roles |
|---|---|---|
| **Project** | Running query jobs (and spending the query budget), creating datasets. A data role here applies to **every** dataset in the project, so data roles should rarely be granted at this level. | `roles/bigquery.jobUser`, `roles/bigquery.user`, `roles/bigquery.admin` |
| **Dataset** | Read or write access to all tables and views inside one dataset, e.g. `swifthaul`. | `roles/bigquery.dataViewer`, `roles/bigquery.dataEditor`, `roles/bigquery.dataOwner` |
| **Table / view** | Access to a single table or view only, without access to the rest of the dataset. | `roles/bigquery.dataViewer` on `v_lane_cost` only |
| **Authorized view** | The view itself is granted read access to the source dataset. Users granted access to the view can query it **without** access to the base table, so they see only the columns and rows the view exposes. | View added to the source dataset's authorized resources |

Querying needs two things. **Data access** comes from a dataset, table or view role. **Permission to run a job** comes from a project role (`bigquery.jobUser`). An analyst needs both.

Finer-grained controls are available inside a table:

- **Column-level security** with **policy tags** (Data Catalog taxonomy). Only principals with `Fine-Grained Reader` on the tag can read a tagged column. Others get an error or, with **dynamic data masking**, a masked value.
- **Row-level security** with **row access policies**, e.g. a regional team only sees rows where `origin_region` is their region.

## 3. Controls I would use for the shipments dataset

### Classifying the data

- `customer_id` identifies SwiftHaul's customers. It is pseudonymous, but it links shipments to customer accounts, so it is the most sensitive column.
- `freight_cost_usd` and the `carrier_rates_ext` rate card are commercially sensitive. They reveal negotiated carrier pricing and margins.
- Operational fields (dates, regions, carrier, `on_time`, `status`) are internal but low risk.

### Who gets what access

| Who | Access | Level |
|---|---|---|
| **Data engineering** (2 to 3 people who load and maintain the warehouse) | `bigquery.dataEditor` on `swifthaul`, `bigquery.jobUser` on the project, `storage.objectViewer` on the bucket for loads | Dataset + project + bucket |
| **Warehouse owner** (data platform lead) | `bigquery.dataOwner` on `swifthaul` to manage sharing; nobody else gets owner or admin | Dataset |
| **Operations analysts** | `bigquery.dataViewer` on the reporting views only (`v_carrier_ontime_monthly`, `v_lane_cost`, `mv_daily_volume`) as authorized views, plus `bigquery.jobUser` | View + project |
| **Dashboard service account** (BI tool) | `bigquery.dataViewer` on `mv_daily_volume` and the reporting views only, plus `bigquery.jobUser` | View + project |
| **Finance** | Same as operations analysts, plus `Fine-Grained Reader` on the `cost` policy tag covering `freight_cost_usd` | View + column |
| **Everyone else** | No access. Nobody is granted data roles at project level, and `allUsers` / `allAuthenticatedUsers` are never used | |

### Supporting controls

- **Grant to Google groups, not individuals** (e.g. `group:ops-analysts@...`), so joiners and leavers are handled in one place.
- **Move the reporting views into a separate dataset** (e.g. `swifthaul_reporting`) and authorize them on `swifthaul`. Analysts then get access to the reporting dataset only and never see the raw `shipments` table or `customer_id`.
- **Policy tag on `customer_id`** with dynamic data masking for everyone except data engineering.
- **Cloud Storage bucket:** uniform bucket-level access and public access prevention enabled (set when the bucket was created). Only data engineering can read the raw CSV files.
- **Encryption:** Google-managed keys are sufficient for this data. Switch to CMEK if SwiftHaul's contracts or regulators require customer key control.
- **Audit:** Cloud Audit Logs (Data Access logs) record who queried which table. Review them periodically, together with the IAM grants.

### Example grants (illustrative, not executed in the sandbox)

BigQuery also supports these grants as SQL (DCL):

```sql
-- Engineers maintain the dataset
GRANT `roles/bigquery.dataEditor`
ON SCHEMA swifthaul
TO "group:data-engineering@swifthaul.example";

-- Analysts read one reporting view only
GRANT `roles/bigquery.dataViewer`
ON VIEW swifthaul.v_lane_cost
TO "group:ops-analysts@swifthaul.example";
```
