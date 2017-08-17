DROP TABLE tomt.relations;
CREATE TABLE tomt.relations As
SELECT * FROM relations 
WHERE 
tags @> '"operator"=>"Nederlandse Spoorwegen"'::hstore
OR tags @> '"operator"=>"NS"'::hstore
--OR tags @> '"operator"=>"Connexxion"'::hstore
--OR tags @> '"operator"=>"GVB"'::hstore
--tags @> '"route"=>"bus"'::hstore
--OR tags @> '"route"=>"train"'::hstore
--OR tags @> '"route"=>"tram"'::hstore;



DROP TABLE IF EXISTS tomt.nodes;
CREATE TABLE tomt.nodes As

SELECT a.* 
FROM nodes a
INNER JOIN way_nodes b ON (a.id = b.node_id)
INNER JOIN ways c ON (b.way_id = c.id)
INNER JOIN relation_members d ON (c.id = d.member_id)
INNER JOIN tomt.relations e ON (d.relation_id = e.id)
UNION 
SELECT * FROM nodes WHERE tags @> '"railway"=>"station"'::hstore
;

DROP TABLE IF EXISTS tomt.way_nodes;
CREATE TABLE tomt.way_nodes As

SELECT b.* 
FROM way_nodes b 
INNER JOIN ways c ON (b.way_id = c.id)
INNER JOIN relation_members d ON (c.id = d.member_id)
INNER JOIN tomt.relations e ON (d.relation_id = e.id)
;

CREATE TABLE tomt.ways As

SELECT c.* 
FROM ways c 
INNER JOIN relation_members d ON (c.id = d.member_id)
INNER JOIN tomt.relations e ON (d.relation_id = e.id)
;

CREATE TABLE tomt.relation_members As

SELECT d.* 
FROM relation_members d 
INNER JOIN tomt.relations e ON (d.relation_id = e.id)
;