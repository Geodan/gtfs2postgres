DROP TABLE IF EXISTS gtfs.cur_tripsegments;
CREATE TABLE gtfs.cur_tripsegments AS

WITH stops AS (
SELECT 
	r.route_long_name, c.date::Date date, t.trip_id, t.trip_headsign, t.direction_id 
	,r.agency_id
	,CASE --In case of larger stations, we only want station id and not platform
		WHEN s.parent_station = '' THEN s.stop_id
		ELSE s.parent_station
	END stop_id
	,date_trunc('hour',st.departure_time) as hour
	,st.stop_sequence
	,ST_SetSrid(ST_MakePoint(s.stop_lon, s.stop_lat),4326) geom
FROM gtfs.routes r
INNER JOIN gtfs.trips t ON (r.route_id = t.route_id)
INNER JOIN gtfs.calendar_dates c ON (t.service_id = c.service_id AND date::Date = now()::Date) --Todays service)
INNER JOIN gtfs.stop_times st ON (t.trip_id = st.trip_id AND date_part('hours',st.departure_time)::Integer < 24)
INNER JOIN gtfs.stops s ON (st.stop_id = s.stop_id)
--WHERE r.agency_id = 'NS' OR r.agency_id = 'ARRIVA'
--GROUP BY 	r.route_long_name, c.date, t.trip_id, t.trip_headsign, t.direction_id 
ORDER BY st.trip_id, st.stop_sequence 
)

,segments AS (
	SELECT stop_id stopid_a, 
		lead(stop_id) OVER (PARTITION BY trip_id ORDER BY trip_id, stop_sequence) stopid_b
		, ST_MakeLine(
			geom, 
			lead(geom) OVER (PARTITION BY trip_id ORDER BY trip_id, stop_sequence)
		) geom
		,hour
		,agency_id
	FROM stops
),
hours AS (
SELECT stopid_a || stopid_b id, stopid_a, stopid_b, geom, agency_id
,'[' || array_to_string(ARRAY[
	 SUM(CASE WHEN hour = '00:00:00' THEN 1 ELSE 0 END) 
	,SUM(CASE WHEN hour = '01:00:00' THEN 1 ELSE 0 END) 
	,SUM(CASE WHEN hour = '02:00:00' THEN 1 ELSE 0 END) 
	,SUM(CASE WHEN hour = '03:00:00' THEN 1 ELSE 0 END) 
	,SUM(CASE WHEN hour = '04:00:00' THEN 1 ELSE 0 END) 
	,SUM(CASE WHEN hour = '05:00:00' THEN 1 ELSE 0 END) 
	,SUM(CASE WHEN hour = '06:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '07:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '08:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '09:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '10:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '11:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '12:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '13:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '14:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '15:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '16:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '17:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '18:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '19:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '20:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '21:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '22:00:00' THEN 1 ELSE 0 END)
	,SUM(CASE WHEN hour = '23:00:00' THEN 1 ELSE 0 END)
	
],',') || ']' AS hours
FROM segments
WHERE stopid_b Is Not Null
GROUP BY stopid_a, stopid_b, geom, agency_id
)

SELECT first(id) id, ST_Union(geom) geom, agency_id, hours
FROM hours
GROUP BY agency_id, hours