## EEA Taskman docker setup
Taskman is a web application based on [Redmine](http://www.redmine.org) that facilitates Agile project management for EEA and Eionet software projects. It comes with some plugins and specific Taskman Redmine theme.

### Taskman stack variables

1. REDMINE_SERVER_LABEL - Comma separated list of host labels (e.g. key1=value1, key2=value2) to be used for scheduling the taskman backend service.
1. REDMINE_FRONT_LABEL - Comma separated list of host labels (e.g. key1=value1, key2=value2) to be used for scheduling the apache service.
1. TASKMAN_DEV - Development/Testing installation. Choose no only for production environment
1. RESTART_CRON - Crontab schedule (for example 0 2 * * *) to stop redmine container, will be started by Rancher ( not recreated), not mandatory
1. EXPOSE_PORT - Port to expose Taskman. If left empty, will not be exposed on host
1. EXPOSE_PORT_MAIL - Port to expose mailtrap ( only works for development installation). If left empty, will not be exposed on host
1. INCOMING_MAIL_API_KEY - Incoming mail API key: Administration -> Settings -> Incoming email - API key
1. T_EMAIL_HOST - Taskman email configuration: hostname
1. T_EMAIL_PORT - Taskman email configuration: port
1. T_EMAIL_USER - Taskman email configuration: user
1. T_EMAIL_PASS - Taskman email configuration: user password
1. H_EMAIL_HOST - Helpdesk email configuration: hostname
1. H_EMAIL_PORT - Helpdesk email configuration: port
1. H_EMAIL_USER - Helpdesk email configuration: username
1. H_EMAIL_PASS - Helpdesk email configuration: user password
1. SYNC_API_KEY - GitHub synchronisation API KEY. Can be found under /settings?tab=repositories
1. PLUGINS_URL - Plugins location SVN URL. The SVN URL that point to the folder where the PRO plugins are located
1. PLUGINS_USER - Plugins SVN User. 
1. PLUGINS_PASSWORD - Plugins SVN User Password.
1. DB_NAME - Redmine Mysql database name. 
1. DB_USERNAME - Redmine database username. 
1. DB_PASSWORD - Redmine database user password. 
1. DB_ROOT_PASSWORD - Redmine database server root password.
1. DB_DUMP_TIME - Time to start database backup. UTC time, formatted as a 4 digit number
1. DB_DUMP_FREQ - Frequency of backup. Minutes between backups, set 1440 for daily
1. DB_DUMP_FILENAME - Database backup filename. The name of the database dump file
1. TZ - Time zone.
1. POSTFIX_RELAY - Postfix SMTP relay, not used in development mode
1. POSTFIX_PORT - Postfix SMTP relay port, not used in development mode
1. POSTFIX_USER - Postfix user used to send email, not used in development mode
1. POSTFIX_PASS - Postfix password used for MTP_USER, not used in development mode
1. APACHE_CONFIG - Apache configuration. Will be provided to the apache container, adding customized error messages
1. RDM_FILES_VOLUMEDRIVER - Redmine files volume driver.
1. RDM_GITHUB_VOLUMEDRIVER - Redmine github files volume driver.
1. REDMINE_SMALL_VOLUMEDRIVER - Redmine temporary and plugin archive volume driver.
1. MYSQL_VOLUMEDRIVER - MySQL data volume driver. 
1. MYSQL_VOLUMEDRIVER_OPTS - MySQL data volume driver options. Specify "driver_opts" key/value pair in the format "optionName: optionValue". E.g. for the `rancher-ebs` driver you should specify the required 'size' option like this: "size: 1".
1. MYSQL_BACKUP_VOLUMEDRIVER - MySQL backup data volume driver.


### Setting up Taskman development replica

1) Copy the .zip archives containing the paid plugins into an SVN folder

3) Add Taskman stack, using the development variable values ( special care with email configuration options)

4) Start the stack

4) If a development stack already exists, backup the database table `settings`. This should be done using the first step from the [restore procedure](#by-script)

4) Stop Redmine & MySQL services

5) Sync data from production:

    - Redmine files [Import Taskman files](https://github.com/eea/eea.docker.taskman#import-taskman-files)
    - MySQL database [Import Taskman database](https://github.com/eea/eea.docker.taskman#import-taskman-database)
    - Set development settings after a production [database restore](#set-development-settings-after-a-production)
    
6) Start Mysql

7) Give user administrator rights, if necessary. Execute shell on taskman-mysql-1 container.

        $ mysql -u<MYSQL_ROOT_USER> -p<MYSQL_ROOT_PASSWORD> <MYSQL_DB_NAME>           
        $ update users set admin=1 where login=<USER_NAME>;
        $ exit

11) Setup network and firewall to allow access of the devel host on the EEA email accounts.

    - Get <H_EMAIL_HOST> and <H_EMAIL_PORT> values from .email.secret file
    - Check 
    ```
    $ telnet <H_EMAIL_HOST> <H_EMAIL_PORT>
    ```
    - If telnet command unsuccesfull, create issue in Infrastructure project to solve this
   
