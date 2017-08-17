DROP VIEW IF EXISTS open9292ov.curr_pos;
CREATE VIEW open9292ov.curr_pos As

WITH 
dump AS (
	SELECT 
	agency_id, 
	vehicle,
	van trip_van,
	naar trip_naar,
	trip_headsign,
	route_short_name,
	trip_id,
	trip_id::integer + to_char(now(), 'SSSS')::integer as id,
	to_char(now(), 'YYYY-MM-DD HH24:MI:SS') as time,
	current_time as timestamp, 
	(ST_Dump(ST_LocateAlong(geom, to_char(now(), 'SSSS')::integer))).geom geom
	FROM open9292ov.curr_trips
	WHERE ST_M(St_StartPoint(geom)) < ST_M(ST_EndPoint(geom)) -- check correctness of M values
	AND departure_time < now()
	AND arrival_time > now()
	ORDER BY time,trip_id, route_short_name
)
	
SELECT 
	* FROM dump 
WHERE St_GeometryType(geom) = 'ST_Point';


