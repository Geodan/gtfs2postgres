/***

Create routes that will later be used to form the trip segments.

***/

CREATE SEQUENCE routesegment;
DROP TABLE IF EXISTS osmosis_nl.all_routes;
CREATE TABLE osmosis_nl.all_routes AS

WITH route_nodes AS ( --get all nodes that are in any route, order by route, way, node
	SELECT 
		a.tags -> 'route' vehicle, 
		a.tags -> 'name' routename, 
		a.tags -> 'ref' line,
		v.tags -> 'name' stationname,
		s.sequence_id as waysequenceid,
		u.sequence_id as nodesequenceid,
		a.id AS routeid,
		t.id AS wayid,
		v.geom 
	FROM osmosis_nl.relations a
	INNER JOIN osmosis_nl.relation_members s ON (a.id = s.relation_id AND s.member_type = 'W') -- uitbreiden met ways
	INNER JOIN osmosis_nl.ways t ON (s.member_id = t.id) -- koppel wegen
	INNER JOIN osmosis_nl.way_nodes u ON (t.id = u.way_id) --uitbreiden met nodes
	INNER JOIN osmosis_nl.nodes v ON (u.node_id = v.id) 
	WHERE 
	(a.tags @> '"route"=>"train"'::hstore
	OR a.tags @> '"route"=>"subway"'::hstore
	OR a.tags @> '"route"=>"tram"'::hstore
	OR a.tags @> '"route"=>"bus"'::hstore
	OR a.tags @> '"route"=>"ferry"'::hstore
	)
	ORDER BY a.id,s.sequence_id,u.sequence_id 
)
,ways As(
	SELECT vehicle, routeid, routename, line, waysequenceid,
	St_MakeLine(geom) as geom
	FROM route_nodes
	GROUP BY vehicle, routeid, routename,waysequenceid, line
	ORDER BY routeid, waysequenceid
)
/*
,ways_aligned As(
	SELECT vehicle, routeid, routename,stationarray,waysequenceid,
	CASE WHEN --
		(
			St_Equals(St_EndPoint(geom), lag(ST_EndPoint(geom)) OVER (PARTITION BY routeid ORDER BY routeid,waysequenceid))
		OR 
			ST_Equals(St_EndPoint(geom), lag(ST_StartPoint(geom)) OVER (PARTITION BY routeid ORDER BY routeid,waysequenceid))
		)
		AND lead(geom) OVER (PARTITION BY routeid ORDER BY routeid,waysequenceid) Is Not null
		THEN St_Reverse(geom)
		ELSE geom
	END as geom
	FROM ways
)*/
,route_dumped AS (
	SELECT 
	vehicle, routeid, routename, line
	--,waysequenceid
	--,geom
	,nextval('routesegment') as routesegment
	,(ST_Dump(ST_LineMerge(St_Union((geom))))).geom geom
	FROM ways
	GROUP BY vehicle, routeid, routename, line
)

SELECT * FROM route_dumped
;
DROP SEQUENCE IF EXISTS routesegment;

CREATE INDEX idx_all_routes_geom
  ON osmosis_nl.all_routes
  USING gist
  (geom );

DROP TABLE IF EXISTS osmosis_nl.all_routes_900913;
CREATE TABLE osmosis_nl.all_routes_900913 AS
SELECT vehicle, routeid, routename,routesegment, line, ST_Transform(geom,900913) geom
FROM osmosis_nl.all_routes;

CREATE INDEX idx_all_routes_900913_geom
  ON osmosis_nl.all_routes_900913
  USING gist
  (geom );

--SELECT populate_geometry_columns();
