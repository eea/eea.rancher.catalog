## Stack configuration

The following properties are mandatory for creating the stack:
<pre>
Uns files volume
Uns MySQL volume
Files Volumes driver
MYSQL Volumes driver
Database name
Database password
Database root password
Database user
CATALINA_OPTS
dbservice memory reservation
Tomcat memory reservation
mailservice LOGSPOUT
mailservice MTP_HOST
mailservice MTP_PASS
mailservice MTP_PORT
mailservice MTP_RELAY
mailservice MTP_USER
administration memory limit
administration memory reservation
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
- Start the services of the stack one by one in the order they appear from top to bottom. The service rsync-dev is not needed for the application to startup.
- After starting service dbservice and before starting tomcat service, in the container of dbservice select "Execute Shell" and run following commands:
<pre>
$ mysql -u root -p
$ enter "Database root password" you specified in previous step
$ CREATE USER 'databaseUser'@'localhost' IDENTIFIED BY 'databasePassword';
$ GRANT ALL PRIVILEGES ON * . * TO 'databaseUser'@'%';
$ FLUSH PRIVILEGES;
</pre>
- Create 2 new service rules in load balancer specifying the application url, one with protocol http and one with protocol https.
- Upgrade tomcat service adding in CATALINA_OPTS the properties cas.filter.serverName, cas.filter.domain and uns.url with the url that you specicied in previous step e.g "-Dcas.filter.serverName=uns.ewxdevel1dub.eionet.europa.eu", "-Dcas.filter.domain=uns.ewxdevel1dub.eionet.europa.eu" and "-Duns.url=https://uns.ewxdevel1dub.eionet.europa.eu/"
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
3. POP3 configuration for retrieving failed e-mail notifications
<pre>
    pop3.adminMail
</pre>
