# Clair

Clair is an open source project for the [static analysis] of vulnerabilities in application containers (currently including [appc] and [docker]).

1. In regular intervals, Clair ingests vulnerability metadata from a configured set of sources and stores it in the database.
2. Clients use the Clair API to index their container images; this creates a list of _features_ present in the image and stores them in the database.
3. Clients use the Clair API to query the database for vulnerabilities of a particular image; correlating vulnerabilities and features is done for each request, avoiding the need to rescan images.
4. When updates to vulnerability metadata occur, a notification can be sent to alert systems that a change has occured.

## Variables


* CLAIR_PORT - Port to expose Clair API, blank to not expose
* HOST_LABELS - Schedule clair services on hosts with the host labels
* TZ - Time zone 
* VOLUME_DRIVER - Clair database volume driver
* VOLUME_DRIVER_OPTS -  Specify "driver_opts" key/value pair in the format "optionName: optionValue".
        E.g. for the `rancher-ebs` driver you should specify the required 'size' option like this: "size: 1".

## Health checks

Clair server has implemented a health check on status 200 for a request to port 6061 - GET /health HTTP/1.0

## Usage

After first deploy, wait for ~30 minutes untill you see in the logs: `"Event":"update finished"`. Because the server start with an empty database, it starts a synchronization to import CVEs. 
This sync is run every 2 hours.
