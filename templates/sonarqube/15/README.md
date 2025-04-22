## What is inside SonarQube Stack?
* [SonarQube Server](http://www.sonarqube.org/)
* Postgres Database

## Installing Plugins Manually
* Go to [Plugin Library](http://docs.sonarqube.org/display/PLUG/Plugin+Library) and find your favourite plugins
* On the SonarQube container, go to /opt/sonarqube/extensions/plugins and put your plugins here
* Restart SonarQube container.

## First Start
* Use admin/admin to login to the SonarQube interface.

## Variables

- *SonarQube web jvm options* - used on SonarQube application
- *Sonarqube database name* - used by SonarQube 
- *Sonarqube database user* - the user used by SonarQube to connect to the database
- *Sonarqube database password* - the password used by SonarQube to connect to the database
- *Postgres SuperUser*, *Postgres SuperUser Password* - the Postgres user credentials with administrative access
- *Schedule Sonarqube services on hosts with following host labels* - Comma separated list of host labels (e.g. key1=value1,key2=value2) to be used for scheduling Sonarqube
- *Schedule database on hosts with following host labels* - Comma separated list of host labels (e.g. key1=value1,key2=value2) to be used for scheduling Postgres
- *Database data volume driver* - default local
- *Database data volume driver options* - used in rancher_ebs volumes to set size
- *Sonarqube services volumes' driver* - default local
- *Sonarqube services volumes' driver options* -  used in rancher_ebs volumes to set size
- *Time zone* - default `Europe/Copenhagen`

### Postfix variables

- `SonarQube server name` - used in Postfix to send emails
- `Postfix relay` - Postfix SMTP relay
- `Postfix relay port` - Postfix SMTP relay port
- `Postfix user` - SMTP user
- `Postfix password` - SMTP user password


## Rancher LB

This service should be exposed in rancher lb:

- sonarqube:9000

## Upgrade

The official documentation is: https://docs.sonarqube.org/latest/setup/upgrading/
Because we are using docker, we only need to access http://yourSonarQubeServerURL/setup  to finish the upgrade.



