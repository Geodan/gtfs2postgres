--DROP TABLE IF EXISTS open9292ov.curr_pos;
--CREATE TABLE open9292ov.curr_pos As



WITH 
series As (
	SELECT time
	FROM generate_series(now(),now() + '1 hour', '10 seconds') time
)
,dump AS (
	SELECT 
	agency_id, 
	vehicle,
	trip_headsign,
	route_short_name,
	trip_id,
	trip_id::integer + to_char(time, 'SSSS')::integer as id,
	to_char(time, 'YYYY-MM-DD HH24:MI:SS') as time,
	time as timestamp, 
	(ST_Dump(ST_LocateAlong(geom, to_char(time, 'SSSS')::integer))).geom geom
	FROM open9292ov.curr_stops, series
	WHERE ST_M(St_StartPoint(geom)) > ST_M(ST_EndPoint(geom))
	ORDER BY time,trip_id, route_short_name
)
	
SELECT 
	to_char(timestamp, 'SSSS') as time,
	'['||string_agg(route_short_name,',')||']' as names, 
	'['||string_agg(ST_x(geom)::text,',')||']' lons,
	'['||string_agg(st_y(geom)::text,',')||']' lats,
	'["'||string_agg(vehicle,'","')||'"]' as vehicles
FROM dump 
WHERE St_GeometryType(geom) = 'ST_Point'
GROUP BY to_char(timestamp, 'SSSS')

