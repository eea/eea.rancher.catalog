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
- **MySQL data volume name, external**, **Nextcloud share data volume name, external**, **Nextcloud application data volume name, external**, **Redis data volume name, external** - create the volumes before the stack. If you are using netapp/rancher-ebs you need to set size to be enough for your needs. 
- **MySQL data volume driver**, **Nextcloud share data volume driver**, **Nextcloud application data volume driver**, **Redis data volume driver** - choose the same driver you used on volume creation ( Rancher Storage page )

## Deploy

1. Create volumes ( Rancher Storage )
2. Deploy stack
3. Configure values in */var/www/html/config/config.php*
4. Add rancher LB entry
5. Enter web page, create administrator user

### Rancher LB

We have the following services that should be exposed in rancher lb:

- app:80

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

    'mail_smtpmode' => 'smtp',
    'mail_smtphost' => 'postfix',
    'mail_sendmailmode' => 'smtp',
    'mail_smtpport' => '25',
    'mail_domain' => '<DOMAIN>',
    'mail_from_address' => '<FROM>',


