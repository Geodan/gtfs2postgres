DROP TABLE IF EXISTS open9292ov.curr_stops;
CREATE TABLE open9292ov.curr_stops AS

WITH trips As(
	SELECT a.route_id, agency_id, b.service_id, trip_id, trip_headsign, direction_id, date
	FROM open9292ov.routes a
	LEFT JOIN open9292ov.trips b ON (a.route_id = b.route_id)
	LEFT JOIN open9292ov.calendar_dates c ON (b.service_id = c.service_id)
	WHERE date = '20120809'
	--GROUP BY a.route_id, agency_id, b.service_id, trip_headsign, direction_id, date
)
,
 stops AS (
	SELECT a.trip_id, agency_id, b.stop_id, b.departure_time, b.stop_sequence, c.wkb_geometry
	FROM trips a
	LEFT JOIN open9292ov.stop_times b ON (a.trip_id = b.trip_id)
	LEFT JOIN open9292ov.stops c ON (b.stop_id = c.stop_id)
	WHERE departure_time > current_time - time '00:010'
	AND departure_time < current_time + time '00:10'
	ORDER BY a.trip_id, b.stop_sequence
	
)
--SELECT trip_id, trip_headsign, direction_id, agency_id, date FROM trips
SELECT 
trip_id, 
agency_id, 
current_date + departure_time as departure_time,
--ST_MakeLine(wkb_geometry) geom 
wkb_geometry geom
FROM stops 
GROUP BY trip_id, agency_id
;

SELECT populate_geometry_columns();