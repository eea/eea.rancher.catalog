# Clair

Clair is an open source project for the [static analysis] of vulnerabilities in application containers (currently including [appc] and [docker]).

1. In regular intervals, Clair ingests vulnerability metadata from a configured set of sources and stores it in the database.
2. Clients use the Clair API to index their container images; this creates a list of _features_ present in the image and stores them in the database.
3. Clients use the Clair API to query the database for vulnerabilities of a particular image; correlating vulnerabilities and features is done for each request, avoiding the need to rescan images.
4. When updates to vulnerability metadata occur, a notification can be sent to alert systems that a change has occured.

## Rancher Crontab 

To be able to schedule the clair-scanner containers to run once per day, you need to deploy a rancher crontab stack on the same environment. 
Use Rancher crontab container Stack - https://github.com/eea/eea.rancher.catalog/tree/master/templates/rancher-crontab.

## Variables

* CLAIR_PORT - Port to expose Clair API, blank to not expose
* HOST_LABELS - Schedule clair services on hosts with the host labels
* LEVEL - Scanner CVE severity threshold
* DOCKER_API_VERSION - to be set if there are hosts with older docker versions
* CRON_SCHEDULE - Crontab schedule to start the containers 
* TZ - Time zone 
* VOLUME_DRIVER - Clair database volume driver
* VOLUME_DRIVER_OPTS -  Specify "driver_opts" key/value pair in the format "optionName: optionValue".
        E.g. for the `rancher-ebs` driver you should specify the required 'size' option like this: "size: 1".


## Health checks

Clair server has implemented a health check on status 200 for a request to port 6061 - GET /health HTTP/1.0

## Usage

After first deploy, wait for ~30 minutes untill you see in the logs: `"Event":"update finished"`. Because the server start with an empty database, it starts a synchronization to import CVEs. 
This sync is run every 2 hours on Clair server. 
The clair-scanner runs according to crontab configuration.

### Output/Logs/Graylog

The clair-scanner outputs logs in a json format. In graylog, a JSON extractor should be added with the condition:"the message includes the string clair-scan-status" on the field message.

After the extractor is created, you need to create a Stream per each monitored environment ( environment_uuid field ). On each stream, an Alert condition on clair-scan-status=ERROR should be added and an appropriate notification should be created.




