rm HAB-consumer*.txt
/hab/pkgs/bumblebees/redis/unstable/20180103200104/bin/redis-cli DEL chefconf2018demo

/hab/pkgs/core/postgresql/9.6.3/20171107224408/bin/psql -U admin chefconf2018demo <<END_OF_SQL

TRUNCATE TABLE checkpoints;
TRUNCATE TABLE consumer_states;
TRUNCATE TABLE rides;
TRUNCATE TABLE staged_log_records;

ALTER SEQUENCE rides_id_seq RESTART WITH 1;
ALTER SEQUENCE staged_log_records_id_seq RESTART WITH 1;
\q
END_OF_SQL

sudo STREAM_NAME=chefconf2018demo ../forego start -e env.test
