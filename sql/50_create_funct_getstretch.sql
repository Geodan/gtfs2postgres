
CREATE OR REPLACE FUNCTION osmosis_nl.get_stretch(text, text, text, text)
  RETURNS geometry AS
$$
WITH stretch AS(
	SELECT 
		a.routeid as route_id, 
		a.id as station1_id, b.id as station2_id, 
		a.loc_on_route as loc1, b.loc_on_route as loc2,
		a.vehicle as vehicle,
		a.geom
	FROM osmosis_nl.stations_on_routes  as a
	INNER JOIN osmosis_nl.stations_on_routes  as b ON (a.routeid = b.routeid AND a.routesegment = b.routesegment) --routes waar stations beide voorkomen
	INNER JOIN open9292ov.vehicle_keys as c ON (a.vehicle = c.osm_key) --vertaalsleutel voor transporttypes van 9292 naar osm
	WHERE	(
		( 
			
			$1 LIKE a.stationname || '%' --haltes eindigen nog wel eens met iets anders
			AND $2 LIKE b.stationname || '%'
			AND $3 != 'Trein'
			AND a.line = $4
		)OR(
			$1 = a.stationname	--treinstations zijn 1:1 te vergelijken
			AND $2 = b.stationname
			AND $3 = 'Trein' --dit gaat nog mis bij bijv. ams-centraal <-> ams sloterdijk
		)
		)
		
	AND 	(c.openov_key = $3) --(Tram = tram, subway; Trein = train; Bus = bus; Veerboot = ferry) 
	LIMIT 1
)
,stretch_dump  AS (
	SELECT loc1, loc2, (St_Dump(ST_LocateBetween(St_AddMeasure(geom,0,1), loc1, loc2))).geom geom 
	FROM  stretch
)
SELECT 
CASE 
	WHEN loc1 > loc2 THEN ST_Reverse(geom)
	ELSE geom
END as geom
FROM stretch_dump
WHERE ST_GeometryType(geom) = 'ST_LineString'
LIMIT 1 --might have more than 1 after dump
$$

  LANGUAGE sql IMMUTABLE STRICT
  COST 100;

