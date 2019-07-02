# Sentry


## Info:
 This templates creates a complete [sentry](https://github.com/getsentry/sentry) setup including postgres and redis servers.

 Images are:
 * Sentry: [eeacms/sentry](https://hub.docker.com/r/eeacms/sentry/)
 * Postgres: [eeacms/postgres](https://hub.docker.com/r/eeacms/postgres/)
 * Postfix: [eeacms/postfix](https://hub.docker.com/r/eeacms/postfix)
 * Redis: [redis](https://hub.docker.com/_/redis/)
 * Memcached: [memcached](https://hub.docker.com/_/memcached)

## Usage:

 * Select EEA - Sentry from catalog.

 * Required
   * Enter a sentry secret
   * Specify the email and password of the initial user

 * Click deploy.

## Set-up a replica on development ( ex on https://sentry.dev2aws.eea.europa.eu )

1. Create an OAiuth App on GitHub.:

   * Go to https://github.com/settings/applications/new
   * Set *Homepage URL* and *Authorization callback URL* to the https url you will be using ex: `https://sentry.dev2aws.eea.europa.eu`
    
    
2. If you will be using rancher-ebs for your Storage driver ( postgres volume ), you have to check the database storage usage on production 
    
    On production, sentry/sentry-postgres:
    $ du -h  /var/lib/postgresql/data
    
3. Start the stack in development with the same version as in production, with environment appropriate settings. Postfix variables should be empty, memory ones should be default, and :
   * Server name -  sentry.dev2aws.eea.europa.eu
   * Sentry db name - the same as production
   * Sentry db user - the same as production 
   * SENTRY_GITHUB_API_ID - *Client ID* from OAuthApp
   * SENTRY_GITHUB_API_SECRET - *Client Secret* from OAuthApp
   * SENTRY_SECRET_KEY,  SENTRY_INITIAL_USER_EMAIL , SENTRY_INITIAL_USER_PASSWORD - anything
   * External volume name - Use to give rancher scoped external volumes, that should be created before
   * Volume Storage Driver - rancher-nfs by default
   * Storage Drive Option - size:? ( it should be more than the existing used space on production), used on netapp and rancher-ebs
   
4. Replicate the database.

* On production, sentry/sentry-postgres, do a backup:
    
      pg_dump -U USER  DATABASE  > /postgresql.backup/NAME
      
* Use Rsync container to move the database backup from production to development - https://github.com/eea/eea.docker.rsync#rsync-data-between-containers-in-rancher

* Prepare development database:
     -  Stop sentry/sentry
     -  On postgres, DROP DATABASE DATABASE;
     -  restart sentry/sentry-postgres
* Restore database backup on development, sentry/sentry-postgres:
    
      psql -U USER  DATABASE < /postgresql.backup/NAME

* Prepare Rancher LB - create a https redirection, make sure that the https certificate is valid, redirect to port 9000 on sentry/sentry

* Check that the site is up & running

* Redirect a test site to the new sentry instance. For redirecting the staging stack, upgrade *-instance containers to use a new SENTRY_DSN ( Can be copied from project settings, Client Keys (DSN), DSN  ) and restart varnish and memcached.

* Test the error sending using the Web Console, for example to generate an exception:

      Raven.captureException('Upgrade generated exception. Just a test, please ignore!')

* Test other features ( like redmine ticket creation )
