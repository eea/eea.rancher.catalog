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
Converters files volume
Converters MySQL volume
Files Volumes driver
MYSQL Volumes driver
</pre>

- 2 storages should be created before launching the stack, one for storing files (Converters files volume) and one for database (Converters MySQL volume) and they should be put in the respective stack properties.
- A default value of 1024MB has been set for tomcat memoryLimit and memoryReservation. These values can be increased according to needs. 
- In CATALINA_OPTS the following properties should be set for the stack to startup. The values that were set in previous properties should be placed.
<pre>
"-Xmx5120m" 
"-Xss4m" 
"-Djava.security.egd=file:/dev/./urandom" 
"-Dapp.home=/opt/xmlconv"
"-Dconfig.log.file=/opt/xmlconv/log/xmlconv.log"
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
"-Denv.schema.maxExecutionTime=36000000"
"-Denv.long.running.jobs.threshold=14400000" 
"-Denv.xquery.http.endpoints=cr.eionet.europa.eu"
"-Denv.basex.xquery.timeLimit=10000"
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one in the order they appear from top to bottom. The service converters-rsynch is not needed for the application to startup.
- After starting service dbservice and before starting tomcat service, in the container of dbservice select "Execute Shell" and run following commands:

<pre>
$ mysql -u root -p
$ enter "Database root password" you specified in previous step
$ create schema quartzDbName; (name should be the one used in quartz.db.url)
$ CREATE USER 'databaseUser'@'localhost' IDENTIFIED BY 'databasePassword';
$ GRANT ALL PRIVILEGES ON * . * TO 'databaseUser'@'%';
$ FLUSH PRIVILEGES;
</pre>

- Create a new service rule in load balancer specifying the application url.
- Upgrade tomcat service adding in CATALINA_OPTS the properties app.host and config.gdem.url with the url that you specicied in previous step e.g "-Dapp.host=converters.ewxdevel1dub.eionet.europa.eu" and "-Dconfig.gdem.url=http://converters.ewxdevel1dub.eionet.europa.eu" 
- According the workload the need for increasing tomcat instances may arise.
- For configuring logging and viewing logs to an external application like graylog the file logback.xml should be created in directory /opt/xmlconv and the property "-Dlogback.configurationFile=/opt/xmlconv/logback.xml" should added in CATALINA_OPTS of tomcat service. An example of the file structure is shown below:
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
- For a fully functional application the following properties in CATALINA_OPTS may need to be set:
1. For executing rest calls
    <pre> 
       add property jwt.secret 
       insert a record in table T_API_USER with the appropriate authorities through the container of dbservice
    </pre>
2. For communicating with uns and send notifications for long running jobs:
    <pre>
       env.uns.xml.rpc.server.url
       env.uns.channel.name
       env.uns.subscriptions.url
       env.uns.username
       env.uns.password
    </pre>
3. Datadict communication
    <pre>
        config.dd.url
        config.dd.rpc.url
    </pre>
4. CR communication for searching XML from CR
    <pre>
        config.cr.sparql.endpoint
    </pre>
5. CDR communication 
    <pre>
        config.cdr.url
    </pre>
6. FME communication
    <pre>
        fme.user
        fme.password
        fme_token
    </pre>











