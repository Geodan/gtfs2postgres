/**
Create a table with all possible stretches on 1 day
This will reduce time in later getting the geom for every stretch when creating the trip list

Run time for complete set approx: 
**/


--DELETE FROM open9292ov.stretchtable WHERE vehicle = 'Bus';
INSERT INTO open9292ov.stretchtable 

WITH /** Create a subset of trips for today **/

trips As(
SELECT 
	a.route_id, route_short_name,agency_id, 
	b.service_id, 
	b.trip_id, 
	trip_headsign, direction_id
	, date
	,d.name as vehicle
	FROM open9292ov.routes a
	INNER JOIN open9292ov.trips b ON (a.route_id = b.route_id)
	INNER JOIN open9292ov.calendar_dates c ON (b.service_id = c.service_id)
	INNER JOIN open9292ov.route_types d ON (a.route_type = d.route_type)
	WHERE date = '20120821'
	AND (
		d.name = 'Tram' 
		--d.name = 'Trein'
		--d.name = 'Bus' --
		--d.name = 'Veerboot'
	)
	
	--GROUP BY a.route_id, route_short_name,agency_id, trip_headsign, direction_id,d.name 
)
,stops AS (
	SELECT 
	DISTINCT
	route_short_name
	,vehicle
	,f.name_simple stop1
	,lead(f.name_simple) OVER  (PARTITION BY a.trip_id ORDER BY a.trip_id, e.stop_sequence) stop2
	FROM trips a
	INNER JOIN open9292ov.stop_times e ON (a.trip_id = e.trip_id)
	INNER JOIN open9292ov.stops f ON (e.stop_id = f.stop_id)
	--WHERE
	--departure_time > current_time - time '00:10:00'  --CHANGE timeframe to collect trips
	--AND departure_time < current_time + time '01:30:00'
)


SELECT 

stop1, stop2, vehicle, route_short_name as line
,osmosis_nl.get_stretch(stop1, stop2, vehicle, route_short_name) as geom
FROM stops
WHERE osmosis_nl.get_stretch(stop1, stop2, vehicle, route_short_name) Is Not null
--LIMIT 100
;