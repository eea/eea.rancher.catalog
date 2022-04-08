## Stack configuration

The following properties are mandatory for creating the stack:
<pre>
template for
cron memory limit (in case of converters and convertersbdr)
cron memory reservation (in case of converters and convertersbdr)
dbservice memory limit
dbservice memory reservation
administration memory limit (in case of converters and converterstest)
administration memory reservation (in case of converters and converterstest)
converters_rsynch memory limit (in case of converters and convertersbdr)
converters_rsynch memory reservation (in case of converters and convertersbdr)
Database name
Database password
Database root password
Database user
Tomcat memory limit
Tomcat memory reservation
CATALINA_OPTS
xqueryPassword
xqueryUser
Converters files volume
Converters MySQL volume
JobExecutor MySQL volume
Files Volumes driver
MYSQL Volumes driver
JobExecutor mysql Volumes driver
JobExecutor memory limit
JobExecutor memory reservation
RabbitMQ host
RabbitMQ port
RabbitMQ username
RabbitMQ username
JobExecutorHeavy memory limit
JobExecutorHeavy memory reservation
SyncFmeJobExecutor memory limit
SyncFmeJobExecutor memory reservation
AsyncFmeJobExecutor memory limit
AsyncFmeJobExecutor memory reservation
Asynchronous fme jobExecutor database 
Asynchronous fme jobExecutor database username
Asynchronous fme jobExecutor database password
Asynchronous fme jobExecutor database root password
</pre>

- 3 storages should be created before launching the stack, one for storing files (Converters files volume), one for converters database (Converters MySQL volume) and one for async fme jobExecutor database (JobExecutor MySQL volume) and they should be put in the respective stack properties.
- A default value of 1024MB has been set for tomcat memoryLimit and memoryReservation. These values can be increased according to needs. 
- In CATALINA_OPTS the following properties should be set for the stack to startup. The values that were set in previous properties should be placed.
<pre>
"-Xmx5120m" 
"-Xss4m" 
"-Djava.security.egd=file:/dev/./urandom" 
"-Dapp.home=/opt/xmlconv"
"-Dconfig.heavy.threshold=10485760" 
"-Dconfig.db.jdbcurl=jdbc:mysql://dbservice:3306/databaseName?autoReconnect=true&amp;characterEncoding=UTF-8&amp;emptyStringsConvertToZero=false&amp;jdbcCompliantTruncation=false" 
"-Dconfig.db.driver=com.mysql.jdbc.Driver" 
"-Dconfig.db.user=databaseUser" 
"-Dconfig.db.password=databasePassword" 
"-Dquartz.db.url=jdbc:mysql://dbservice:3306/quartzDbName?autoReconnect=true&amp;characterEncoding=UTF-8&amp;emptyStringsConvertToZero=false&amp;jdbcCompliantTruncation=false" 
"-Dquartz.db.user=databaseUser" 
"-Dquartz.db.pwd=databasePassword" 
"-Dconfig.hostname=$HOSTNAME" 
"-Dconfig.isRancher=1" 
"-Denv.long.running.jobs.threshold=14400000" 
"-Denv.xquery.http.endpoints=cr.eionet.europa.eu"
"-Denv.basex.xquery.timeLimit=10000"
"-Dwq.job.max.age=336"
"-Duns.sendNotification.method=/v2/uns/event/legacy/sendNotification/"
"-Denv.rabbitmq.host=rabbitmqHostName"
"-Denv.rabbitmq.port=rabbitmqPort"
"-Denv.rabbitmq.username=rabbitmqUsername"
"-Denv.rabbitmq.password=rabbitmqPassword"
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one. The service converters-rsynch is not needed for the application to startup. The service dbservice needs to start before tomcat service and 
services tomcat and asyncFmeDatabase should start before services jobExecutor, jobExecutorHeavy, syncFmeJobExecutor and asyncFmeJobExecutor.
- Initially start dbservice and after starting it, in the container of dbservice select "Execute Shell" and run following commands:

<pre>
$ mysql -u root -p
$ enter "Database root password" you specified in previous step
$ create schema quartzDbName; (name should be the one used in quartz.db.url)
$ CREATE USER 'databaseUser'@'localhost' IDENTIFIED BY 'databasePassword';
$ GRANT ALL PRIVILEGES ON * . * TO 'databaseUser'@'%';
$ FLUSH PRIVILEGES;
</pre>

- After staring service dbservice, start service tomcat.
- Create a new service rule in load balancer specifying the application url.
- Upgrade tomcat service adding in CATALINA_OPTS the properties app.host and config.gdem.url with the url that you specicied in previous step e.g "-Dapp.host=converters.ewxdevel1dub.eionet.europa.eu" and "-Dconfig.gdem.url=http://converters.ewxdevel1dub.eionet.europa.eu" 
- An environment API key should be created and the following properties should be added in CATALINA_OPTS:
<pre>
    env.rancher.api.url
    env.rancher.api.accessKey
    env.rancher.api.secretKey
    env.rancher.api.light.jobExec.service.id=id of light jobExecutor service
    env.rancher.api.heavy.jobExec.service.id=id of heavy jobExecutorHeavy service
    env.rancher.api.sync.fme.jobExec.service.id=id of sync fme jobExecutor service
    env.rancher.api.async.fme.jobExec.service.id=id of async fme jobExecutor service
