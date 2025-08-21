-- 1) Build zone-by-hour tip rates
CREATE OR REPLACE TABLE `splendid-world-462802-e0.my_taxi_data.zone_hour_tip_rate` AS
SELECT
  pickup_zone,
  EXTRACT(HOUR FROM tpep_pickup_datetime) AS hour,
  -- Use SAFE_DIVIDE for robustness; WHERE still guards zeros
  AVG(SAFE_DIVIDE(tip_amount, fare_amount)) AS avg_tip_rate,
  -- Optional: a weighted version that treats each hour by total $ volume
  SAFE_DIVIDE(SUM(tip_amount), NULLIF(SUM(fare_amount), 0)) AS weighted_tip_rate
FROM `splendid-world-462802-e0.my_taxi_data.trips_with_zone`
WHERE fare_amount > 0
GROUP BY pickup_zone, hour;

-- 2) Top 10 pickup zones with the highest overall tip rate (across all hours)
--    (Uses the simple average of hourly rates; consider 'weighted_tip_rate' if preferred)
SELECT
  pickup_zone,
  AVG(avg_tip_rate) AS overall_tip_rate,
  AVG(weighted_tip_rate) AS overall_weighted_tip_rate,
  COUNT(*) AS hour_count
FROM `splendid-world-462802-e0.my_taxi_data.zone_hour_tip_rate`
GROUP BY pickup_zone
HAVING hour_count > 5  -- keep zones with sufficient hourly coverage
ORDER BY overall_tip_rate DESC
LIMIT 10;

-- 3) Citywide average tip rate by hour
SELECT
  hour,
  AVG(avg_tip_rate) AS tip_rate_by_hour,
  AVG(weighted_tip_rate) AS weighted_tip_rate_by_hour
FROM `splendid-world-462802-e0.my_taxi_data.zone_hour_tip_rate`
GROUP BY hour
ORDER BY tip_rate_by_hour DESC;

-- 4) Zones with the strongest hour-to-hour tip variability
SELECT
  pickup_zone,
  MAX(avg_tip_rate) - MIN(avg_tip_rate) AS tip_variation,
  COUNT(*) AS hour_count
FROM `splendid-world-462802-e0.my_taxi_data.zone_hour_tip_rate`
GROUP BY pickup_zone
HAVING hour_count > 5
ORDER BY tip_variation DESC
LIMIT 50;

-- 5) Trip-distance distribution (deciles)
SELECT
  APPROX_QUANTILES(trip_distance, 10) AS distance_percentiles
FROM `splendid-world-462802-e0.my_taxi_data.trips_with_zone`
WHERE trip_distance > 0;

-- 6) Tip rate by trip-distance group (bins capped at 20 miles to remove outliers)
SELECT
  CASE
    WHEN trip_distance <= 1 THEN 'Short'
    WHEN trip_distance <= 2.75 THEN 'Medium'
    WHEN trip_distance <= 7 THEN 'Long'
    ELSE 'Very Long'
  END AS distance_group,
  COUNT(*) AS trip_count,
  AVG(SAFE_DIVIDE(tip_amount, fare_amount)) AS avg_tip_rate,
  SAFE_DIVIDE(SUM(tip_amount), NULLIF(SUM(fare_amount), 0)) AS weighted_tip_rate
FROM `splendid-world-462802-e0.my_taxi_data.trips_with_zone`
WHERE fare_amount > 0
  AND trip_distance > 0
  AND trip_distance <= 20  -- basic outlier filter
GROUP BY distance_group
ORDER BY avg_tip_rate DESC;
