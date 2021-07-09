## Stack configuration

The following properties are mandatory for creating the stack:
<pre>
cr7_cr3 volume
cr7_cr driver
cr7_data volume
cr7_data driver
cr7_virtuosotmp volume
cr7_virtuosotmp driver
cr3_virtuosotmp volume
cr3_virtuosotmp driver
cr7_tmp_volume volume
cr7_tmp driver
cr_eionet_tmp volume
cr_eionet_tmp_driver driver
cron memory limit
cron memory reservation
virtuoso memory limit
virtuoso memory reservation
virtuoso dba password
CATALINA_OPTS
tomcat memory limit
tomcat memory reservation
administration memory limit
administration memory reservation
</pre>

- 6 storages should be created before launching the stack and they should be put in the respective stack properties.
- Default values for services memoryLimit and memoryReservation have been set. These values can be increased according to needs. 
- In CATALINA_OPTS the following properties should be set for the stack to startup. The values that were set in previous properties should be placed.
<pre>
        "-Xmx12000m"
        "-Djava.security.egd=file:/dev/./urandom"
        "-Dconfig.application.displayName=Ver.7 Content Registry"
        "-Dconfig.app.home=/var/local/cr3"
        "-Dconfig.harvester.tempFileDir=/var/tmp"
        "-Dconfig.virtuoso.db.usr="
        "-Dconfig.virtuoso.db.pwd="
        "-Dconfig.virtuoso.db.rousr="
        "-Dconfig.virtuoso.db.ropwd="
        "-Dconfig.harvester.batchHarvestingHours=0-7,20-23"
        "-Dconfig.harvester.jobInterval=0"
        "-Dconfig.harvester.batchHarvestingUpperLimit=100"
        "-Dconfig.harvester.httpConnection.timeout=30000"
        "-Dconfig.harvester.rdfLoaderThreads=3"
        "-Dconfig.harvester.skipXoring.noOfTriplesThreshold=3000000"
        "-Dconfig.harvester.skipXoring.fileSizeThreshold=150000000"
        "-Dlog4j.configuration=file:/var/local/cr3/log4j.xml"
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one in the order they appear from top to bottom. Services crom and administration are not needed for the application to startup.
- Create a new service rule in load balancer specifying the application url.
- Upgrade tomcat service adding in CATALINA_OPTS the properties config.application.homeURL and config.edu.yale.its.tp.cas.client.filter.serverName with the url that you specicied in previous step e.g "-Dconfig.application.homeURL=http://cr.ewxdevel1dub.eionet.europa.eu" and "-Dconfig.edu.yale.its.tp.cas.client.filter.serverName=cr.ewxdevel1dub.eionet.europa.eu"
- For configuring logging and viewing logs to an external application like graylog the file log4j.xml should be created in directory /opt/datadict and the property "-Dlog4j.configurationFile=/opt/datadict/log4j2.xml" should added in CATALINA_OPTS of tomcat service. An example of the file structure is shown below:
- For a fully functional application the following properties in CATALINA_OPTS may need to be set with the appropriate values
<pre>
    config.pingWhitelist
    mail.transport.protocol
    mail.store.protocol
    config.mail.host
    config.mail.user
    config.mail.password
    config.mail.from
    config.mail.sysAdmins
</pre>