</pre>
- For configuring logging for converters and viewing logs to an external application like graylog the file logback.xml should be created in directory /opt/xmlconv and the property "-Dlogback.configurationFile=/opt/xmlconv/logback.xml" should added in CATALINA_OPTS of tomcat service. An example of the file structure is shown below:
~~~
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>[%-5p] %d{dd.MM.yy HH:mm:ss} - %c - %m%n</pattern>
        </encoder>
    </appender>

    <appender name="SYSLOG" class="ch.qos.logback.classic.net.SyslogAppender">
        <syslogHost>logserver.server</syslogHost>
        <port>logserver.port</port>
        <facility>USER</facility>
        <suffixPattern>%d{yyyy-MM-dd'T'HH:mm:ssX} %property{config.hostname} %logger %msg</suffixPattern>
    </appender>
<!-- %property{app.host} -->

    <root level="info">
        <appender-ref ref="STDOUT" />
        <appender-ref ref="SYSLOG" />
    </root>

</configuration>
~~~
- Before starting services jobExecutor, jobExecutorHeavy, syncFmeJobExecutor, asyncFmeJobExecutor in order for services to properly work and show logs to an external application like graylog the file executorLogback.xml should be created in directory /opt/xmlconv before starting jobExecutor, jobExecutorHeavy, syncFmeJobExecutor and asyncFmeJobExecutor. An example of the file structure is shown below:
~~~
<configuration debug="true">

    <define name="appName" class="eionet.xmlconv.jobExecutor.ApplicationNamePropertyDefiner"/>


    <appender name="GELF" class="de.siegmar.logbackgelf.GelfTcpAppender">
        <graylogHost>garylogHost</graylogHost>
        <graylogPort>graylogPort</graylogPort>
        <connectTimeout>50000</connectTimeout>
         <encoder class="de.siegmar.logbackgelf.GelfEncoder">
            <includeRawMessage>false</includeRawMessage>
            <includeMarker>true</includeMarker>
            <includeMdcData>true</includeMdcData>
            <includeCallerData>false</includeCallerData>
            <includeRootCauseData>false</includeRootCauseData>
            <includeLevelName>false</includeLevelName>
            <shortPatternLayout class="ch.qos.logback.classic.PatternLayout">
                <pattern>%m%nopex</pattern>
            </shortPatternLayout>
            <fullPatternLayout class="ch.qos.logback.classic.PatternLayout">
                <pattern>%m%n</pattern>
            </fullPatternLayout>
            <numbersAsString>false</numbersAsString>
            <staticField>application_name:${appName}</staticField>
            <staticField>rancherService:jobExecutor</staticField>
            <staticField>containerName:${appName}</staticField>
            <staticField>os_arch:${os.arch}</staticField>
            <staticField>os_name:${os.name}</staticField>
            <staticField>os_version:${os.version}</staticField>
        </encoder>
    </appender>

    <appender name="Console"
              class="ch.qos.logback.core.ConsoleAppender">
        <layout class="ch.qos.logback.classic.PatternLayout">
            <Pattern>
                %black(%d{ISO8601}) %highlight(%-5level) [%blue(%t)]   %yellow(%C{1.}): %msg%n%throwable
            </Pattern>
        </layout>
    </appender>

    <root level="INFO">
        <appender-ref ref="GELF" />
        <appender-ref ref="Console" />
    </root>

</configuration>
~~~

- For a fully functional application the following properties in tomcat CATALINA_OPTS may need to be set:
1. Graylog communication (links in the form of graylogLink/search?rangetype=absolute&fields=message%2Csource&width=1848&highlightMessage=&q=)
    <pre>
        env.converters.graylog=graylog link for converters app 
        env.jobExecutor.graylog=graylog link for jobExecutor app
    </pre>
2. For executing rest calls
    <pre> 
       add property jwt.secret 
       insert a record in table T_API_USER with the appropriate authorities through the container of dbservice
    </pre>
3. For communicating with uns and send notifications for long running jobs or alerts:
    <pre>
       env.uns.url
       uns.rest.username
       uns.rest.password
       env.uns.xml.rpc.server.url
       env.uns.channel.name
       env.uns.subscriptions.url
       env.uns.username
       env.uns.password
       env.uns.alerts.channel.name
    </pre>
4. Datadict communication
    <pre>
        config.dd.url
        config.dd.rpc.url
    </pre>
5. CR communication for searching XML from CR
    <pre>
        config.cr.sparql.endpoint
    </pre>