9) Start Redmine services

### Set development settings after a production

#### By script

This script is an alternative to the manual restore steps described lower. Works for redmine > 4.1

1) **Before** the database restore, save the settings in a file:

       mysqldump --skip-add-drop-table --skip-add-locks --no-create-info --replace --user=root --password="$MYSQL_ROOT_PASSWORD" redmine settings --where="name in ('plugin_redmine_contacts','host_name', 'plugin_redmine_drawio', 'plugin_redmine_banner', 'mail_handler_api_key')" > /var/lib/mysql/export_settings.sql

2) **After** the database restore:

    - Create script to update ids in settings in case they were changed ( not likely, but it's important to keep them consistent) and run it 

          cd /var/lib/mysql/
          mysql -N --password="$MYSQL_ROOT_PASSWORD" redmine -e "select concat(\"sed -i \\\"s/([0-9]*,'\",name,\"'/(\",id,\",'\",name,\"'/g\\\" export_settings.sql\") from settings where name in ('plugin_redmine_contacts','host_name', 'plugin_redmine_drawio', 'plugin_redmine_banner', 'mail_handler_api_key');" > execute_id_replacement.sh
          chmod 755 execute_id_replacement.sh
          ./execute_id_replacement.sh

    - Run the update of the settings 

          mysql --password="$MYSQL_ROOT_PASSWORD" redmine < export_settings.sql

#### Manually from the taskman website

1) Disable helpdesk email accounts from the following Taskman projects ( needs to be done only if database was copied from production):

    - check via Redmine REST API where Helpdesk module is enabled
      - http://YOUR_TASKMAN_DEV_HOST/projects.xml?include=enabled_modules&limit=1000
        - <enabled_module id="111" name="contacts"/>
        - <enabled_module id="222" name="contacts_helpdesk"/>
      - currentlly the projects REST API is not showing all the projects. This are the known projects where the Helpdesk module is enabled:
        - zope (IDM2 A-Team)
        - it-helpdesk (IT Helpdesk)
        - ied (CWS support)
      - alternativelly you can connect to the MySQL server and do the following queries:
        - select * from enabled_modules where name='contacts_helpdesk';
        - select * from enabled_modules where name='contacts';
        - select identifier, name, id from projects where id in ( select project_id from enabled_modules where name='contacts_helpdesk' union all select project_id from enabled_modules where name='contacts');
        
    - delete *Incoming mail server* settings ( from *Mail server settings* )  from all projects excluding zope found in previous step using the following url: http://YOUR_TASKMAN_DEV_HOST:8080/projects/<PROJECT_IDENTIFIER>/settings/helpdesk 


9) If the database was copied from production, change the following settings to set-up the development mail account  :

    - http://YOUR_TASKMAN_DEV_HOST/projects/zope/settings/helpdesk :
        -  From address: support.taskmannt AT eea.europa.eu 
        -  User name: support.taskmannt AT eea.europa.eu
        -  Password  

    - http://YOUR_TASKMAN_DEV_HOST/settings/plugin/redmine_contacts_helpdesk?tab=general ( From address: support.taskmannt AT eea.europa.eu )
    - http://YOUR_TASKMAN_DEV_HOST/settings?tab=notifications ( Emission email address: taskmannt AT eionet.europa.eu )

10) If the database was copied from production, set the banner to  development message

    - http://YOUR_TASKMAN_DEV_HOST/settings/plugin/redmine_banner ( Banner message: This is a Taskman development replica, please do not use/login if you are not part of the development team.)
    
    
12) Change the following settings:

    - http://YOUR_TASKMAN_DEV_HOST/settings?tab=general ( Host name and path: YOUR_TASKMAN_DEV_HOST )
    

13) Update HELPDESK_EMAIL_KEY variable with API key:

    - add value from http://YOUR_TASKMAN_DEV_HOST/settings?tab=mail_handler, "API key" to HELPDESK_EMAIL_KEY
       

14) Test e-mails using mailtrap on the folowing address: http://YOUR_TASKMAN_DEV_HOST:EXPOSED_PORT


15) Configure drawio development url here: https:/YOUR_TASKMAN_DEV_HOST/settings/plugin/redmine_drawio ( needs to be done only if database was copied from production) 


