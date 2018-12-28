/** Put an index to the osmosis tags
	Note: This index takes over 3 gig, since we're only interested in some tags for 
	the station category it might be better to put that information into a separate column
**/
/*
CREATE INDEX ndx_nodes_tags
  ON osmosis_nl.nodes
  USING gist
  (tags );
*/
/** Make linestring for trips out of shapes **/
SELECT AddGeometryColumn ('gtfs','trips','geom',4326,'LINESTRING',2);

UPDATE gtfs.trips AS tr 
SET geom = sh.geom
FROM
( SELECT shape_id, ST_SetSrid(ST_MakeLine(ST_MakePoint(shape_pt_lon::float, shape_pt_lat::float)),4326) geom
 FROM gtfs.shapes
 GROUP BY shape_id 
) sh
WHERE tr.shape_id = sh.shape_id;
CREATE INDEX trips_route_id_idx
  ON gtfs.trips
  USING btree
  (route_id);
  
/** Make geometry object for stops **/
SELECT AddGeometryColumn ('gtfs','stops','geom',4326,'POINT',2);
UPDATE gtfs.stops SET geom = ST_SetSrid(St_MakePoint(stop_lon, stop_lat),4326);
CREATE INDEX sidx_stops_geom
  ON gtfs.stops
  USING gist
  (geom);
/** Create a simple stop-name to be able to compare with OSM stop names **/
ALTER TABLE gtfs.stops
   ADD COLUMN name_simple character varying;


/** block for testing
SELECT 
	CASE WHEN position(',' in stop_name) > 1
		THEN upper(ltrim(split_part(stop_name,',',2))) 
	ELSE 
		upper(stop_name)
	END 
FROM gtfs.stops LIMIT 100; --testline
**/	
UPDATE gtfs.stops SET name_simple = upper(stop_name);
UPDATE gtfs.stops SET name_simple = upper(ltrim(split_part(stop_name,',',2))) WHERE position(',' in stop_name) > 1;


ALTER TABLE gtfs.stops
   ADD COLUMN id_simple integer;
UPDATE gtfs.stops SET id_simple = left(stop_id,7)::Integer;
ALTER TABLE gtfs.stop_times
   ADD COLUMN stop_id_simple integer;
UPDATE gtfs.stop_times SET stop_id_simple = left(stop_id,7)::Integer; --SET stop_id_simple = stop_id::integer WHERE length(stop_id) =7;
--AND stop_id LIKE '1%'
--AND stop_id_simple Is null;
--SELECT stop_id::integer FROM gtfs.stop_times  WHERE length(stop_id) = 7 LIMIT 1000;

/** add indices **/

CREATE INDEX stops_name_simple_idx
  ON gtfs.stops
  USING btree
  (name_simple );

CREATE INDEX stops_id_simple_idx
  ON gtfs.stops
  USING btree
  (id_simple );

CREATE INDEX stop_times_departure_time_idx
  ON gtfs.stop_times
  USING btree
  (departure_time );

CREATE INDEX stop_times_stop_id_simple_idx
  ON gtfs.stop_times
  USING btree
  (stop_id_simple );

CREATE INDEX stop_times_trip_id_idx
  ON gtfs.stop_times
  USING btree
  (trip_id );

CREATE INDEX calendar_dates_date_idx
  ON gtfs.calendar_dates
  USING btree
  (date );

CREATE INDEX trips_route_id_idx
  ON gtfs.trips
  USING btree
  (route_id );

CREATE INDEX trips_trip_id_idx
  ON gtfs.trips
  USING btree
  (trip_id );