/**
Match stations and stops to all routes that fall within xx distance of the route
Runs surprisingly fast! (+- 1 min.)
**/

DROP TABLE IF EXISTS osmosis_nl.stations_on_routes;
CREATE TABLE osmosis_nl.stations_on_routes As

SELECT a.id, upper(a.tags -> 'name') stationname, b.routeid, b.routename,b.vehicle,b.line, 
ST_Line_Locate_Point(b.geom, a.geom) loc_on_route, routesegment, a.geom as stop_geom, b.geom
FROM osmosis_nl.nodes a
LEFT JOIN osmosis_nl.all_routes b 
	ON ST_DWithin(a.geom, b.geom,0.004) --catch all routes within xx grades from the station
WHERE 
(a.tags @> '"railway"=>"station"'::hstore AND b.vehicle = 'train') --having the correct vehicle on it
OR (a.tags @> '"highway"=>"bus_stop"'::hstore AND b.vehicle = 'bus')
OR (a.tags @> '"railway"=>"tram_stop"'::hstore AND (b.vehicle = 'tram' OR b.vehicle = 'subway'))
OR (a.tags @> '"amenity"=>"ferry_terminal"'::hstore AND b.vehicle = 'ferry')
;

CREATE INDEX stations_on_routes_stationname_idx
  ON osmosis_nl.stations_on_routes
  USING btree
	(stationname);

CREATE INDEX stations_on_routes_line_idx
  ON osmosis_nl.stations_on_routes
  USING btree
  (line);
  
--SELECT populate_geometry_columns();