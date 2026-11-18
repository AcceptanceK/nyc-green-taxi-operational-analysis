# NYC Green Taxi Demand, Revenue & Operational Performance

**Advanced SQL portfolio project | New York City, USA | January–March 2025**

## Project overview

This project uses **147,155 imported NYC green taxi trip records** and a **265-zone lookup table** to explore route revenue, demand by time of day, geographic concentration, and unusual fare or trip records. The goal is to turn transactional trip data into practical decisions about driver allocation, operating performance, and transaction review.

The dataset is restricted to **green taxis**, not all NYC taxis. Analyses filter pickups to January 1–March 31, 2025, and apply the documented trip-quality conditions. The raw import also contains some April 1 pickup records, which are excluded from the analyses.

## Business questions and project files

| # | Business question | SQL query | CSV results |
|---|---|---|---|
| 01 | Which pickup-to-drop-off routes generate the most recorded revenue? | [View SQL](sql_queries/01_route_revenue_performance.sql) | [View results](results/01_route_revenue_performance.csv) |
| 02 | Which weekday-hour periods show the greatest trip demand and revenue? | [View SQL](sql_queries/02_demand_revenue_trends.sql) | [View results](results/02_demand_revenue_trends.csv) |
| 03 | Which pickup zones dominate demand, and how much occurs during weekday afternoon peaks? | [View SQL](sql_queries/03_high_demand_taxi_zones.sql) | [View results](results/03_high_demand_taxi_zones.csv) |
| 04 | Which recorded trips have unusual durations, speeds, or charges per mile? | [View SQL](sql_queries/04_fare_trip_anomalies.sql) | [View results](results/04_fare_trip_anomalies.csv) |

## Key findings

**1. Route revenue:** East Harlem North → East Harlem South generated approximately **$88,849 from 6,187 trips**, illustrating how frequent, short-distance trips can lead in total revenue. East Harlem North → LaGuardia Airport averaged **$49.57 per trip** from 639 trips, showing a lower-volume, higher-value pattern.

**2. Peak demand:** All 15 top-ranked weekday-hour combinations were between **16:00 and 18:00**; **17:00** appeared nine times. Monthly weekday totals are affected by the number of times each weekday occurs.

**3. Geographic concentration:** East Harlem North and South accounted for **41.4% of qualifying pickup trips**. The share of trips starting during weekday 16:00–18:59 was **28.9% in East Harlem South**, versus **12.5% in East Harlem North**.

**4. Trip anomalies:** Among the 20 highest-amount flagged trips, **13** were categorised as long duration, **6** as high revenue per mile and **1** as high average speed. Unusual records warrant review but are **not evidence of fraud**.

See the [full business findings](business_insights/key_findings.md) and [executive summary](business_insights/executive_summary.md).

## Recommendations

- Investigate driver coverage in high-volume East Harlem pickup zones; assess additional weekday-afternoon capacity in East Harlem South and Central Park.
- Compare trips per actual weekday-hour occurrence, driver supply, passenger wait times and revenue per operating hour before changing shifts.
- Implement daily exception reports for unusual trip durations, speeds and recorded charges; use human review and refine thresholds based on verified outcomes.

## Data and methodology

**Source:** [NYC Taxi & Limousine Commission — Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page). Trip data are joined to the [TLC taxi zone lookup](https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv) using pickup and drop-off location IDs.

**PostgreSQL / DBeaver:** date parsing with `TO_TIMESTAMP`; joins to taxi-zone dimensions; CTEs; conditional aggregates using `FILTER`; `DATE_TRUNC` and `EXTRACT`; `DENSE_RANK`; `SUM() OVER ()`; and `CASE WHEN` for anomaly classification.

**Quality rules:** time-window filtering; positive trip amount and trip distance; valid location-zone matches where needed; and positive duration for trip-speed calculations. Location lookups, thresholds and ranking filters mean that outputs are **not interchangeable with the raw imported row count**.

**Anomaly rules (illustrative only):** average speed >65 mph; duration >120 minutes; recorded amount per mile >$30. The query returns the first matching category in that priority order and shows only the **20 highest-amount flagged trips**.

## Limitations

- The records represent **completed green taxi trips**, not unserved requests, all NYC taxis, or the number of available drivers.
- Recorded trip amounts are **not profit** and can include tips, tolls and surcharges; labour, fuel, idle time and other operating costs are not available.
- Monthly weekday-hour counts are totals across all occurrences of that weekday; they should not be mistaken for per-day averages.
- The anomaly thresholds are exploratory flags. Fare details, rate codes, meter/GPS logs and human review would be required to establish the cause of an unusual record.
- Findings cover three months and should not be treated as year-round demand patterns.

## Repository structure

```text
nyc-green-taxi-operational-analysis/
├── README.md
├── sql_queries/
│   ├── 01_route_revenue_performance.sql
│   ├── 02_demand_revenue_trends.sql
│   ├── 03_high_demand_taxi_zones.sql
│   └── 04_fare_trip_anomalies.sql
├── results/
│   ├── 01_route_revenue_performance.csv
│   ├── 02_demand_revenue_trends.csv
│   ├── 03_high_demand_taxi_zones.csv
│   └── 04_fare_trip_anomalies.csv
└── business_insights/
    ├── executive_summary.md
    └── key_findings.md
```

## How to reproduce

1. Download the relevant green taxi trip CSV and taxi-zone lookup from the official TLC sources, then create and populate the PostgreSQL `taxi_trips` and `taxi_zones` tables.
2. Ensure the column names match the queries, including `trip_id`, `pu_location_id`, `do_location_id`, and `location_id`. The imported pickup/drop-off datetimes were stored as text in `MM/DD/YYYY HH12:MI:SS AM` format.
3. Execute the scripts under [`sql_queries/`](sql_queries/) in order and compare the outputs to [`results/`](results/).

**Note:** Table creation and original raw trip data are not included in the four analysis scripts. An identity-generated `trip_id` was added during import; because these IDs depend on import order, trip IDs may differ if the source records are re-imported.
