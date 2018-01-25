# EEA Logcentral Graylog configuration HOW-TO

This stack contains the configuration of logcentral, a graylog application which connects to an external `Logcentral - Elasticsearch` service.

## Needed

This stack requires one instance of the `Logcentral - Elasticsearch` stack to be running in the same environment.

## How to configure it

These are the steps to configure that application:

### Apache
- `graylog_master_url` - DNS name of deployment
- `graylog_ssl_cert` - SSL certificate path on host
- `graylog_ssl_key` - SSL certificate key
- `graylog_ssl_chain` - SSL certificate chain

### Mail server
Mail server credentials used to send alerts email
- `postfix_mtp_user` - mtp user
- `postfix_mtp_password` - mtp password

### Graylog
- `graylog_root_password` - a root password used for initial login **SHA256 encrypted**. `echo -n yourpassword | shasum -a 256`
- `graylog_secret` - is used for password encryption and salting here. The server will refuse to start if it’s not set. Generate a secret with for example ```pwgen -N 1 -s 96```
- `graylog_heap_size` - Graylog Java VM heap size values

### Elastic search
- `elasticsearch_link` - choose the "EEA logcentral elasticsearch" master stack
- `elasticsearch_cluster` - Same as `cluster_name` within **EEA logcentral elasticsearch** deployment

### Rancher Labels
Comma separated list of host labels (e.g. `key1=value1,key2=value2`) to be used for scheduling the services.

- `graylog_apache_host_labels` - Schedule Graylog Apache frontend on hosts with following host labels
- `graylog_master_host_labels` - Schedule Graylog master on hosts with following host labels
- `graylog_client_host_labels` - Schedule Graylog clients on hosts with following host labels
- `loadbalancer_host_labels` - Schedule Loadbalancer on hosts with following host labels
- `mongodb_host_labels` - Schedule Mongodb on hosts with following host labels

## Upgrade

* Press the available upgrade buttons within Rancher UI

## Backup and restore

### Backup Graylog MongoDB

* Within mongodb container run:

        $ mongodump -o /tmp/logcentral

* Fix DB name if needed

        $ mv /tmp/logcentral/graylog2 /tmp/logcentral/graylog

* Archive

        $ tar -czvf /tmp/logcentral.tgz /tmp/logcentral

* Cleanup

        $ rm -rf /tmp/logcentral

* Copy dump on host:

        $ docker cp <mongo_container_id>:/tmp/logcentral.tgz /elasticshared/

### Restore Graylog MongoDB

* Copy dump in container:

        $ docker cp /elasticshared/logcentral.tgz  <mongo_container_id>:/tmp/

* Within mongodb container run:

        $ cd /tmp/
        $ tar -zxvf logcentral.tgz
        $ mongorestore logcentral

### Backup ElasticSearch cluster

* Within `kopf` Web UI go to rest tab `http://10.128.1.42:8090/#!/rest`

* Initialize repo

        PUT /_snapshot/my_backup
        {
          "type": "fs",
          "settings": {
            "location": "/backup"
          }
        }

* Do the backup

        PUT /_snapshot/my_backup/snapshot_1


### Restore ElasticSearch snapshot_1

* Initialize repo

        PUT /_snapshot/my_backup
        {
          "type": "fs",
          "settings": {
            "location": "/backup"
          }
        }

* Close `graylog2_0` index

* Restore

        POST /_snapshot/my_backup/snapshot_1/_restore

See ElasticSearch docs about [backup](https://www.elastic.co/guide/en/elasticsearch/guide/current/backing-up-your-cluster.html) and [restore](https://www.elastic.co/guide/en/elasticsearch/guide/current/_restoring_from_a_snapshot.html)

## Troubleshooting

- Q: Elasticsearch cluster unhealthy (RED)
- A: Check if there are unassigned shards, e.g. under `http://10.128.1.42:8090/#!/cluster`. First you can try restarting the entire Elastic Search Cluster. If it does not work, with the following command we could reassign the shards to the nodes. Within kopf web interface `http://10.128.1.42:8090/#!/rest`

```
POST /_cluster/reroute?pretty

{ "commands" : [ {
  "allocate" : {
       "index" : "graylog2_0",
       "shard" : 2,
       "node" : "logcentral-elasticsearch_elasticsearch-datanodes_2",
       "allow_primary":true
     }
  } ]
}
```
