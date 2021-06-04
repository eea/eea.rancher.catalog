## Stack configuration

The following properties are mandatory for creating the stack:
<pre>
Datadict MySQL volume
MYSQL Volume driver
Datadict files volume
Files Volume driver
Data2rdf volume
Data2rdf Volume driver
Database name
Database password
Database root password
Database user
CATALINA_OPTS
Tomcat memory limit
Tomcat memory reservation
dbservice memory limit
dbservice memory reservation
buildsw memory limit
buildsw memory reservation
dd_rsynch memory limit
dd-rsynch memory reservation
</pre>

- 3 storages should be created before launching the stack, one for storing files (Datadict files volume), one for database (Datadict MySQL volume) and one for data2rdf (Data2rdf volume) and they should be put in the respective stack properties.
- A mail stack should exist in order to be configured in external_links of tomcat service.
- Default values for services memoryLimit and memoryReservation have been set. These values can be increased according to needs. 
- In CATALINA_OPTS the following properties should be set for the stack to startup. The values that were set in previous properties should be placed.
<pre>
"-Xmx6144m"
"-Dlog4j.configurationFile=/opt/datadict/log4j2.xml"
"-Djava.security.egd=file:/dev/./urandom"
"-Denv.app.home=/opt/datadict"
"-Denv.db.driver=com.mysql.jdbc.Driver"
"-Denv.db.jdbcurl=jdbc:mysql://dbservice:3306/databaseName?maxAllowedPacket=16106127360&autoReconnect=true&useUnicode=true&characterEncoding=UTF-8&emptyStringsConvertToZero=false&jdbcCompliantTruncation=false&rewriteBatchedStatements=true"
"-Denv.db.jdbcurl.encoded=jdbc:mysql://dbservice:3306/databaseName?maxAllowedPacket=16106127360&amp;autoReconnect=true&amp;useUnicode=true&amp;characterEncoding=UTF-8&amp;emptyStringsConvertToZero=false&amp;jdbcCompliantTruncation=false&amp;rewriteBatchedStatements=true"
"-Denv.db.user=databaseUser"
"-Denv.db.password=databasePassword"
"-Denv.dd.vocabulary.api.jwt.timeout=10000"  
"-Denv.mysql.url=jdbc:mysql://dbservice:3306/mysql?maxAllowedPacket=16106127360&autoReconnect=true&useUnicode=true&characterEncoding=UTF-8&emptyStringsConvertToZero=false&jdbcCompliantTruncation=false&rewriteBatchedStatements=true"
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one in the order they appear from top to bottom. 
- After starting service dbservice and before starting tomcat service, in the container of dbservice select "Execute Shell" and run following commands providing the values that you specified in previous steps:
<pre>
$ mysql -u root -p
$ enter "Database root password" you specified in previous step
$ CREATE USER 'databaseUser'@'localhost' IDENTIFIED BY 'databasePassword';
$ GRANT ALL PRIVILEGES ON * . * TO 'databaseUser'@'%';
$ FLUSH PRIVILEGES;
</pre>
- Create a new service rule in load balancer specifying the application url.
- Upgrade tomcat service adding in CATALINA_OPTS the properties env.dd.host and env.dd.url with the url that you specicied in previous step e.g "-Denv.dd.host=dd.ewxdevel1dub.eionet.europa.eu" and "-Denv.dd.url=http://dd.ewxdevel1dub.eionet.europa.eu"
- For a fully functional application the following properties in CATALINA_OPTS may need to be set with the appropriate values
1. LDAP communication
    <pre>
        env.ldap.url
        env.ldap.principal
        env.ldap.password
        env.ldap.context
        env.ldap.role.dir
        env.ldap.user.dir
    </pre>
2. Converters communication
    <pre>
        env.xmlConv.url
    </pre>
3. Cr communication
    <pre>
        env.cr.reharvest.request.url
    </pre>
4. UNS communication
    <pre>
        env.uns.xml.rpc.server.url
        env.uns.channel.name
    </pre>
5. Site code allocation
    <pre>
        env.siteCode.allocate.notification.to
        env.siteCode.reserve.notification.to
        env.siteCode.notification.from
        env.siteCode.allocate.maxAmount
        env.siteCode.allocate.maxAmountWithoutName
        env.siteCode.allocate.maxAmountForEtcEeaUsers
        env.siteCode.reserve.maxAmount
        env.siteCode.test.notification.to
    </pre>
6. Notification in case of error for vocabulary schedule synchronization
    <pre>
        env.notification.email.from
    </pre>
7. Email setup
    <pre>
        env.smtp.host
    </pre>
