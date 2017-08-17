mv ./data/stops.txt ./data/stops.csv
mv ./data/stop_times.txt ./data/stop_times.csv
mv ./data/calendar_dates.txt ./data/calendar_dates.csv
mv ./data/agency.txt ./data/agency.csv
mv ./data/routes.txt ./data/routes.csv
mv ./data/trips.txt ./data/trips.csv
mv ./data/transfers.txt ./data/transfers.csv
mv ./data/feed_info.txt ./data/feed_info.csv
mv ./data/shapes.txt ./data/shapes.csv

ogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.stops ./data/stops.vrt
ogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.stop_times ./data/stop_times.csv
ogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.calendar_dates ./data/calendar_dates.csvogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.agency ./data/agency.csv
ogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.routes ./data/routes.csv
ogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.trips ./data/trips.csv
ogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.transfers ./data/transfers.csv
ogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.feed_info ./data/feed_info.csv
ogr2ogr -f PostgreSQL PG:"dbname=research port=5433 user=postgres" -nln gtfs.shapes ./data/shapes.csv
