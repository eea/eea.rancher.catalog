## EEA Taskman docker setup
Taskman is a web application based on [Redmine](http://www.redmine.org) that facilitates Agile project management for EEA and Eionet software projects. It comes with some plugins and specific Eionet redmine theme.

### Taskman stack variables


### Setting up Taskman development replica

1) Copy the .zip archives containing the paid plugins into an SVN folder

3) Add Taskman stack, using the development variable values

4) Start the stack

4) Stop Redmine & MySQL services

5) Sync data from production:

    - Redmine files [Import Taskman files](https://github.com/eea/eea.docker.taskman#import-taskman-files)
    - MySQL database [Import Taskman database](https://github.com/eea/eea.docker.taskman#import-taskman-database)
    

6)  Start Mysql and Redmine services
 

7) Give user administrator rights, if necessary. Execute shell on taskman-mysql-1 container.

        $ mysql -u<MYSQL_ROOT_USER> -p<MYSQL_ROOT_PASSWORD> <MYSQL_DB_NAME>           
        $ update users set admin=1 where login=<USER_NAME>;
        $ exit

8) Disable helpdesk email accounts from the following Taskman projects ( needs to be done only if database was copied from production):

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
        - select identifier, name, id from projects where id in ( select project_id from enabled_modules where name='contacts_helpdesk' union all select project_id from enabled_modules where name='contacts_helpdesk');
        
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
    
    
11) Setup network and firewall to allow access of the devel host on the EEA email accounts.

    - Get <H_EMAIL_HOST> and <H_EMAIL_PORT> values from .email.secret file
    - Check 
    ```
    $ telnet <H_EMAIL_HOST> <H_EMAIL_PORT>
    ```
    - If telnet command unsuccesfull, create issue in Infrastructure project to solve this
   
12) Change the following settings:

    - http://YOUR_TASKMAN_DEV_HOST/settings?tab=general ( Host name and path: YOUR_TASKMAN_DEV_HOST )
    

13) Update HELPDESK_EMAIL_KEY variable with API key:

    - add value from http://YOUR_TASKMAN_DEV_HOST/settings?tab=mail_handler, "API key" to HELPDESK_EMAIL_KEY
       

14) Test e-mails using mailtrap on the folowing address: http://YOUR_TASKMAN_DEV_HOST:EXPOSED_PORT





### First time installation of the Taskman stack on Production


### First time installation of the Taskman frontend stack on Production

Add the certificate to rancher 

1) Copy the .zip archives containing the paid plugins into an SVN folder

3) Add Taskman stack, using the production variable values

4) Start the stack

5) Follow [import existing data](#import-existing-data) if you need to import existing data

6) Add a loadbalancer to the taskman/apache service, using a certificate for https 


[Start updating Taskman](#upgrade-procedure) if you updated the Redmine version or if you updated the Redmine's plugins.

#### Import existing data

If you already have a Taskman installation than follow the steps below to import the files and mysql db into the data containers.

##### Import Taskman files

Copy Taskman files from one instance ( ex. production ) to another ( ex. replica) .

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

#### Email settings

**IMPORTANT:** test first if the email notification are sent!
Use first time the email accounts marked as **email configuration without affecting production** from the _.email.secret_ file.

Features to be tested:

* create ticket via email
* create ticket for Helpdesk
* receive email notification on content update
* email issue reminder notification

Edit email configuration for helpdesk and taskman accounts

    $ vim .email.secret

Edit email configuration for redmine

    $ vim .postfix.secret

Restart postfix container

    $ docker-compose stop postfix
    $ docker-compose rm -v postfix
    $ docker-compose up -d postfix

### Upgrade procedure

#### Only for upgrade to 3.2.4 ( 09.10.2017 )

Uninstall redmine_mail_reminder plugin using  [Uninstall plugins](#how-to-uninstall-redmine-plugins)


#### Cleanup & Backup before upgrade

1) Make a backup of database

       $ docker exec -it eeadockertaskman_mysql_1 sh -c "mysqldump -u<MYSQL_ROOT_USER> -p<MYSQL_ROOT_PASSWORD> --add-drop-table <MYSQL_DB_NAME> > /var/local/backup/taskman.sql"
      
1) Pull latest version of redmine to minimize waiting time during the next step

       $ docker pull eeacms/redmine:<imagetag>

1) Update repository

       $ git pull

