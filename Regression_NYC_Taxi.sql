-- Export cleaned subset to CSV for modeling
SELECT
  trip_distance,
  EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
  payment_type,
  fare_amount,
  tip_amount,
  tolls_amount,
  total_amount
FROM `splendid-world-462802-e0.my_taxi_data.trips_with_zone`
WHERE fare_amount > 0 AND trip_distance > 0
LIMIT 50000;