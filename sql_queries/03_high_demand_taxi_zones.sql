WITH parsed_trips AS (
    SELECT
        trip_id,
        pu_location_id,
        total_amount,
        TO_TIMESTAMP(lpep_pickup_datetime, 'MM/DD/YYYY HH12:MI:SS AM')::timestamp AS pickup_ts
    FROM taxi_trips
    WHERE total_amount  > 0
      AND trip_distance > 0
),
qualifying_trips AS (
    SELECT
        t.trip_id,
        t.total_amount,
        t.pickup_ts,
        z.borough,
        z.zone,
        t.pu_location_id
    FROM parsed_trips t
    JOIN taxi_zones z
        ON z.location_id = t.pu_location_id
    WHERE t.pickup_ts >= TIMESTAMP '2025-01-01 00:00:00'
      AND t.pickup_ts <  TIMESTAMP '2025-04-01 00:00:00'
),
zone_metrics AS (
    SELECT
        pu_location_id,
        borough,
        zone,
        COUNT(trip_id)                                                    AS total_trips,
        SUM(total_amount)                                                 AS revenue,
        AVG(total_amount)                                                 AS avg_revenue,
        COUNT(trip_id) FILTER (
            WHERE EXTRACT(ISODOW FROM pickup_ts) BETWEEN 1 AND 5
              AND EXTRACT(HOUR   FROM pickup_ts) BETWEEN 16 AND 18
        )                                                                 AS peak_hour_trips
    FROM qualifying_trips
    GROUP BY pu_location_id, borough, zone
),
with_network AS (
    SELECT
        *,
        SUM(total_trips) OVER () AS network_trips
    FROM zone_metrics
)
SELECT
    borough                                                      AS pickup_borough,
    zone                                                         AS pickup_zone,
    total_trips,
    ROUND(revenue::numeric, 2)                                   AS total_revenue,
    ROUND(avg_revenue::numeric, 2)                               AS avg_revenue_per_trip,
    peak_hour_trips,
    ROUND(100.0 * peak_hour_trips / NULLIF(total_trips, 0), 1)   AS peak_hour_share_pct,
    ROUND(100.0 * total_trips / NULLIF(network_trips, 0), 1)     AS network_trip_share_pct,
    DENSE_RANK() OVER (ORDER BY total_trips DESC)                AS demand_rank
FROM with_network
ORDER BY demand_rank, pickup_zone
LIMIT 15;