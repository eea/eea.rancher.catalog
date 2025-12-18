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
- `elasticsearch_link` - choose the "EEA logcentral elasticsearch" client stack

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

* Copy dump on host or use [Rsync container](#rsync-data-between-containers)

        $ docker cp <mongo_container_id>:/tmp/logcentral.tgz /elasticshared/



### Restore Graylog MongoDB

New installation ( new stack)

* Don't start the services ( un-check "Start services after creating")

* Start mongodb service

Existing installation ( old stack )

* Stop all graylog services

* Delete graylog database

        $ mongo graylog --eval "db.dropDatabase()"

Next steps:

* Copy dump in container or use [Rsync container](#rsync-data-between-containers)

        $ docker cp /elasticshared/logcentral.tgz  <mongo_container_id>:/tmp/

* Within mongodb container run:

        $ cd /tmp/
        $ tar -zxvf logcentral.tgz
        $ mongorestore logcentral

### Rsync data between containers

0. Request TCP access to port 2222 to a frontend server of environment of the new installation from the mongo container host server.

1. Start **rsync client** on host from where do you want to migrate data (ex. production).

    Infrastructures -> Hosts ->  Add Container
    * Select image: eeacms/rsync
    * Command: sh
    * Volumes -> Volumes from: Select graylog mongo container

2. Open logs from container, copy the ssh key from the message

2. Start **rsync server** on host from where do you want to migrate data (ex. devel). The mongodb container should be temporarily moved to a frontend server.

    Infrastructures -> Hosts ->  Add Container
    * Select image: eeacms/rsync
    * Port map -> +(add) : 2222:22
    * Command: server
    * Add environment variable: SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>"
    * Volumes -> Volumes from: Select graylog mongo container


3. Within **rsync client** container from step 1 run:

  ```
    $ rsync -e 'ssh -p 2222' -avz <DUMP_LOCATION> root@<TARGET_HOST_IP_ON_DEVEL>:/data/db/
  ```


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

### Restore ElasticSearch remotely

You can use reindex from remote to migrate indices from your old cluster to a new cluster. This enables you **move** your **cluster without interrupting** service.
See [Reindex from a remote cluster](https://www.elastic.co/guide/en/elasticsearch/reference/current/reindex-upgrade-remote.html)

* Within NEW ES cluster es-client containers allow remote access to the OLD cluster IP (e.g.: `10.120.31.148`):

        $ echo "reindex.remote.whitelist: 10.120.31.148:9200" >> config/elasticsearch.yml

* Within new ES cluster `cerebro` WEB UI create new index with the same id (e.g.: `graylog2_593`) using template:

        {
          "index": {
            "number_of_replicas": "0",
            "number_of_shards": "4",
            "refresh_interval": "-1",
            "blocks": {
              "write": "false",
              "metadata": "false",
              "read": "false"
            },
            "analysis": {
              "analyzer": {
                "analyzer_keyword": {
                  "filter": "lowercase",
                  "tokenizer": "keyword"
                }
              }
            }
          }
        }

* Within `cerebro` WEB UI `rest` tab run:


        _reindex POST

        {
          "source": {
            "remote": {
              "host": "http://10.120.31.148:9200"
            },
            "index": "graylog2_593"
          },
          "dest": {
            "index": "graylog2_593"
          }
        }

## Troubleshooting

- Q: Elasticsearch cluster unhealthy (RED)
- A: Check if there are unassigned shards, e.g. under `http://10.128.1.42:8090/#!/cluster`. First you can try restarting the entire Elastic Search Cluster. If it does not work, with the following command we could reassign the shards to the nodes. Within `cerebro` web interface `rest` tab:


        _cluster/reroute?pretty POST

        {
          "commands" : [ {
            "allocate" : {
              "index" : "graylog2_0",
              "shard" : 2,
              "node" : "logcentral-elasticsearch_elasticsearch-datanodes_2",
              "allow_primary":true
            }
          } ]
        }

