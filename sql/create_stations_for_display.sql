/**
	Create a nicer table for displaying stations on the map

**/

DROP TABLE IF EXISTS osmosis_nl.stations_for_display;
CREATE TABLE osmosis_nl.stations_for_display AS

WITH sub AS (

SELECT stationname, vehicle, stop_geom, line FROM osmosis_nl.stations_on_routes
GROUP BY stationname, vehicle, stop_geom, line
)

SELECT stationname, vehicle, stop_geom, ST_Transform(stop_geom, 28992) geom_28992,  array_agg(line) FROM sub
GROUP BY stationname, vehicle, stop_geom;