### First time installation of the Taskman stack on Production

Add the certificate to rancher 

1) Copy the .zip archives containing the paid plugins into an SVN folder

3) Add Taskman stack, using the production variable values

4) Start the stack

5) Follow [import existing data](#import-existing-data) if you need to import existing data

6) Add a loadbalancer service to the taskman/apache service, using a certificate for https 

7) Configure drawio loadbalancer service to the taskman/drawio service, on port 8080, using a certificate for https

[Start updating Taskman](#upgrade-procedure) if you updated the Redmine version or if you updated the Redmine's plugins.

#### Import existing data

If you already have a Taskman installation then follow the steps below to import the files and mysql db into the data containers.

For rancher rsync instructions follow this [wiki](https://github.com/eea/eea.docker.rsync/blob/master/Readme.md#rsync-data-between-containers-in-rancher)

##### Import Taskman files

Copy Taskman files from one instance ( ex. production ) to another ( ex. replica) . For rancher, use the steps bellow and the  [wiki](https://github.com/eea/eea.docker.rsync/blob/master/Readme.md#rsync-data-between-containers-in-rancher)

1. Start **rsync client** on host from where do you want to migrate data (ex. production)

  ```
    $ docker run -it --rm --name=r-client \
                 --volumes-from=eeadockertaskman_redmine_1 \
             eeacms/rsync sh
  ```

2. Start **rsync server** on host from where do you want to migrate data (ex. devel)

  ```
    $ docker run -it --rm --name=r-server -p 2222:22 \
                 --volumes-from=eeadockertaskman_redmine_1 \
                 -e SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>" \
             eeacms/rsync server
  ```

3. Within **rsync client** container from step 1 run:

  ```
    $ rsync -e 'ssh -p 2222' -avz /usr/src/redmine/files/ root@<TARGET_HOST_IP_ON_DEVEL>:/usr/src/redmine/files/
  ```

4. Close **rsync client**

  ```
    $ CTRL+d
  ```

5. Close **rsync server**

  ```
    $ docker kill r-server
  ```

##### Import Taskman database

Replace the < MYSQL_ROOT_USER > and < MYSQL_ROOT_PASSWORD > with your values.

1. Make a dump of the database from source server.

  ```
    $ docker exec -it eeadockertaskman_mysql_1 bash
      $ mysqldump -u<MYSQL_ROOT_USER> -p --add-drop-table <MYSQL_DB_NAME> > /var/local/backup/taskman.sql
      <MYSQL_ROOT_PASSWORD> 
      $ exit
  ```

2. Start **rsync client** on source server

  ```
    $ docker run -it --rm --name=r-client \
                 --volumes-from=eeadockertaskman_mysql_1 \
             eeacms/rsync sh
  ```

3. Start **mysql** and the **rsync server** on destination server

> The eeadockertaskman_mysql_1 container must be started, check documentation for start command

> <SSH-KEY-FROM-R-CLIENT-ABOVE> must contain "ssh-rsa ..."

  ```
    $ docker run -it --rm --name=r-server -p 2222:22 \
                 --volumes-from=eeadockertaskman_mysql_1 \
                 -e SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>" \
             eeacms/rsync server
  ```

4. Sync mysql dump. Within **rsync client** container from step 2 (source server) run:

  ```
    $ scp -P 2222 /var/local/backup/taskman.sql root@<TARGET_HOST_IP_ON_DEVEL>:/var/local/backup/
    $ exit
  ```
  
5. Close **rsync client**

  ```
    $ CTRL+d
  ```
  
6. Import the dump file (on destination server)

  ```
    $ docker exec -it eeadockertaskman_mysql_1 bash
     $ mysql -u<MYSQL_ROOT_USER> -p <MYSQL_DB_NAME> < /var/local/backup/taskman.sql
     <MYSQL_ROOT_PASSWORD>
     $ exit
  ```

7. Close **rsync server**

  ```
    $ docker kill r-server
  ```

#### Email settings - tested on Development/Testing installation

**IMPORTANT:** test first if the email notification are sent!
Use first time the email development accounts.

Features to be tested:

* create ticket via email
* create ticket for Helpdesk
* receive email notification on content update
* email issue reminder notification

Verify in mailtrap if the emails are sent correctly.

### Upgrade procedure

1) Create new release in Rancher Catalog Taskman.

1) Make a backup of database - Run on mysql container

       $ mysqldump -u<MYSQL_ROOT_USER> -p<MYSQL_ROOT_PASSWORD> --add-drop-table <MYSQL_DB_NAME> > /var/local/backup/taskman.sql
      
1) If possible, pull latest version of Redmine to minimize waiting time during the next step

       $ docker pull eeacms/redmine:<imagetag>

