/** 
Makes lines out of trips and gives an M value to every stop. 
M is seconds from midnight.
Every trip has a start and end time.

Takes 120 seconds for only trains
**/
DELETE FROM  open9292ov.curr_trips;
INSERT INTO open9292ov.curr_trips
--DROP TABLE IF EXISTS open9292ov.curr_trips;
--CREATE TABLE open9292ov.trips As

WITH /** Create a subset of trips for today **/
trips As(
	SELECT a.route_id, d.name as vehicle, route_short_name,agency_id, b.service_id, trip_id, trip_headsign, direction_id, date
	FROM open9292ov.routes a
	LEFT JOIN open9292ov.trips b ON (a.route_id = b.route_id)
	LEFT JOIN open9292ov.calendar_dates c ON (b.service_id = c.service_id)
	LEFT JOIN open9292ov.route_types d ON (a.route_type = d.route_type)
	
	WHERE date = '20120822'
	AND ( 1=2
		--OR d.name = 'Tram'
		OR d.name = 'Trein'
		--OR (d.name = 'Bus' AND agency_id='CONNEXXION')
		--OR d.name = 'Veerboot'
		)
	
	
	--AND trip_id = 77338773
	--GROUP BY a.route_id, agency_id, b.service_id, trip_headsign, direction_id, date
)
, stops AS ( /**Create a subset of stops from the trips (within a timeframe) **/
	SELECT 
	a.trip_id, 
	vehicle,
	trip_headsign,
	route_id,
	route_short_name,
	agency_id, 
	b.stop_id,
	b.departure_time, 
	--b.arrival_time, 
	b.stop_sequence,
	c.wkb_geometry as geom_start,
	c.name_simple stop1,
	lead(c.name_simple) OVER  (PARTITION BY a.trip_id ORDER BY a.trip_id, b.stop_sequence) stop2,
	lead(c.wkb_geometry) OVER  (PARTITION BY a.trip_id ORDER BY a.trip_id, b.stop_sequence) geom_arrive,
	lead(b.arrival_time) OVER  (PARTITION BY a.trip_id ORDER BY a.trip_id, b.stop_sequence) arrival_time
	FROM trips a
	INNER JOIN open9292ov.stop_times b ON (a.trip_id = b.trip_id)
	INNER JOIN open9292ov.stops c ON (b.stop_id = c.stop_id)
	--WHERE departure_time > current_time - time '00:10:00'  --CHANGE timeframe to collect trips
	--AND departure_time < current_time + time '01:30:00'
	ORDER BY a.trip_id, b.stop_sequence
)
, travel As ( /** Create the trip-lines, including M data  based on time**/
SELECT 
	trip_id, 
	s.vehicle,
	agency_id, 
	trip_headsign,
	route_short_name,
	min(current_date + departure_time) as departure_time,
	max(current_date + arrival_time) as arrival_time,
	ST_AddMeasure(
		/** When we can find a stretch from openstreetmap, use it 
			otherwhise make a straight line between A and B **/
		CASE WHEN x.geom Is Not Null
			THEN x.geom
		ELSE 
			ST_MakeLine(geom_start,geom_arrive)
		END,
		to_char(current_date + departure_time, 'SSSS')::integer,
		to_char(current_date + arrival_time, 'SSSS')::integer
		)
	
	
	as geom,
	s.stop1, s.stop2
FROM stops s
LEFT JOIN open9292ov.stretchtable x ON (s.stop1 = x.stop1 AND s.stop2 = x.stop2 AND s.vehicle = x.vehicle AND (s.route_short_name = x.line OR s.vehicle = 'Trein'))
GROUP BY 
	trip_id, 
	s.vehicle,
	agency_id, 
	trip_headsign,
	route_short_name,
	departure_time,
	arrival_time,
	s.stop1, s.stop2,
	geom_start,geom_arrive,x.geom
)

SELECT *
FROM travel

;
--SELECT populate_geometry_columns();

/*
CREATE INDEX curr_trips_arrival_time_idx
  ON open9292ov.curr_trips
  USING btree
  (arrival_time );

CREATE INDEX curr_trips_departure_time_idx
  ON open9292ov.curr_trips
  USING btree
  (departure_time );
  
CREATE INDEX curr_trips_geom_idx
  ON open9292ov.curr_trips
  USING gist
  (geom );
*/

--SELECT populate_geometry_columns();

