Methods for connecting a Postgres SQL database to ElasticSearch and Kibana via Logstash

Setup
-----

Install dependencies:

```
make install
```

Initialize Postgres database (give it a password of 'admin')

```
make pg-init
```

Start ElasticSearch

```
make es-start
```

In a separate terminal session, start Logstash

```
make ls-start
```

Import some rows to Postgres database (run this a few times)

```
make pg-import
```

In a separate terminal session, start Kibana

```
make kib-start
```

Open your web browser to http://localhost:5602

Go to Management > Stack Management > Index Patterns > Create Index Pattern > add a pattern for "pg_data"

Then you can go to Visualize > Create New Visualization to start making visualizations on the data in the "pg_data" index

If needed, you can refresh the pg_data index by going to Management > Stack Management > Index Management, select 'pg_data' check box, then Manage Index > Refresh Index