6. CDR communication 
    <pre>
        config.cdr.url
    </pre>
7. FME communication
    <pre>
        env.fme.user
        env.fme.password
        env.fme.token
    </pre>
8. ldap communication
    <pre>
        ldap.url
    </pre>

- The following properties are declared with the specific default values in tomcat service, but can be configured if need be by adding them in CATALINA_OPTS.
<pre>
    "-Denv.rabbitmq.workers.jobs.queue=workers-jobs-queue"
    "-Denv.rabbitmq.workers.jobs.results.queue=workers-jobs-results-queue"
    "-Denv.rabbitmq.workers.status.queue=workers-status-queue"
    "-Denv.rabbitmq.worker.heartBeat.response.queue=worker-heart-beat-response-queue"
    "-Denv.rabbitmq.xmlconv.heartBeat.request.exchange=xmlconv-heart-beat-request-exchange"
    "-Denv.rabbitmq.main.xmlconv.jobs.exchange=main-xmlconv-jobs-exchange"
    "-Denv.rabbitmq.main.workers.exchange=main-workers-exchange"
    "-Denv.rabbitmq.jobs.routingkey=xmlconv-job"
    "-Denv.rabbitmq.jobs.results.routingkey=xmlconv-job-result"
    "-Denv.rabbitmq.worker.status.routingkey=xmlconv-worker-status"
    "-Denv.rabbitmq.worker.heartBeat.response.routingKey=worker-heart-beat-response-routing"
    "-Denv.rabbitmq.dead.letter.queue=workers-dead-letter-queue"
    "-Denv.rabbitmq.dead.letter.exchange=workers-dead-letter-exchange"
    "-Denv.rabbitmq.dead.letter.routingKey=workers-dead-letter-routing-key"
    "-Denv.rabbitmq.heavy.workers.jobs.queue=workers-heavy-jobs-queue"
    "-Denv.rabbitmq.main.xmlconv.heavy.jobs.exchange=main-xmlconv-heavy-jobs-exchange"
    "-Denv.rabbitmq.heavy.jobs.routingkey=xmlconv-job-heavy"
    "-Denv.rabbitmq.workers.fme.sync.jobs.queue=workers-sync-fme-jobs-queue"
    "-Denv.rabbitmq.xmlconv.sync.fme.jobs.exchange=xmlconv-sync-fme-jobs-exchange"
    "-Denv.rabbitmq.sync.fme.jobs.routingkey=xmlconv-sync-fme-jobs-routingKey"
    "-Denv.rabbitmq.workers.fme.async.jobs.queue=workers-async-fme-jobs-queue"
    "-Denv.rabbitmq.xmlconv.async.fme.jobs.exchange=xmlconv-async-fme-jobs-exchange"
    "-Denv.rabbitmq.async.fme.jobs.routingkey=xmlconv-async-fme-jobs-routingKey"
    "-Denv.max.light.jobExecutor.containers.allowed=10"
    "-Denv.max.heavy.jobExecutor.containers.allowed=3"
    "-Denv.max.sync.fme.jobExecutor.containers.allowed=4"
    "-Denv.max.async.fme.jobExecutor.containers.allowed=1"
</pre>
- If changes are made in the above default properties, then the respective changes should also be applied in properties of services jobExecutor, jobExecutorHeavy, syncFmeJobExecutor, asyncFmeJobExecutor
<pre>
    job.rabbitmq.jobsResultExchange=main-workers-exchange
    job.rabbitmq.jobsResultRoutingKey=xmlconv-job-result
    job.rabbitmq.listeningQueue=workers-jobs-queue (for service jobExecutor) | workers-heavy-jobs-queue (for service jobExecutorHeavy) | workers-sync-fme-jobs-queue (for service syncFmeJobExecutor) | workers-async-fme-jobs-queue (for service asyncFmeJobExecutor)
    job.rabbitmq.workerStatusRoutingKey=xmlconv-worker-status
    heartBeat.response.rabbitmq.routingKey=worker-heart-beat-response-routing
    heartBeat.request.rabbitmq.exchange=xmlconv-heart-beat-request-exchange
    rabbitmq.dead.letter.exchange=workers-dead-letter-exchange
    rabbitmq.dead.letter.routingKey=workers-dead-letter-routing-key
</pre>

- For services jobExecutor, jobExecutorHeavy, syncFmeJobExecutor and asyncFmeJobExecutor to be completely functional the following properties should be set:
<pre>
    converters_url
    converters_restapi_token
    fme_retry_hours
    fme_user
    fme_user_password
    fme_token
    fme_synchronous_token
    dd_url
    dd_restapi_token
</pre>
- For service asyncFmeJobExecutor the following properties should be set for connection with the database:
<pre>
    spring.datasource.url
    spring.datasource.username
    spring.datasource.password
    spring.autoconfigure.exclude with no value
    enable.fmeScheduler=true for enabling async fme scheduled task that polls async fme jobs for their status
</pre>
