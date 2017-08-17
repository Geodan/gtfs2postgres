DROP VIEW IF EXISTS open9292ov.curr_pos_trail;
CREATE VIEW open9292ov.curr_pos_trail As

WITH 
dump AS (
	SELECT 
	agency_id, 
	vehicle,
	trip_headsign,
	route_short_name,
	trip_id,
	trip_id::integer + to_char(now(), 'SSSS')::integer as id,
	to_char(now(), 'YYYY-MM-DD HH24:MI:SS') as time,
	current_time as timestamp, 
	ST_Force_2D((ST_Dump(ST_LocateBetween(geom, 
		to_char(now()-time '00:00:15', 'SSSS')::integer,
		to_char(now()+time '00:00:00', 'SSSS')::integer)
	)).geom)
	as geom
	FROM open9292ov.curr_trips
	WHERE ST_M(St_StartPoint(geom)) < ST_M(ST_EndPoint(geom)) -- check correctness of M values
	AND departure_time < now()
	AND arrival_time > now()
	ORDER BY time,trip_id, route_short_name
)
	
SELECT 
	* FROM dump 
WHERE St_GeometryType(geom) = 'ST_LineString';


