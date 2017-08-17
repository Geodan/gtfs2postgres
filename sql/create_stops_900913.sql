DROP TABLE IF EXISTS open9292ov.stops_900913;
CREATE TABLE open9292ov.stops_900913
AS SELECT stop_name, stop_url, ST_Transform(wkb_geometry,900913) geom
FROM open9292ov.stops;

CREATE INDEX idx_stops_900913_geom
  ON open9292ov.stops_900913
  USING gist
  (geom );