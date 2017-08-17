
CREATE OR REPLACE FUNCTION osmosis_nl.get_stretch(text, text)
  RETURNS geometry AS
$$
WITH station_nodes AS (
	SELECT b.relation_id, a.id, a.tags , t.id as way_id, s.sequence_id as way_sequence, a.geom as station_geom
	FROM osmosis_nl.nodes a
	INNER JOIN osmosis_nl.relation_members b ON (a.id = b.member_id)
	INNER JOIN osmosis_nl.relations c ON (b.relation_id = c.id)

	--Zoek ways behorende bij station
	INNER JOIN osmosis_nl.relation_members s ON (b.relation_id = s.relation_id AND s.member_type = 'W') -- uitbreiden met ways
	INNER JOIN osmosis_nl.ways t ON (s.member_id = t.id) -- koppel wegen
	INNER JOIN osmosis_nl.way_nodes u ON (t.id = u.way_id) --uitbreiden met nodes
	INNER JOIN osmosis_nl.nodes v ON (u.node_id = v.id AND v.id = a.id) --versmallen met station 2
	
	WHERE a.tags @> '"railway"=>"station"'::hstore
	AND c.tags @> '"route"=>"train"'::hstore
		
)
,routelist AS ( 
	SELECT 
		a.relation_id as route_id, 
		a.id as station1_id, b.id as station2_id, 
		a.way_id as way1_id, b.way_id as way2_id,
		a.station_geom as station1_geom, b.station_geom as station2_geom,
		a.way_sequence as way1_sequence, b.way_sequence as way2_sequence
	FROM station_nodes as a
	INNER JOIN station_nodes as b ON (a.relation_id = b.relation_id) --routes waar stations beide voorkomen

	WHERE	(a.tags @> hstore('name',$1))
	AND (b.tags @> hstore('name',$2))
	ORDER BY a.way_sequence -- try to get the lowest sequence first to prefer an ascending sequence
)

,route AS (
	SELECT 
		route_id, 
		way1_sequence as waysequence_start, way2_sequence as waysequence_end
		,station1_geom, station2_geom
	FROM routelist
	--WHERE (way1_sequence < way2_sequence) --obey direction
	LIMIT 1
)

,routenodes as(
	SELECT a.id as routeid, c.id as wayid, b.sequence_id as waysequence,
	d.sequence_id
	,e.geom geom
	, waysequence_start, waysequence_end
	,station1_geom, station2_geom
	FROM osmosis_nl.relations a 
	INNER JOIN route r ON (a.id = r.route_id)
	INNER JOIN osmosis_nl.relation_members b ON (a.id = b.relation_id)
	INNER JOIN osmosis_nl.ways c ON (b.member_id = c.id)
	INNER JOIN osmosis_nl.way_nodes d ON (c.id = d.way_id)
	INNER JOIN osmosis_nl.nodes  e ON (d.node_id = e.id AND NOT a.tags @> '"railway"=>"station"'::hstore)
	WHERE 
	( (b.sequence_id >= waysequence_start AND b.sequence_id < waysequence_end)
	 OR
	 (b.sequence_id < waysequence_start AND b.sequence_id >= waysequence_end)
	) AND
	b.member_type = 'W'
	--GROUP BY a.id, b.sequence_id, c.id
	ORDER BY a.id, b.sequence_id, d.sequence_id
)
,routeways as(

	SELECT 
		routeid, 
		wayid,waysequence,
		waysequence_start, waysequence_end
		,station1_geom, station2_geom
		,ST_MakeLine(geom) geom --make 1 line per way
	FROM routenodes
	GROUP BY routeid, wayid, waysequence, waysequence_start, waysequence_end,station1_geom, station2_geom
	ORDER BY routeid, waysequence
)

SELECT 
	--waysequence_start ,waysequence_end,
	(
	CASE 
		WHEN (waysequence_start > waysequence_end)
			THEN ST_Reverse(ST_LineMerge(ST_Union(geom)))
		WHEN ST_Line_Locate_Point(ST_LineMerge(ST_Union(geom)), station1_geom) > 0.5
			THEN ST_Reverse(ST_LineMerge(ST_Union(geom)))
		ELSE
			ST_LineMerge(ST_Union(geom))
		END
		)as geom

FROM routeways
GROUP BY routeid,waysequence_start, waysequence_end,station1_geom
HAVING ST_GeometryType(ST_LineMerge(ST_Union(geom))) = 'ST_LineString'
$$

  LANGUAGE sql IMMUTABLE STRICT
  COST 100;

