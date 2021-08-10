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
- In CATALINA_OPTS the following properties should be set for the stack to startup. The values that were set in previous properties should be placed. You should also specify the database user passowrds.
<pre>
        "-Xmx12000m"
        "-Djava.security.egd=file:/dev/./urandom"
        "-Dconfig.application.displayName=Ver.7 Content Registry"
        "-Dconfig.app.home=/var/local/cr3"
        "-Dconfig.harvester.tempFileDir=/var/tmp"
        "-Dconfig.virtuoso.db.usr=cr3user"
        "-Dconfig.virtuoso.db.pwd="
        "-Dconfig.virtuoso.db.rousr=cr3rouser"
        "-Dconfig.virtuoso.db.ropwd="
        "-Dconfig.harvester.batchHarvestingHours=0-7,20-23"
        "-Dconfig.harvester.jobInterval=0"
        "-Dconfig.harvester.batchHarvestingUpperLimit=100"
        "-Dconfig.harvester.httpConnection.timeout=30000"
        "-Dconfig.harvester.rdfLoaderThreads=3"
        "-Dconfig.harvester.skipXoring.noOfTriplesThreshold=3000000"
        "-Dconfig.harvester.skipXoring.fileSizeThreshold=150000000"
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one. Services cron and administration are not needed for the application to startup. Service virtuoso needs to start before tomcat service.
- After starting service virtuoso and before starting tomcat service, upgrade it adding the following environment variables:
  <pre>
        VIRT_Parameters_ColumnStore: '1'
        VIRT_Parameters_DirsAllowed: ., ../vad, /usr/share/proj, /var/tmp, /var/local/cr3/files
        VIRT_Parameters_KeepAliveTimeout: '100'
        VIRT_Parameters_MaxCheckpointRemap: '2000000'
        VIRT_Parameters_MaxDirtyBuffers: '2000000'
        VIRT_Parameters_MaxQueryCostEstimationTime: '0'
        VIRT_Parameters_MaxQueryExecutionTime: '600'
        VIRT_Parameters_MaxQueryMem: 12G
        VIRT_Parameters_MaxVectorSize: '2000000'
        VIRT_Parameters_NumberOfBuffers: '3000000'
        VIRT_Parameters_ResultSetMaxRows: '50000'
        VIRT_Parameters_TimezonelessDatetimes: '0'
        VIRT_Parameters_VectorSize: '2000'
  </pre>
Moreover, in the container of service virtuoso select "Execute Shell" and run the following commands:
<pre>
$ cat > 1_create_users.sql
The file 1_create_users.sql should be in the format of https://github.com/eea/eionet.contreg/blob/master/sql/virtuoso/install/1_create_users.sql, where you will set the user passwords that you specified in catalina_opts of previous step.
$ cat > 2_setup_full_text_indexing.sql
The file 2_setup_full_text_indexing.sql should be in the format of https://github.com/eea/eionet.contreg/blob/master/sql/virtuoso/install/2_setup_full_text_indexing.sql
$ isql 1111 -U dba -P virtuoso_dba_password < 1_create_users.sql, where virtuoso_dba_password is the "virtuoso dba password" you set while creating the stack
$ isql 1111 -U dba -P virtuoso_dba_password < 2_setup_full_text_indexing.sql
</pre>

- Start tomcat service
- Create a new service rule in load balancer specifying the application url.
- Upgrade tomcat service adding in CATALINA_OPTS the properties config.application.homeURL and config.edu.yale.its.tp.cas.client.filter.serverName with the url that you specicied in previous step e.g "-Dconfig.application.homeURL=http://cr.ewxdevel1dub.eionet.europa.eu" and "-Dconfig.edu.yale.its.tp.cas.client.filter.serverName=cr.ewxdevel1dub.eionet.europa.eu"
- For configuring logging and viewing logs to an external application like graylog the file log4j.xml should be created in directory /var/local/cr3 and the property "-Dlog4j.configuration=file:/var/local/cr3/log4j.xml" should added in CATALINA_OPTS of tomcat service. An example of the file structure is shown below:

~~~
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">

<log4j:configuration xmlns:log4j="http://jakarta.apache.org/log4j/">

    <appender name="console" class="org.apache.log4j.ConsoleAppender">
        <param name="Target" value="System.out" />
        <param name="Threshold" value="debug" />
        <layout class="org.apache.log4j.PatternLayout">
            <param name="ConversionPattern" value="[%-5p] - %c - %m%n" />
        </layout>
    </appender>

    <appender name="syslog" class="org.apache.log4j.net.SyslogAppender">
        <param name="Threshold" value="debug" />
        <param name="SyslogHost" value="logserver.server:port"/>
        <param name="Facility" value="USER"/>
        <param name="FacilityPrinting" value="false"/>
        <layout class="org.apache.log4j.PatternLayout">
            <param name="ConversionPattern" value="applicationUrl %d{yyyy-MM-dd'T'HH:mm:ssX} %c{2} %m%n"/>
        </layout>
    </appender>

    <appender name="file" class="org.apache.log4j.RollingFileAppender">
        <param name="file" value="DataDict.log" />
        <param name="MaxFileSize" value="5000KB" />
        <param name="MaxBackupIndex" value="10" />
        <layout class="org.apache.log4j.PatternLayout">
            <param name="ConversionPattern" value="[%-5p] %d{dd.MM.yy HH:mm:ss} - %c - %m%n" />
        </layout>
    </appender>

    <logger name="eionet.cr">
        <level value="info" />
    </logger>

    <logger name="eionet.cr.web.action.PingActionBean">
        <level value="debug" />
    </logger>

    <logger name="org.apache">
        <level value="info" />
    </logger>

    <logger name="org.springframework">
        <level value="warn" />
    </logger>

    <logger name="org.displaytag">
        <level value="warn" />
    </logger>

    <logger name="net.sourceforge.stripes">
        <level value="warn" />
    </logger>

    <root>
        <priority value="info" />
        <appender-ref ref="console" />
        <appender-ref ref="file" />
        <appender-ref ref="syslog" />
    </root>

</log4j:configuration>
~~~

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