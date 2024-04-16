# pg-elk

Methods for connecting a PostgreSQL database to ElasticSearch and Kibana via Logstash

**NOTE**: There is a newer version of this that uses MySQL and Docker Compose instead located here; https://github.com/stevekm/mysql-elk. If you are trying to connect a SQL db to ELK then you might want to review that version as well since its Docker usage is preferable to the conda + binary installation and management methods here. 

# Setup

- *NOTE*: see the `Makefile` contents for the exact commands and enviornment configurations used in the recipes described here.

## Install

Install dependencies:

```
make install
```

This will install a fresh `conda` to the local directory with PostgreSQL installed inside, and download and extract the software needed to run ElasticSearch, Logstash, and Kibana. The `Makefile` has been pre-configured to use this installed software for the demonstration.

## Initialize Servers

Initialize Postgres database (give it a password of 'admin'):

```
make pg-init
```

Start ElasticSearch:

```
make es-start
```

In a separate terminal session, start Logstash:

```
make ls-start
```

## Data Import

Import some rows to Postgres database (run this a few times, using the password from before)

```
make pg-import
```

You can verify that results were imported to the database with 

```
make pg-show
```

The results should look like this;

```
1|817|Sample7|Lung|Normal|2020-12-23 09:49:44.56633
2|864|Sample9|Skin|Tumor|2020-12-23 09:49:44.56633
3|575|Sample10|Lung|Tumor|2020-12-23 09:49:44.56633
4|437|Sample3|Skin|Tumor|2020-12-23 09:49:44.56633
```

Logstash should be automatically importing new entries from PostgreSQL to ElasticSearch, and its console log should show entries that look like this;

```
[2020-12-23T13:01:00,255][INFO ][logstash.inputs.jdbc     ][main][1169d815293ec69820cf79b20b70d8d5341059d0eff6abd10a319d72e8f2c0f6] (0.001520s) SELECT * from data WHERE id > 108
{
      "coverage" => 302,
    "@timestamp" => 2020-12-23T18:01:00.285Z,
      "sampleid" => "Sample8",
       "created" => 2020-12-23T18:00:40.545Z,
      "@version" => "1",
        "tissue" => "Heart",
            "id" => 116,
          "type" => "Tumor"
}
```

You can verify that the entries have been imported to ElasticSearch with the command

```
make es-show
```

The outputs should look like this;

```
curl  "http://localhost:9200/pg_data/_search?pretty=true"
{
  "took" : 39,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 135,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "pg_data",
        "_type" : "_doc",
        "_id" : "38",
        "_score" : 1.0,
        "_source" : {
          "@version" : "1",
          "sampleid" : "Sample4",
          "@timestamp" : "2020-12-23T14:59:00.136Z",
          "coverage" : 381,
          "tissue" : "Brain",
          "type" : "Tumor",
          "id" : 38,
          "created" : "2020-12-23T14:58:15.224Z"
        }
...
```

## Web Dashboard

In a separate terminal session, start Kibana

```
make kib-start
```

Open your web browser to http://localhost:5602

Go to Management > Stack Management > Index Patterns > Create Index Pattern > add a pattern for "pg_data", the index created for the imported PostgreSQL entries.

![screenshot](https://github.com/stevekm/pg-elk/raw/master/images/Screen%20Shot%202020-12-23%20at%202.56.48%20PM.png)

Then you can go to Visualize > Create New Visualization to start making visualizations on the data in the "pg_data" index. Examples:

![screenshot](https://github.com/stevekm/pg-elk/raw/master/images/Screen%20Shot%202020-12-23%20at%2010.04.33%20AM.png)

![screenshot](https://github.com/stevekm/pg-elk/raw/master/images/Screen%20Shot%202020-12-23%20at%2010.08.09%20AM.png)

If needed, you can refresh the pg_data index by going to Management > Stack Management > Index Management, select 'pg_data' check box, then Manage Index > Refresh Index

# Extras

See the `Makefile` for all included recipes. Some useful ones are listed here.

- stop the PostgreSQL database server, and ElasticSearch server

```
make pg-stop
make es-stop
```

- check the status of the Postgres and ElasticSearch servers

```
make pg-check
make es-check
```

- run some example queries on ElasticSearch

```
make es-query1
make es-query2
make es-query3
```

