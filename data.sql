CREATE TABLE data (
   id serial,
   coverage int,
   sampleid text,
   tissue text,
   type text,
   created timestamp default current_timestamp
);
