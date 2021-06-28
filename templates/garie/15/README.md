# What is Garie?

https://github.com/boyney123/garie/

## Highlights

- Get setup with polling performance data and out of the box dashboards within minutes.
- Setup CRON jobs to get performance data at any interval.
- Webhook support (e.g Trigger collection of performance data every release).
- Generates reports with recommended improvements for your website (Using Lighthouse)
- Historic reports. See any report that was generated in the past.
- Generates performance videos.
- Plugin Architecture using Docker

## [Docs](https://garie.io)

Quicklinks:

- [**Getting started**](https://garie.io/docs/getting-started/installation)
- [Viewing Dashboards](https://garie.io/docs/getting-started/viewing-dashboards)
- [Building your first dashboard](https://garie.io/docs/creating-your-own-dashboard/getting-started)
- [Examples of Garie](https://garie.io/docs/examples/example-list)


### Plugins

- [Lighthouse](https://github.com/eea/garie-lighthouse)
- [Pagespeed Insights](https://github.com/eea/garie-pagespeed-insights)
- [Browsertime](https://github.com/eea/garie-pagespeed-insights)
- [Linksintegrity](https://github.com/eea/garie-linksintegrity)
- [Sonarqube](https://github.com/eea/garie-sonarqube)
- [Uptimerobot](https://github.com/eea/garie-uptimerobot)
- [SSLlabs](https://github.com/eea/garie-ssllabs)
- [Privacyscore](https://github.com/eea/garie-privacyscore)
- [Securityheaders](https://github.com/eea/garie-securityheaders)
- [Sentry-metrics](https://github.com/eea/garie-sentry-metrics)
- [Webbkoll](https://github.com/eea/garie-webbkoll)



## Variables

- *Influx administrator username* - used on influxdb 
- *Influx administrator password* - used on influxdb
- *Docker binary path* - used by browsertime to start docker containers, default `/usr/bin/docker`
- *Grafana `admin` user password*
- *Pagespeed insights key* - must be taked from Pagespeed API
- *Garie configuration* - used for all plugins, must be json and respect the format common on all plugins https://github.com/eea/garie-plugin
- *Schedule frontend services on hosts with following host labels* - Comma separated list of host labels (e.g. key1=value1,key2=value2) to be used for scheduling all the services besides influxdb
- *Schedule influxdb on hosts with following host labels* - Comma separated list of host labels (e.g. key1=value1,key2=value2) to be used for scheduling influxdb
- *Time zone* - default `Europe/Copenhagen`
- *Influxdb data volume driver* - default local
- *Influxdb data volume driver options* - used in rancher_ebs volumes to set size
- *Frontend services volumes' driver* - use nfs if you don't want to pin the services to rancher hosts
- *Frontend services volumes' driver options* -  used in rancher_ebs volumes to set size

## Configuration 


## Deploy

If you are using NFS volumes, you will need to manually add the contents in them because they are not automaticaly copied from the image. For grafana container, you need to start it with a different entrypoint ( like 'sh' with -it flags ) and copy the grafana.ini and provisioning directory. Otherwise the container will not start. You will also need to add rights to grafana to the configuration directory:

      chown -R grafana:grafana /etc/grafana/

## Rancher LB

We have the following services that should be exposed in rancher lb:

- grafana:3000
- chronograf:8888
- garie-lighthouse:3000
- garie-browsertime:3000
- garie-webscore:3000

