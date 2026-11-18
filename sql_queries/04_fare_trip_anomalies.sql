WITH parsed_trips AS (
    SELECT
        trip_id,
        TO_TIMESTAMP(lpep_pickup_datetime,  'MM/DD/YYYY HH12:MI:SS AM')::timestamp AS pickup_datetime,
        TO_TIMESTAMP(lpep_dropoff_datetime, 'MM/DD/YYYY HH12:MI:SS AM')::timestamp AS dropoff_datetime,
        trip_distance,
        total_amount
    FROM taxi_trips
),
trip_metrics AS (
    SELECT
        trip_id,
        pickup_datetime,
        dropoff_datetime,
        trip_distance,
        total_amount,
        EXTRACT(EPOCH FROM (dropoff_datetime - pickup_datetime)) / 60.0 AS duration_minutes
    FROM parsed_trips
    WHERE pickup_datetime >= TIMESTAMP '2025-01-01 00:00:00'
      AND pickup_datetime <  TIMESTAMP '2025-04-01 00:00:00'
      AND trip_distance > 0
      AND total_amount  > 0
      AND dropoff_datetime > pickup_datetime
),
with_rates AS (
    SELECT
        *,
        trip_distance::numeric / (duration_minutes::numeric / 60.0) AS avg_speed_mph,
        total_amount::numeric  / trip_distance::numeric             AS revenue_per_mile
    FROM trip_metrics
),
flagged AS (
    SELECT
        *,
        CASE
            WHEN avg_speed_mph    > 65  THEN 'High average speed'
            WHEN duration_minutes > 120 THEN 'Long duration'
            WHEN revenue_per_mile > 30  THEN 'High revenue per mile'
        END AS anomaly_category
    FROM with_rates
)
SELECT
    trip_id,
    pickup_datetime,
    dropoff_datetime,
    trip_distance,
    total_amount,
    ROUND(duration_minutes::numeric, 1)  AS duration_minutes,
    ROUND(avg_speed_mph, 1)              AS avg_speed_mph,
    ROUND(revenue_per_mile, 2)           AS revenue_per_mile,
    anomaly_category,
    DENSE_RANK() OVER (ORDER BY total_amount DESC) AS anomaly_rank
FROM flagged
WHERE anomaly_category IS NOT NULL
ORDER BY anomaly_rank, trip_id
LIMIT 20;