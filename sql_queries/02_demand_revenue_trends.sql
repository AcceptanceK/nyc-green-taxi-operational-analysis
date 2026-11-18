WITH parsed_trips AS (
    SELECT
        trip_id,
        total_amount,
        TO_TIMESTAMP(lpep_pickup_datetime, 'MM/DD/YYYY HH12:MI:SS AM')::timestamp AS pickup_ts
    FROM taxi_trips
    WHERE total_amount  > 0
      AND trip_distance > 0
),
trip_parts AS (
    SELECT
        trip_id,
        total_amount,
        DATE_TRUNC('month', pickup_ts)::date  AS trip_month,
        TO_CHAR(pickup_ts, 'FMDay')           AS day_of_week,
        EXTRACT(ISODOW FROM pickup_ts)::int   AS weekday_num,
        EXTRACT(HOUR FROM pickup_ts)::int     AS pickup_hour
    FROM parsed_trips
    WHERE pickup_ts >= TIMESTAMP '2025-01-01 00:00:00'
      AND pickup_ts <  TIMESTAMP '2025-04-01 00:00:00'
),
demand AS (
    SELECT
        trip_month,
        day_of_week,
        weekday_num,
        pickup_hour,
        COUNT(trip_id)     AS total_trips,
        SUM(total_amount)  AS revenue,
        AVG(total_amount)  AS avg_revenue
    FROM trip_parts
    GROUP BY trip_month, day_of_week, weekday_num, pickup_hour
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY trip_month
            ORDER BY total_trips DESC
        ) AS demand_rank
    FROM demand
)
SELECT
    trip_month,
    day_of_week,
    pickup_hour,
    total_trips,
    ROUND(revenue::numeric, 2)      AS total_revenue,
    ROUND(avg_revenue::numeric, 2)  AS avg_revenue_per_trip,
    demand_rank
FROM ranked
WHERE demand_rank <= 5
ORDER BY trip_month, demand_rank, weekday_num, pickup_hour;