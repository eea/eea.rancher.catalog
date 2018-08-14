# Metricbeat global stack 

Is used to monitor docker containers.

## Default configuration

https://github.com/eea/eea.docker.beats/blob/master/metricbeat/metricbeat.yml

## Environment variables

* Custom configuration - to set-up a custom configuration
* Elasticsearch URL - elasticsearch url
* Elasticsearch USER - elasticsearch username for authentification in elasticsearch
* Elasticsearch PASSWORD - elasticsearch user password 
* Tags in elasticsearch - add fields to make filtering easier in elasticsearch
* Log metricbeat internal metrics - select true to write in log every 30 seconds the metricbeat metrics



## Kibana integration

To create kibana dashboards, run 

     ./metricbeat setup --dashboards