1) Backup existing plugins and remove them from plugins directory
    
       $ docker exec -it eeadockertaskman_redmine_1 sh -c "rm -rf /usr/src/redmine/plugins/*"

1) Stop all services

       $ docker-compose stop
    
1) Remove redmine container to be able to recreate plugins from image
   
       $ docker-compose rm redmine

1) Start all

       $ docker-compose up -d

#### Upgrade Redmine version

Start updating Taskman

    $ docker exec -it eeadockertaskman_redmine_1 bash
    $ bundle exec rake db:migrate RAILS_ENV=production

If required by the migrate, run 

    $ bundle install

Finish upgrade

    $ bundle exec rake tmp:cache:clear tmp:sessions:clear RAILS_ENV=production
    $ exit
    $ docker-compose stop redmine
    $ docker-compose start redmine


#### Upgrade premium plugins

Update premium plugins ( .zip archives ) located in eea.docker.taskman/plugins directory

    $ docker exec -it eeadockertaskman_redmine_1 bash
    $ ./install_plugins.sh
    $ docker-compose stop redmine
    $ docker-compose start redmine
    
#### Upgrade Redmine's plugins 
    
Does not need to be run if install_plugins.sh was executed

    $ bundle install --without development test
    $ bundle exec rake redmine:plugins:migrate RAILS_ENV=production

### End of install/upgrade procedure(s)

For this final steps you will need help from a sys admin.

- close current production, follow [wiki here]( https://taskman.eionet.europa.eu/projects/infrastructure/wiki/How_To_Inform_on_Planned_Maintenance)
- re-run rsync files
- re-take mysql dump
- re-import mysql dump
- run upgrade commands if there is a new Redmine version
- start the new installation
- switch floating IP

Finally go to "Administration -> Roles & permissions" to check/set permissions for the new features, if any.

Follow any other manual steps via redmine UI needed e.g. when adding new plugins.


## How-tos
### How to add repository to redmine

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
* enter the redmine container (docker exec -it eeadockertaskman_redmine_1 bash)
* cd /var/local/redmine/github
* git clone --mirror https://github.com/eea/eea.mypackage.git
* cd eea.mypackage.git
* git fetch --all
* chown -R apache.apache .

You can "read more":http://www.redmine.org/projects/redmine/wiki/HowTo_keep_in_sync_your_git_repository_for_redmine

### How to add check Redmine's logs

    $ docker-compose logs redmine

or

    $ docker exec -it eeadockertaskman_redmine_1 bash
    $ tail -f /usr/src/redmine/log/production.log

### How to manually sync LDAP users/groups

If you want to manually sync LDAP users and/or groups you need to run the following rake command inside the redmine container:

    $ docker exec -it eeadockertaskman_redmine_1 bash
    redmine@76547b4110ab:~/redmine$ bundle exec rake -T redmine:plugins:ldap_sync

For more info see the [LDAP sync documentation](https://github.com/thorin/redmine_ldap_sync#rake-tasks)

### How to install Redmine  Premium plugins

    $ cd /var/local/deploy/eea.docker.taskman/plugins
    $ docker-compose stop
    $ wget <URL-TO-DOWNLOAD-ZIPPED-PLUGIN>
    $ docker-compose up -d

Follow instructions from [Start updating Taskman](https://github.com/eea/eea.docker.taskman#start-updating-taskman)

### How to uninstall Redmine Premium plugins

    $ docker exec -it eeadockertaskman_redmine_1 bash
    $ bundle exec rake redmine:plugins:migrate NAME=redmine_plugin-name VERSION=0 RAILS_ENV=production
    $ exit
    $ cd /var/local/deploy/eea.docker.taskman/plugins
    $ rm -rf <redmine_plugin-name>.zip
    $ docker-compose stop
    $ docker-compose up -d


### How to uninstall Redmine plugins

1) Uninstall plugin 

       $ docker exec -it eeadockertaskman_redmine_1 bash
       $ bundle exec rake redmine:plugins:migrate NAME=redmine_plugin-name VERSION=0 RAILS_ENV=production
       $ cd plugins
       $ rm -rf <redmine_plugin-name>
       $ exit
       $ docker-compose stop
       $ docker-compose up -d

2) Make sure the plugin is removed from docker image

### Specific plugins documentation

* [Agile plugin](http://www.redminecrm.com/projects/agile/pages/1).
* [Checklists plugin](https://www.redminecrm.com/projects/checklist/pages/1).
* [LDAP Sync plugin](https://github.com/thorin/redmine_ldap_sync).

