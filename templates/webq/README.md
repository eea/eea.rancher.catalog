## Stack configuration

The following properties are mandatory for creating the stack:
<pre>
MySQL volume
MySQL Volume driver
config volume
config Volume driver
application memory limit
application memory reservation
catalina_opts
java_opts
webqproddb memory limit
webqproddb memory reservation
Database name
Database password
Database root password
Database user
</pre>

- 2 storages should be created before launching the stack and they should be put in the respective stack properties ("MySQL volume" and "config volume").
- Default values for services memoryLimit and memoryReservation have been set. These values can be increased according to needs. 
- In CATALINA_OPTS the following properties should be set for the stack to startup. The values that were set in previous properties should be placed.
<pre>
     "-Djava.security.egd=file:/dev/./urandom"
     "-Ddb.url=jdbc:mysql://webqproddb:3306/dataabaseName?maxAllowedPacket=32212254720"
     "-Ddb.driver=com.mysql.jdbc.Driver"
     "-Ddb.username=databaseUser"
     "-Ddb.password=databasePassword"
     "-Duser.file.expiration.hours=72"
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one in the order they appear from bottom to top. The service rsync-dev is not needed for the application to startup.
- After starting service webqproddb and before starting appl service, in the container of webqproddb select "Execute Shell" and run following commands:
<pre>
$ mysql -u root -p
$ enter "Database root password" you specified in previous step
$ CREATE USER 'databaseUser'@'localhost' IDENTIFIED BY 'databasePassword';
$ GRANT ALL PRIVILEGES ON * . * TO 'databaseUser'@'%';
$ FLUSH PRIVILEGES;
</pre>
Furthermore the user's eionet username and password '' must be inserted in the 'users' table and the user's username and authority (e.g. 'ADMIN') must be inserted in the 'authorities' table 
or you can set property initial.admin.username in CATALINA_OPTS of appl service with the user's username and the user will get the admin role at startup.
- Create new service rule in load balancer specifying the application url.
- Upgrade tomcat service adding in CATALINA_OPTS the property cas.service with the url that you specicied in previous step e.g "-Dcas.service=https://webforms.ewxdevel1dub.eionet.europa.eu"
- For configuring logging and viewing logs to an external application like graylog the file log4j.xml should be created in directory /opt/config and the property 
"-Dlog4j.configuration=file:/opt/config/log4j.xml" should added in CATALINA_OPTS of appl service. An example of the file structure is shown below:

~~~
    <?xml version="1.0" encoding="UTF-8" ?>
    <!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">
    <log4j:configuration xmlns:log4j="http://jakarta.apache.org/log4j/">
    
        <appender name="console" class="org.apache.log4j.ConsoleAppender">
            <layout class="org.apache.log4j.PatternLayout">
                <param name="ConversionPattern" value="%-5p [%c] : %m%n "/>
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
    
        <!-- custom log level -->
    
        <category name="org.hibernate">
            <priority value="WARN"/>
        </category>
    
        <category name="eionet.webq">
            <priority value="INFO"/>
        </category>
    
        <category name="org.directwebremoting">
            <priority value="FATAL"/>
        </category>
    
        <category name="org.springframework">
            <priority value="WARN"/>
        </category>
    
        <category name="de.betterform">
            <priority value="INFO"/>
        </category>
    
        <logger name="net.sf.ehcache">
            <level value="ERROR"/>
        </logger>
    
        <root>
            <priority value="INFO"/>
            <appender-ref ref="console"/>
            <appender-ref ref="syslog" />
        </root>
    
    </log4j:configuration>
~~~

- For a fully functional application the following property in CATALINA_OPTS needs to be configured with the appropriate value:
<pre>
    converters.api.url
</pre>