1) Backup existing plugins and remove them from SVN directory

1) Upgrade the Taskman stack to the new version, making sure the variables are correct.


#### Upgrade Redmine version

Start updating Taskman ( if necessary - by default, `gosu redmine rake db:migrate` is run on start )

    $ docker exec -it eeadockertaskman_redmine_1 bash
    $ bundle exec rake db:migrate RAILS_ENV=production

If required by the migrate, run 

    $ bundle install

Finish upgrade

    $ bundle exec rake tmp:cache:clear tmp:sessions:clear RAILS_ENV=production

Restart Redmine service

#### Upgrade plugins

1. For free plugins, you need to modify Dockerfile. For paid ones, you need to add them to the SVN folder, and modify plugins.cfg file in Redmine.

2. Create a new Redmine image

3. Add a new template in Taskman Rancher Catalog with the new image

4. Upgrade it on the development replica and test it

5. Upgrade on the production


#### Manual Upgrade Redmine's plugins (not recommended)
    
Copy the source code to the plugins directory in Redmine, then run:    

    $ bundle install --without development test
    $ bundle exec rake redmine:plugins:migrate RAILS_ENV=production

## How-tos
### How to add repository to Redmine

*Prerequisites*: You have "Manager"/"Product Owner"-role in your <Project>.

1) Within Redmine Web Interface of your project: Settings > Repositories > Add new repository

    - SCM: Git
    - Identifier: eea-mypackage
    - Path to repository: /var/local/redmine/github/eea.mypackage.git

<pre>
All local repositories within */var/local/redmine/github* folder are synced automatically
from https://github.com/eea every 5 minutes (see */etc/chaperone.d/chaperone.conf* and
*/var/local/redmine/crons/redmine_github_sync.sh*) so you don't have to add them manually on server side.
</pre>

2) Update users mapping for your new repository:

    - Within Redmine Web Interface > Projects > <Project> > Settings > Repositories click on *Users* link available for your new repository and Update missing users

If it still doesn't update automatically after a while:

* login to the docker host and become root
* enter the Redmine container (docker exec -it eeadockertaskman_redmine_1 bash)
* cd /var/local/redmine/github
* git clone --mirror https://github.com/eea/eea.mypackage.git
* cd eea.mypackage.git
* git fetch --all
* chown -R apache.apache .

You can "read more":http://www.redmine.org/projects/redmine/wiki/HowTo_keep_in_sync_your_git_repository_for_redmine

### How to add check Redmine's logs

Use [Graylog](https://logs.eea.europa.eu/)


### How to manually sync LDAP users/groups

If you want to manually sync LDAP users and/or groups you need to run the following rake command inside the Redmine container:

    $ bundle exec rake -T redmine:plugins:ldap_sync

For more info see the [LDAP sync documentation](https://github.com/eea/redmine_ldap_sync#rake-tasks)


### How to uninstall Redmine Premium plugins

On Redmine container:

    $ bundle exec rake redmine:plugins:migrate NAME=redmine_plugin-name VERSION=0 RAILS_ENV=production

Remove it from configuration file ( plugins.cfg ), follow the upgrade [steps])(#upgrade-plugins)

### How to uninstall Redmine plugins

1) Uninstall plugin 

       $ bundle exec rake redmine:plugins:migrate NAME=redmine_plugin-name VERSION=0 RAILS_ENV=production
     
2) Remove the plugin from docker image, follow the upgrade [steps])(#upgrade-plugins)

### How to make changes on Taskman theme

Under Redmine container follow the next steps:

1) Upgrade the current packages to the latest version.
```
apt update
apt-get install curl
```
2) Installing Node.js
```
apt-get install software-properties-common
curl -sL https://deb.nodesource.com/setup_8.x | bash -
apt-get install nodejs npm
```
3) Make sure you have successfully installed node.js and npm on your system
```
node --version
npm --version
```
4) Install Grunt
```
npm install -g grunt
```
5) This will install Grunt globally on your system. Run command to check the version installed on your system.
```
grunt --version
```

After you installed node, npm and grunt, under Redmine theme follow the next steps:
1) Install project dependencies
```
npm install
```
2) Run Grunt
```
grunt
```

### Specific plugins documentation

* [Agile plugin](http://www.redminecrm.com/projects/agile/pages/1).
* [Checklists plugin](https://www.redminecrm.com/projects/checklist/pages/1).
* [LDAP Sync plugin](https://github.com/eea/redmine_ldap_sync).
