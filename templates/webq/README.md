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
     "-Dlog4j.configuration=file:/opt/config/log4j.xml"
     "-Djava.security.egd=file:/dev/./urandom"
     "-Ddb.url=jdbc:mysql://webqproddb:3306/dataabaseName?maxAllowedPacket=32212254720"
     "-Ddb.driver=com.mysql.jdbc.Driver"
     "-Ddb.username=databaseUser"
     "-Ddb.password=databasePassword"
     "-Duser.file.expiration.hours=72"
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one in the order they appear from top to bottom. The service rsync-dev is not needed for the application to startup.
- After starting service webqproddb and before starting appl service, in the container of webqproddb select "Execute Shell" and run following commands:
<pre>
$ mysql -u root -p
$ enter "Database root password" you specified in previous step
$ CREATE USER 'databaseUser'@'localhost' IDENTIFIED BY 'databasePassword';
$ GRANT ALL PRIVILEGES ON * . * TO 'databaseUser'@'%';
$ FLUSH PRIVILEGES;
</pre>
Furthermore the user's eionet username and password '' must be inserted in the 'users' table.
and the user's username and authority (e.g. 'ADMIN') must be inserted in the 'authorities' table.
- Create new service rule in load balancer specifying the application url.
- Upgrade tomcat service adding in CATALINA_OPTS the property cas.service with the url that you specicied in previous step e.g "-Dcas.service=https://webforms.ewxdevel1dub.eionet.europa.eu"
- For a fully functional application the following property in CATALINA_OPTS needs to be configured with the appropriate value:
<pre>
    converters.api.url
</pre>

