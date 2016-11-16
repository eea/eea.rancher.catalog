# EEA Logcentral Graylog configuration HOW-TO

This stack containes the configuration of logcentral, a graylog application which connects to an external "EEA logcentral elasticsearch" service.

## Needed

This stack requires one instance of the "EEA logcentral elasticsearch" stack to be running in the same environment.

## How to configure it

These are the steps to configure that application:

### Mail server
Mail server credentials used to send alerts email
- *postfix_mtp_user* - mtp user
- *postfix_mtp_password* - mtp password

### Graylog
- *graylog_root_password* - a root password used for initial login.
- *graylog_secret* - is used for password encryption and salting here. The server will refuse to start if it’s not set. Generate a secret with for example ```pwgen -N 1 -s 96```
- *graylog_heap_size* - Graylog Java VM heap size values

### Elastic search
- *elasticsearch_link* - choose the "EEA logcentral elasticsearch" master stack

### Rancher Labels
Comma separated list of host labels (e.g. key1=value1,key2=value2) to be used for scheduling the services.

- *graylog_master_host_labels* - Schedule Graylog master on hosts with following host labels
- *graylog_client_host_labels* - Schedule Graylog clients on hosts with following host labels
- *loadbalancer_host_labels* - Schedule Loadbalancer on hosts with following host labels
- *mongodb_host_labels* - Schedule Mongodb on hosts with following host labels
