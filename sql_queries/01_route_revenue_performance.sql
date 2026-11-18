WITH parsed_trips AS (
    SELECT
        trip_id,
        pu_location_id,
        do_location_id,
        trip_distance,
        total_amount,
        TO_TIMESTAMP(lpep_pickup_datetime, 'MM/DD/YYYY HH12:MI:SS AM')::timestamp AS pickup_ts
    FROM taxi_trips
),
route_metrics AS (
    SELECT
        t.pu_location_id,
        t.do_location_id,
        pz.borough                AS pickup_borough,
        pz.zone                   AS pickup_zone,
        dz.borough                AS dropoff_borough,
        dz.zone                   AS dropoff_zone,
        COUNT(t.trip_id)          AS total_trips,
        SUM(t.total_amount)       AS revenue,
        AVG(t.total_amount)       AS avg_revenue,
        AVG(t.trip_distance)      AS avg_distance
    FROM parsed_trips t
    JOIN taxi_zones pz
        ON pz.location_id = t.pu_location_id
    JOIN taxi_zones dz
        ON dz.location_id = t.do_location_id
    WHERE t.pickup_ts >= TIMESTAMP '2025-01-01 00:00:00'
      AND t.pickup_ts <  TIMESTAMP '2025-04-01 00:00:00'
      AND t.total_amount  > 0
      AND t.trip_distance > 0
    GROUP BY
        t.pu_location_id, t.do_location_id,
        pz.borough, pz.zone,
        dz.borough, dz.zone
)
SELECT
    pickup_borough,
    pickup_zone,
    dropoff_borough,
    dropoff_zone,
    total_trips,
    ROUND(revenue::numeric, 2)       AS total_revenue,
    ROUND(avg_revenue::numeric, 2)   AS avg_revenue_per_trip,
    ROUND(avg_distance::numeric, 2)  AS avg_trip_distance,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM route_metrics
ORDER BY revenue_rank, pickup_zone, dropoff_zone
LIMIT 15;