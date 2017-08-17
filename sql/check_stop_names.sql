SELECT 
 a.stop_name
,tags -> 'name' 
FROM open9292ov.stops a
LEFT JOIN osmosis_nl.nodes b 
ON (b.tags -> 'name' = a.stop_name AND tags @> '"railway"=>"station"'::hstore )
WHERE 
a.stop_url != ''
ORDER BY stop_name

--UPDATE tomt.nodes SET 