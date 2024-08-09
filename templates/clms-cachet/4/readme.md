# Cachet Status page


Cachet is a beautiful and powerful open source status page system.

## Overview

- List your service components
- Report incidents
- Customise the look of your status page
- Markdown support for incident messages
- A powerful JSON API
- Metrics
- Multi-lingual
- Subscriber notifications via email
- Two factor authentication

## Documentation

- https://docs.cachethq.io/
- https://github.com/CachetHQ/Cachet
- https://github.com/CachetHQ/Docker
- https://github.com/castawaylabs/cachet-monitor


## Configuration

- "Cachet public url" - use full url
- "Cachet generated key" - generate with `php artisan key:generate`
- "Cachet api token" - API token for user used in monitor ( not the same as the generated key )
- "Cachet-monitor configuration" - https://github.com/castawaylabs/cachet-monitor#example-configuration
- "Debug enabled" - used in both cachet and cachet-monitor
- "Cachet database name" - Postgres database, used by cachet
- "Cachet database user" 
- "Cachet database password"
- "Schedule the database on hosts with following host labels" - Used for rancher-ebs and local db volume
- "Database data volume driver" - default rancher-nfs
- "Database data volume driver options" - used for netapp & ebs volumes
- "Cachet homeserver public FQDN" - Used by postfix
- "Cachet email FROM" - used in all emails sent by Cachet 
- "Cachet email name" - used in all emails sent by Cachet
- "Postfix relay", "Postfix relay port", "Postfix user", "Postfix password" - used to configure postfix server
- "Time zone"




