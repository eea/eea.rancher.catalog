# What is Nextcloud?


Nextcloud is free and open-source suite of client-server software for creating and using file hosting services.


## Why is this so awesome? 


* **Access your Data** You can store your files, contacts, calendars and more on a server of your choosing.
* **Sync your Data** You keep your files, contacts, calendars and more synchronized amongst your devices.
* **Share your Data** …by giving others access to the stuff you want them to see or to collaborate with.
* **Expandable with hundreds of Apps** ...like [Calendar](https://github.com/nextcloud/calendar), [Contacts](https://github.com/nextcloud/contacts), [Mail](https://github.com/nextcloud/mail), [Video Chat](https://github.com/nextcloud/spreed) and all those you can discover in our [App Store](https://apps.nextcloud.com)
* **Security** with our encryption mechanisms, [HackerOne bounty program](https://hackerone.com/nextcloud) and two-factor authentication.

## Documentation


Quicklinks:

- https://docs.nextcloud.com/server/16/admin_manual/index.html
- https://github.com/nextcloud/docker
- https://github.com/nextcloud/server

## Stack variables


- **Nextcloud database name** - MariaDB database name
- **Nextcloud database username** - MariaDB application user name
- **Nextcloud database user password** - MariaDB application user password
- **Nextcloud database server root password** - MariaDB root password
- **Time zone** -  Set on all containers
- **Postfix hostname** - Used in postfix configuration
- **Postfix relay** - Use the default value
- **Postfix relay port** - Use the default value
- **Postfix user** - Specific to application, used on SMTP relay
- **Postfix password** - Specific to application, used on SMTP relay
- **Nextcloud server memory reservation & limit**, **Nextcloud crontab  memory reservation & limit**, **MariaDB memory reservation & limit**, **Redis memory reservation**, **Redis memory limit** - used to setup memory reservations and limits in rancher, make sure you are setting enough for your needs   
- **All stack volumes are external** - Yes for production, choose No for fast deploy on dev
- **MySQL data volume name**, **Nextcloud share data volume name**, **Nextcloud application data volume name**, **Nextcloud php configuration volume name**, **Redis data volume name** - if external, create the volumes before the stack. If you are using netapp/rancher-ebs you need to set size to be enough for your needs. 
- **MySQL data volume driver**, **Nextcloud share data volume driver**, **Nextcloud application data volume driver**, **Nextcloud php configuration volume driver**, **Redis data volume driver** - ignored if volumes are external


## Deploy

1. Create external volumes ( Rancher Storage )
2. Deploy stack
3. Configure values in */var/www/html/config/config.php*
4. Add rancher LB entry
5. Enter web page, create administrator user
5. Configure security on Rancher LB

### Rancher LB

We have the following services that should be exposed in rancher lb:

- nginx:80

Also, according to the security guidelines:https://docs.nextcloud.com/server/16/admin_manual/installation/harden_server.html , you need to set up the backend in the custom haproxy.cfg :

```
backend nextcloud
  http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
  http-response set-header X-Content-Type-Options "nosniff"
  http-response set-header X-XSS-Protection "1; mode=block"
  http-response set-header X-Robots-Tag "none"
  http-response set-header X-Frame-Options "SAMEORIGIN"
  http-response set-header Referrer-Policy "no-referrer"

  http-request set-path %[path,regsub(^/.well-known/carddav,/remote.php/dav,)]  if { path path_beg /.well-known/carddav }
  http-request set-path %[path,regsub(^/.well-known/caldav,/remote.php/dav,)]  if { path path_beg /.well-known/caldav } 
  http-request set-path %[path,regsub(^/.well-known/webfinger,/public.php?service=webfinger,)]  if { path path_beg /.well-known/webfinger }
  ```


### Configuration

You need to wait until the app container creates the */var/www/html/config* directory ( after installation )

Needs to be configured in the app volume ( */var/www/html/config/config.php* ) , then restart both app and cron containers

Documentation: https://docs.nextcloud.com/server/16/admin_manual/configuration_server/config_sample_php_parameters.html

Detailed explanation for each field: https://github.com/nextcloud/server/blob/stable16/config/config.sample.php

#### To set the correct data directory

    'datadirectory' => '/data/share',

Also, you need to set up the correct permissions for the application to run correctly:

     mkdir /data/share
     chown www-data:www-data /data/share
     chmod 0770 /data/share/
     sed -i "/instanceid/a\  'datadirectory' => '/data/share'," /var/www/html/config/config.php

#### To force https

    'overwriteprotocol' => 'https',

#### To have empty share directory for new users 

    'skeletondirectory' => '',

#### To configure LDAP

    'ldapIgnoreNamingRules' => false,
    'ldapProviderFactory' => 'OCA\\User_LDAP\\LDAPProviderFactory',
    'lost_password_link' => 'disabled',
    'simpleSignUpLink.shown' => false,

#### To configure email

Can be configured from the website - "/settings/admin"

    'mail_smtpmode' => 'smtp',
    'mail_smtphost' => 'postfix',
    'mail_sendmailmode' => 'smtp',
    'mail_smtpport' => '25',
    'mail_domain' => '<DOMAIN>',
    'mail_from_address' => '<FROM>',

#### To edit the php configuration

The php configuration is stored in **/usr/local/etc/php/conf.d/**.

#### To run occ commands

Use `su www-data -s` :

     su www-data -s occ db:convert-filecache-bigint
     
     
### Upgrade

1. Stop cron service
2. Manually upgrade app service to latest minor version ( same major version), temporary disable healthcheck and memory limit to not have interruptions during upgrades
3. Check nextcloud website - `/settings/admin/overview`
4. Upgrade stack ( this will reset the healtchecks and memory settings to default values ) 

