/*
Create a list of todays trips during daytime
*/

DROP TABLE IF EXISTS open9292ov.curr_trips;
CREATE TABLE open9292ov.curr_trips AS

WITH trips As(
	SELECT a.route_id, agency_id, a.route_short_name, b.service_id, trip_id, trip_headsign, direction_id, date
	FROM open9292ov.routes a
	LEFT JOIN open9292ov.trips b ON (a.route_id = b.route_id)
	LEFT JOIN open9292ov.calendar_dates c ON (b.service_id = c.service_id)
	WHERE date::Date = now()::Date --Todays services
	--GROUP BY a.route_id, agency_id, b.service_id, trip_headsign, direction_id, date
)
,
 stops AS (
	SELECT a.trip_id, route_short_name, a.trip_headsign, agency_id, b.stop_id, b.departure_time, b.stop_sequence, c.geom
	FROM trips a
	LEFT JOIN open9292ov.stop_times b ON (a.trip_id = b.trip_id)
	LEFT JOIN open9292ov.stops c ON (b.stop_id = c.stop_id)
	WHERE departure_time::Time > current_time - time '10:00'
	AND departure_time::Time < current_time + time '08:00'
	AND left(departure_time,2)::Integer < 24 --throwing out stops after midnight
	ORDER BY a.trip_id, b.stop_sequence
	
	
)
--SELECT trip_id, trip_headsign, direction_id, agency_id, date FROM trips
SELECT 
trip_id, 
agency_id, 
trip_headsign,
route_short_name,
ST_MakeLine(geom) geom 
FROM stops 
GROUP BY trip_id, agency_id, route_short_name, trip_headsign
;

--SELECT populate_geometry_columns();