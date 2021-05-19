## Stack configuration

The following properties are mandatory for creating the stack:
Database name, Database password, Database root password, Database user, Tomcat memory limit, Tomcat memory reservation, CATALINA_OPTS, Converters files volume, Converters MySQL volume,
Files Volumes driver, MYSQL Volumes driver.
- 2 storages should be created before launching the stack, one for storing files (Converters files volume) and one for database (Converters MySQL volume) and they should be put in the respective stack properties.
- A default value of 1024MB has been set for memoryLimit and memoryReservation. These values can be increased according to needs. 
- In CATALINA_OPTS the following properties should be set for the stack to startup. We used some indicative values. The values that were set in previous properties should be placed.
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
"-Dquartz.db.url=jdbc:mysql://dbservice:3306/quartz?autoReconnect=true&amp;characterEncoding=UTF-8&amp;emptyStringsConvertToZero=false&amp;jdbcCompliantTruncation=false" 
"-Dquartz.db.user=databaseUser" 
"-Dquartz.db.pwd=databasePassword" 
"-Dconfig.hostname=$HOSTNAME" 
</pre>

- When all properties are set, uncheck box "Start services after creating" and press "Launch". 
- Start the services of the stack one by one. The service converters-rsynch is not needed for the application to startup.
- After starting service dbservice, simply run:

create schema quartz; (name should be the one used in quartz.db.url)


