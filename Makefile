SHELL:=/bin/bash
UNAME:=$(shell uname)
USERNAME:=$(shell whoami)
IP:=127.0.0.1
.ONESHELL:
export LOGDIR:=$(CURDIR)/logs
export PATH:=$(CURDIR):$(CURDIR)/conda/bin:$(PATH)
unexport PYTHONPATH
unexport PYTHONHOME

# ~~~~~ Installation of dependencies for running MinIO, CWL workflow ~~~~~ #
# versions for Mac or Linux
ifeq ($(UNAME), Darwin)
CONDASH:=Miniconda3-4.7.12.1-MacOSX-x86_64.sh
ES_GZ:=elasticsearch-7.10.1-darwin-x86_64.tar.gz
KIBANA_GZ:=kibana-7.10.1-darwin-x86_64.tar.gz
export KIBANA_HOME:=$(CURDIR)/kibana-7.10.1-darwin-x86_64
endif

ifeq ($(UNAME), Linux)
CONDASH:=Miniconda3-4.7.12.1-Linux-x86_64.sh
ES_GZ:=elasticsearch-7.10.1-linux-x86_64.tar.gz
KIBANA_GZ:=kibana-7.10.1-linux-x86_64.tar.gz
export KIBANA_HOME:=$(CURDIR)/kibana-7.10.1-linux-x86_64
endif

ES_URL:=https://artifacts.elastic.co/downloads/elasticsearch/$(ES_GZ)
KIBANA_URL:=https://artifacts.elastic.co/downloads/kibana/$(KIBANA_GZ)

export ES_HOME:=$(CURDIR)/elasticsearch-7.10.1
export PATH:=$(ES_HOME)/bin:$(PATH)

CONDAURL:=https://repo.continuum.io/miniconda/$(CONDASH)
conda:
	@echo ">>> Setting up conda..."
	@wget "$(CONDAURL)" && \
	bash "$(CONDASH)" -b -p conda && \
	rm -f "$(CONDASH)"

$(ES_HOME):
	wget "$(ES_URL)" && \
	tar -xzf $(ES_GZ)

$(KIBANA_HOME):
	wget "$(KIBANA_URL)" && \
	tar -xzf $(KIBANA_GZ)

$(LOGDIR):
	mkdir -p "$(LOGDIR)"

install: conda $(ES_HOME) $(KIBANA_HOME) $(LOGDIR)
	conda install -y anaconda::postgresql=12.2



# ~~~~~ Postgres Setup ~~~~~ #
# data dir for db
export PGDATA:=$(CURDIR)/pg_db
# name for db
export PGDATABASE=db
# name for db table to use
export PGTABLE:=data
# if PGUSER is not current username then need to initialize pg server user separately
export PGUSER=$(USERNAME)
# default password to use
# export PGPASSWORD=admin
export PGHOST=$(IP)
export PGLOG=$(LOGDIR)/postgres.log
export PGPORT=9011

# directory to hold the Postgres database files
$(PGDATA):
	mkdir -p "$(PGDATA)"

# set up & start the Postgres db server instance
pg-init: $(PGDATA)
	set -x && \
	pg_ctl -D "$(PGDATA)" initdb && \
	pg_ctl -D "$(PGDATA)" -l "$(PGLOG)" start && \
	createdb && \
	$(MAKE) pg-table-init

pg-table-init:
	psql -p "$(PGPORT)" -U "$(PGUSER)" -W "$(PGDATABASE)" < data.sql

# start the Postgres database server process
pg-start: $(PGDATA)
	pg_ctl -D "$(PGDATA)" -l "$(PGLOG)" start

# stop the db server
pg-stop:
	pg_ctl -D "$(PGDATA)" stop

# check if db server is running
pg-check:
	pg_ctl status

# interactive Postgres console
# use command `\dt` to show all tables
pg-inter:
	psql -p "$(PGPORT)" -U "$(PGUSER)" -W "$(PGDATABASE)"

# count number of entries in the db
pg-count:
	echo "SELECT COUNT(*) FROM $(PGTABLE)" | psql -p "$(PGPORT)" -U "$(PGUSER)" -W "$(PGDATABASE)" -At

# show contents of table
pg-show:
	echo "SELECT * FROM $(PGTABLE)" | psql -p "$(PGPORT)" -U "$(PGUSER)" -W "$(PGDATABASE)" -At

# add 5 new rows to the db
pg-import:
	echo "INSERT INTO $(PGTABLE)(value, word) VALUES ($$RANDOM, '$$(shuf -n1 /usr/share/dict/words)'), ($$RANDOM, '$$(shuf -n1 /usr/share/dict/words)'), ($$RANDOM, '$$(shuf -n1 /usr/share/dict/words)'), ($$RANDOM, '$$(shuf -n1 /usr/share/dict/words)'), ($$RANDOM, '$$(shuf -n1 /usr/share/dict/words)')" | psql -p "$(PGPORT)" -U "$(PGUSER)" -W "$(PGDATABASE)"



# ~~~~~ ElasticSearch setup ~~~~~ #
export ES_PORT:=9200
export ES_HOST:=$(IP)
export ES_URL:=http://$(ES_HOST):$(ES_PORT)
export ES_DATA:=$(CURDIR)/es_data
export ES_PIDFILE:=$(LOGDIR)/elasticsearch.pid
export ES_INDEX:=pg_data

$(ES_DATA):
	mkdir -p "$(ES_DATA)"

# ElasticSearch download, installation, and dir setup
es: $(ES_HOME) $(ES_DATA) $(LOGDIR)

# start the ElasticSearch server in daemon mode
es-start: es
	$(ES_HOME)/bin/elasticsearch \
	-E "path.data=$(ES_DATA)" \
	-E "path.logs=$(LOGDIR)" \
	-d -p "$(ES_PIDFILE)"

# stop ElasticSearch daemon
es-stop:
	pkill -F "$(ES_PIDFILE)"

# check if ElasticSearch is running
es-check:
	curl -X GET "$(ES_URL)/?pretty"

# get the entries in the ElasticSearch index
es-count:
	curl  "$(ES_URL)/$(ES_INDEX)/_search?pretty=true"


# ~~~~~ Kibana setup ~~~~~ #
export KIBANA_HOST:=$(IP)
export KIBANA_PORT:=5602
export KIBANA_LOG:=$(LOGDIR)/kibana.log
kib-start: $(KIBANA_HOME) $(LOGDIR)
	$(KIBANA_HOME)/bin/kibana \
	-e "$(ES_URL)" \
	--port "$(KIBANA_PORT)" \
	--host "$(KIBANA_HOST)" \
	--log-file "$(KIBANA_LOG)"
