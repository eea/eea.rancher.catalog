# Metricbeat global stack 

Is used to monitor docker containers.

## Default configuration

https://github.com/eea/eea.docker.beats/blob/master/metricbeat/metricbeat.yml

## Environment variables

* CONFIG - to set-up a custom configuration
* ES_URL - elasticsearch url
* ES_USER - elasticsearch username for authentification in elasticsearch
* ES_PASSWORD - elasticsearch user password 
* KIBANA_URL - kibana url, need to be provided for dashboard creation


## Kibana integration

To create kibana dashboards, run 

     ./metricbeat setup --dashboards

