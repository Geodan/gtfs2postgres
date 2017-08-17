/** 
Makes lines out of trips and gives an M value to every stop. 
M is seconds from midnight.
Every trip has a start and end time.
**/
--DELETE FROM open9292ov.curr_stops;
--INSERT INTO open9292ov.curr_stops
DROP TABLE open9292ov.curr_stops;
CREATE TABLE open9292ov.curr_stops AS
WITH 
trips As(
	SELECT a.route_id, route_short_name,agency_id, b.service_id, trip_id, trip_headsign, direction_id, date
	FROM open9292ov.routes a
	LEFT JOIN open9292ov.trips b ON (a.route_id = b.route_id)
	LEFT JOIN open9292ov.calendar_dates c ON (b.service_id = c.service_id)
	--LEFT JOIN open9292ov.route_types d ON (a.route_type = d.route_type)
	WHERE date::Date = now()::Date --Todays service
	AND agency_id = 'NS'
	--GROUP BY a.route_id, agency_id, b.service_id, trip_headsign, direction_id, date
)
,stop_times AS (
	SELECT * FROM open9292ov.stop_times WHERE left(departure_time,2)::Integer < 24 --throw out hours after midnight, postgres vomits otherwhise
)
,
 stops AS (
	SELECT 
	a.trip_id, 
	trip_headsign,
	route_id,
	route_short_name,
	agency_id, 
	b.stop_id, 
	b.departure_time, 
	b.arrival_time, 
	b.stop_sequence,
	c.geom as geom_start
	--lag(c.wkb_geometry) OVER  (PARTITION BY a.trip_id ORDER BY a.trip_id, b.stop_sequence) geom_arrive,
	--lag(b.arrival_time) OVER  (PARTITION BY a.trip_id ORDER BY a.trip_id, b.stop_sequence) arrival_time
	FROM trips a
	LEFT JOIN stop_times b ON (a.trip_id = b.trip_id)
	LEFT JOIN open9292ov.stops c ON (b.stop_id = c.stop_id)
	WHERE departure_time::Time > '05:00:00'::Time -- current_time - time '10:00' -- sample set van een uurt
	AND departure_time::Time < '23:00:00'::Time --current_time + time '08:00'
	ORDER BY a.trip_id, b.stop_sequence
	
)
, travel As (
SELECT 
	route_id,
	trip_id,
	agency_id, 
	trip_headsign,
	route_short_name,
	min(current_date + departure_time::Time) as departure_time,
	max(current_date + arrival_time::Time) as arrival_time,
	ST_MakeLine(
		ST_SetSrid(
			ST_MakePointM(
				St_X(geom_start),
				St_Y(geom_start),
				to_char(departure_time::Time, 'SSSS')::integer
			)
			,4326
		)
	)as geom
FROM stops 
GROUP BY 
	route_id,
	trip_id, 
	agency_id, 
	trip_headsign,
	route_short_name
)

SELECT *
FROM travel
;

--SELECT populate_geometry_columns();