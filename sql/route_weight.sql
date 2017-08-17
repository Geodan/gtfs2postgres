SELECT 
count(trip_id) as trips,
route_id,
agency_id,
route_short_name,
first(ST_Force_2D(geom)) geom
FROM open9292ov.curr_stops
WHERE departure_time::Time < '07:00:00'::Time
AND agency_id = 'NS'
GROUP BY 
agency_id,
route_id,
route_short_name