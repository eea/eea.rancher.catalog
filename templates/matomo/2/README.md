
# What is Matomo?

> Matomo is a free and open source web analytics application written by a team of international developers that runs on a PHP/MySQL webserver. It tracks online visits to one or more websites and displays reports on these visits for analysis. As of September 2015, Matomo was used by nearly 900 thousand websites, or 1.3% of all websites, and has been translated to more than 45 languages. New versions are regularly released every few weeks.

https://www.matomo.org/

# Prerequisites

To run this application you need [Docker Engine](https://www.docker.com/products/docker-engine) >= `1.10.0`. [Docker Compose](https://www.docker.com/products/docker-compose) is recommended with a version `1.6.0` or later.

# Instalation


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


### Database backup

On the mariadb container:


    $ mysqldump -p eea_matomo_db > /bitnami/sqldump.$(date +%F ).sql
      Enter password:

After you provide the root password, you will have the current database dump saved in the /bitnami volume.

Another solution is to use https://mariadb.com/kb/en/library/incremental-backup-and-restore-with-mariadb-backup/


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


# Configuration

## Environment variables

When you start the Matomo image, you can adjust the configuration of the instance by passing one or more environment variables either on the docker-compose file or on the docker run command line.

##### User and Site configuration

 - `MATOMO_USERNAME`: Matomo application username. Default: **User**
 - `MATOMO_HOST`: Matomo application host. Default: **127.0.0.1**
 - `MATOMO_PASSWORD`: Matomo application password. Default: **bitnami**
 - `MATOMO_EMAIL`: Matomo application email. Default: **user@example.com**
 - `MATOMO_WEBSITE_NAME`: Name of a website to track in Matomo. Default: **example**
 - `MATOMO_WEBSITE_HOST`: Website's host or domain to track in Matomo. Default: **https://example.org**

##### Use an existing database

- `MARIADB_HOST`: Hostname for MariaDB server. Default: **mariadb**
- `MARIADB_PORT_NUMBER`: Port used by MariaDB server. Default: **3306**
- `MATOMO_DATABASE_NAME`: Database name that Matomo will use to connect with the database. Default: **bitnami_matomo**
- `MATOMO_DATABASE_USER`: Database user that Matomo will use to connect with the database. Default: **bn_matomo**
- `MATOMO_DATABASE_PASSWORD`: Database password that Matomo will use to connect with the database. No defaults.
- `ALLOW_EMPTY_PASSWORD`: It can be used to allow blank passwords. Default: **no**

##### Create a database for Matomo using mysql-client

- `MARIADB_HOST`: Hostname for MariaDB server. Default: **mariadb**
- `MARIADB_PORT_NUMBER`: Port used by MariaDB server. Default: **3306**
- `MARIADB_ROOT_USER`: Database admin user. Default: **root**
- `MARIADB_ROOT_PASSWORD`: Database password for the `MARIADB_ROOT_USER` user. No defaults.
- `MYSQL_CLIENT_CREATE_DATABASE_NAME`: New database to be created by the mysql client module. No defaults.
- `MYSQL_CLIENT_CREATE_DATABASE_USER`: New database user to be created by the mysql client module. No defaults.
- `MYSQL_CLIENT_CREATE_DATABASE_PASSWORD`: Database password for the `MYSQL_CLIENT_CREATE_DATABASE_USER` user. No defaults.
- `ALLOW_EMPTY_PASSWORD`: It can be used to allow blank passwords. Default: **no**

