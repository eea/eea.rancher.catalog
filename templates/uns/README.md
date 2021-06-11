## Stack configuration

The following properties are mandatory for creating the stack:
<pre>
Uns files volume
Uns MySQL volume
Files Volumes driver
MYSQL Volumes driver
rsync-dev memory limit
rsync-dev memory reservation
Database name
Database password
Database root password
Database user
CATALINA_OPTS
dbservice memory limit
dbservice memory reservation
tomcat memory limit
tomcat memory reservation
mailservice LOGSPOUT
mailservice MTP_HOST
mailservice MTP_PASS
mailservice MTP_PORT
mailservice MTP_RELAY
mailservice MTP_USER
mailservice memory limit
mailservice memory reservation
administration memory limit
administration memory reservation
alpine-dev memory limit
alpine-dev memory reservation
smtpmock memory limit
smtpmock memory reservation
</pre>

- 2 storages should be created before launching the stack, one for storing files (Uns files volume) and one for database (Uns MySQL volume) and they should be put in the respective stack properties.
- Default values for services memoryLimit and memoryReservation have been set. These values can be increased according to needs. 
- In CATALINA_OPTS the following properties should be set for the stack to startup. The values that were set in previous properties should be placed.
<pre>
"-Dlog4j.configurationFile=/opt/uns/log4j2-gelf.xml" 
"-Ddb.host=dbservice"
"-Ddb.url=jdbc:mysql://dbservice:3306/databaseName?useUnicode=true&characterEncoding=UTF-8&autoReconnect=true&createDatabaseIfNotExist=true"
"-Ddb.user=databaseUser" 
"-Ddb.password=databasePassword"
"-Djabber.host=" 
"-Dpop3.host=" 
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one in the order they appear from top to bottom. The only services that are needed for the application to startup are dbservice and tomcat.
- After starting service dbservice and before starting tomcat service, in the container of dbservice select "Execute Shell" and run following commands:
<pre>
$ mysql -u root -p
$ enter "Database root password" you specified in previous step
$ CREATE USER 'databaseUser'@'localhost' IDENTIFIED BY 'databasePassword';
$ GRANT ALL PRIVILEGES ON * . * TO 'databaseUser'@'%';
$ FLUSH PRIVILEGES;
</pre>
- Create 2 new service rules in load balancer specifying the application url (consistent with what you specified in mailservice MTP_HOST), one service rule with protocol http and one with protocol https.
- Upgrade tomcat service adding in CATALINA_OPTS the properties cas.filter.serverName, cas.filter.domain and uns.url with the url that you specicied in previous step e.g "-Dcas.filter.serverName=uns.ewxdevel1dub.eionet.europa.eu", "-Dcas.filter.domain=uns.ewxdevel1dub.eionet.europa.eu" and "-Duns.url=https://uns.ewxdevel1dub.eionet.europa.eu/"
  In property uns.url use https as in the example.
- For configuring logging and viewing logs to an external application like graylog the file log4j2-gelf.xml should be created in directory opt/uns and the property "-Dlog4j.configurationFile=/opt/uns/log4j2-gelf.xml" should added in CATALINA_OPTS of tomcat service. An example of the file structure is shown below:
~~~
<Configuration>
  <Appenders>

    <Console name="console">
      <PatternLayout>
        <Pattern>[%p] [%c:%L] : %m%n</Pattern>
      </PatternLayout>
    </Console>

<!--
    <Gelf name="gelf" host="tcp:logserver.server"
          extractStackTrace="true" filterStackTrace="true" includeFullMdc="true">
      <Field name="Application" literal="UNS"/>
      <Field name="Timestamp" pattern="%d{dd MMM yyyy HH:mm:ss,SSS}" />
      <Field name="SimpleClassName" pattern="%C{1}" />
      <Field name="ClassName" pattern="%C"/>
      <Field name="LogLevel" pattern="%p"/>
      <Field name="Location" pattern="%l" />
    </Gelf>
-->
  </Appenders>

  <Loggers>
    <Root level="INFO">
      <!-- <AppenderRef ref="gelf" /> -->
      <AppenderRef ref="console" />
    </Root>
  </Loggers>

</Configuration>
~~~
- For a fully functional application the following properties in CATALINA_OPTS need to be configured with the appropriate values
1. LDAP communication
<pre>
    config.ldap.url
    config.ldap.principal
    config.ldap.password
</pre>
2. smtp configuration
<pre>
    smtp.host
</pre>
3. POP3 configuration 
<pre>
    pop3.adminMail
</pre>
