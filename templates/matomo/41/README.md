
# What is Matomo?

> Matomo is a free and open source web analytics application written by a team of international developers that runs on a PHP/MySQL webserver. It tracks online visits to one or more websites and displays reports on these visits for analysis. As of September 2015, Matomo was used by nearly 900 thousand websites, or 1.3% of all websites, and has been translated to more than 45 languages. New versions are regularly released every few weeks.

https://www.matomo.org/

# Prerequisites

To run this application you need [Docker Engine](https://www.docker.com/products/docker-engine) >= `1.10.0`. [Docker Compose](https://www.docker.com/products/docker-compose) is recommended with a version `1.6.0` or later.

# Installation

## Configuration
- `Matomo url` - Matomo url, used in the reports archiving job and analytics job
- `Mariadb username` - User used by matomo to connect to the database
- `Mariadb database` - Database used by matomo to store data
- `Mariadb database password` - Password used by matomo to connect to the database
- `Mariadb root password` - root user password on mariadb database
- `Allow empty password` - choose YES to not use passwords for mariadb and matomo ( only for development purposes )
- `Number of Matomo containers` - default number of matomo containers in cluster
- `Schedule Mariadb on hosts with following host labels` - Comma separated list of host labels (e.g. key1=value1, key2=value2) to be used for scheduling the Mariadb service. If the database uses a local volume, the container MUST be fixed on one host.
- `Schedule Matomo services on hosts with following host labels, blank for any` - default empty, do not use this unless you want to control matomo container location
- `Schedule Matomo Analytics (LOGS import)  serviceson hosts with following host labels, blank for any` - default empty, do not use this unless you want to control matomo analytics containers location
- `Matomo authentification token from a privileged user` - used to import data from web server logs, can be copied from `Personal settings` ( click `Administration` )
- `Rsync commands, separated by ;` - Will be run in container, using sh -C "<RSYNC_COMMANDS>"
- `Matomo server name` - used in Postfix to send emails
- `Postfix relay` - Postfix SMTP relay
- `Postfix relay port` - Postfix SMTP relay port
- `Postfix user` - SMTP user
- `Postfix password` - SMTP user password
- `Time zone` - Timezone set on all servers
- `Fix mariadb local volume location` - When you want to use a specified path for the Mariadb data volume, database must be fixed using `Schedule Mariadb on hosts with following host labels`
- `Mariadb Volume Storage Driver` - preferable 'local' or 'netapp' 
- `Matomo Volume Storage Driver` - must be shared on all Matomo containers
- `Matomo Misc Volume Storage Driver` - must be shared on all Matomo containers
- `Matomo Analytics Logs Volume Storage Driver` - must be shared on all Matomo analytics containers
- `Rsync Client SSH keys Storage Driver` - use local only if you are scheduling the container on only one host, otherwise use a shared volume
- `Mariadb Storage Driver Option (Optional)`, `Matomo Storage Driver Option (Optional)`, `Matomo Storage Driver Option (Optional)`, `Matomo Analytics Logs Storage Driver Option (Optional)`, `Rsync Client SSH keys Storage Driver Option (Optional)` - used for rancher_ebs to declare size


# Backup & recovery

## Backup

Before any major changes on the matomo application, you need to backup the configuration, the database and, if applicable, the plugins.

### Configuration backup

On any matomo container:

     $ cp /bitnami/matomo/config/config.ini.php /bitnami/backup/config.ini.php.$( date +%F )

or, if you prefer to have the time included:

     $ cp /bitnami/matomo/config/config.ini.php /bitnami/backup/config.ini.php.$( date +%F.%T ) 

### Plugins backup

On any matomo container:

     $ cp -r /bitnami/matomo/plugins /bitnami/plugins.$( date +%F )

or, if you prefer to have the time included:

     $ cp -r /bitnami/matomo/plugins /bitnami/plugins.$( date +%F.%T )



### Lock database ( enable maintenance mode)

To stop all writing in the database you need to:

#### *Disable tracking* - no new pages will be added to matomo. 


This needs to be present in the configuration:

```
             [Tracker]
             record_statistics = 0
```

The `record_statistics` line was added in the configuration with the default value(1) to make it's disabling easier:

     $ sed -i 's/^record_statistics.*/record_statistics = 0/' /bitnami/matomo/config/config.ini.php
     $ grep record_statistics /bitnami/matomo/config/config.ini.php

#### *Disable UI* - the UI will have a maintenance message so it will not be available.

This needs to be present in the configuration:

```
             [General]
             maintenance_mode = 1
```

The `maintenance_mode` line was added in the configuration with the default value (0) to make it's disabling easier:

     $ sed -i 's/^maintenance_mode.*/maintenance_mode = 1/' /bitnami/matomo/config/config.ini.php
     $ grep maintenance_mode /bitnami/matomo/config/config.ini.php

#### *Restart* the container(s) to apply the change.

#### Check

- *Tracking* - `/piwik.php` will respond with HTTP 503
- *UI* - `/index.php?module=API&method=API.getPiwikVersion`  will respond with HTTP 503


### Database backup -

On the mariadb container:


    $ mysqldump -p eea_matomo_db > /bitnami/sqldump.$(date +%F ).sql
      Enter password:

After you provide the root password, you will have the current database dump saved in the /bitnami volume.

Another solution is to use `rsync` on the /bitnami volume -  https://mariadb.com/kb/en/library/incremental-backup-and-restore-with-mariadb-backup/ or `mariabackup` utility - https://mariadb.com/kb/en/library/incremental-backup-and-restore-with-mariadb-backup/ 


## Recovery

### Database restore

#### Empty database, if necessary

On the mariadb container:

   $ mysql -p
     $ drop database eea_matomo_db;
     $ create database eea_matomo_db;

#### Restore database:

On the mariadb container:

   $ mysql -p eea_matomo_db < /bitnami/sqldump.<DATE>.sql

### Restore matomo data

When making changes in the /bitnami directory in the container, make sure that the correct permisions are given:

    $ chmod -R 755 /bitnami
    $ chown -R daemon:daemon /bitnami


#### Restore configuration

Matomo configuration is stored in `/bitnami/matomo/config/config.ini.php`. If you changed any configuration regarding the database connection, you will need to manually update the restored file.

#### Restore other matomo data

1. Plugins - plugins are saved in `/bitnami/matomo/plugins` directory 
2. Logo - the logo files are saved in `/opt/bitnami/matomo/misc/user`
3. Geolite database - either you download it manually, or restore it in `/opt/bitnami/matomo/misc` ( this location is  a volume )

### Disable maintenace mode - enable database writing

#### *Enable tracking* - new pages will be added to matomo.

This should to be present in the configuration:

```
             [Tracker]
             record_statistics = 1
```

The `record_statistics` line was added in the configuration with the default value(1) to make it's enabling/disabling easier:

     $ sed -i 's/^record_statistics.*/record_statistics = 1/' /bitnami/matomo/config/config.ini.php
     $ grep record_statistics /bitnami/matomo/config/config.ini.php

#### *Enable UI* - the UI will be available.

This should to be present in the configuration:

```
             [General]
             maintenance_mode = 0
```

The `maintenance_mode` line was added in the configuration with the default value (0) to make it's disabling easier:

     $ sed -i 's/^maintenance_mode.*/maintenance_mode = 1/' /bitnami/matomo/config/config.ini.php
     $ grep maintenance_mode /bitnami/matomo/config/config.ini.php

#### *Restart* the container(s) to apply the change.

#### Check 

- *Tracking* - `/piwik.php` will respond with HTTP 200
- *UI* - `/index.php?module=API&method=API.getPiwikVersion`  will respond with HTTP 200

# Upgrading Matomo

## Backup mandatory
You need to do a backup to the matomo files and database before the upgrade so you will be able to rollback in case of a problem. If the upgrade does database changes, the older version of matomo container will not be able to run with the newer version of the database.

## Manual upgrade
Because of the way we are keeping some of the matomo files in volumes, only manual upgrade can be done, otherwise the files from the volumes will not be updated correctly. If you have multiple containers for matomo, you will need to reduce them to one, and increase this only after the rancher/docker upgrade is done.

## Rancher upgrade

You should upgrade the stack as usual

## Rollback 

It might not be enough to do a rancher rollback to restore the previous version of the application. You might need to restore both database and Matomo files from volumes.



Additionally, [snapshot the MariaDB data](https://github.com/bitnami/bitnami-docker-mariadb#step-2-stop-and-backup-the-currently-running-container)

# Miscelanious

## Setting up log import flows

### Create a generic user that will be used to import logs, skip if already exists
Note the user name and password.

### Create separate site to import the logs to
Note the new site id, it will be used in the job configuration. Give the analytics user *write* access to it

### Prepare a remote rsync server with access to the logs
Make sure you add the ssh key from the existing *rsync-analytics* to the rsync server ( can be seen in docker logs). Note the location of the logs. Make sure you have access to it from the *rsync-analytics* container. Test:
     $ ssh -p 2222 <IP>


### Modify the exising Rsync commands variable to include the new flow
Add a new shell command. Should be in  the format:
     rsync -e 'ssh -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' -avz --delete root@<IP>:<LOG_LOCATION_REMOTE> /analytics/logs/<NEW_SITE_ID>
   
   This command will be run every hour, make sure that the rsync server does not take the current, incomplete log.

### Matomo log import
https://github.com/eea/eea.docker.matomo-log-analytics
You don't need to change anything on this container, it should work by having the logs located in the new <SITE_ID> directory. This job will run every hour and will import all unprocessed ( or unsuccesfully processed) logs found in /analytics/logs/<SITE>/*




