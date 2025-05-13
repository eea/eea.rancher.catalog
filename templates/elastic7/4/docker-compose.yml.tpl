version: '2'

volumes:
  elastic-data:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
    per_container: true
  {{- if .Values.ELASTIC_PASSWORD }}  
  elasticconfig:
    driver: ${VOLUME_CONFIG_DRIVER}
    {{- if .Values.VOLUME_CONFIG_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_CONFIG_DRIVER_OPTS}}
    {{- end}}
  {{- end}}
  {{- if .Values.BACKUP_VOLUME_NAME}}
  {{ .Values.BACKUP_VOLUME_NAME }}:
    driver: ${BACKUP_VOLUME_DRIVER}
    {{- if eq .Values.BACKUP_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.BACKUP_VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.BACKUP_VOLUME_DRIVER_OPTS}}
    {{- end}}
  {{- end}}
  
services:
    es-master:
        labels:
            {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.container.hostname_override: container_name
        image: eeacms/elastic:7.17-1.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "cluster.initial_master_nodes=$${HOSTNAME}"
            - "discovery.seed_hosts=es-master,es-data"
            - "bootstrap.memory_lock=true"
            - "ES_JAVA_OPTS=-Xms${master_heap_size} -Xmx${master_heap_size}"
            {{- if eq .Values.USE_MONITORING "true" }}
            - "xpack.monitoring.collection.enabled=true"
            - "node.roles=master,ingest"
            {{- else }}
            - "node.roles=master"
            {{- end}}
            {{- if .Values.ELASTIC_PASSWORD }}
            - "xpack.security.enabled=true"
            - "xpack.security.transport.ssl.enabled=true"
            - "xpack.security.transport.ssl.verification_mode=certificate"
            - "xpack.security.transport.ssl.keystore.path=elastic-certificates.p12"
            - "xpack.security.transport.ssl.truststore.path=elastic-certificates.p12"
            - "elastic_password=${ELASTIC_PASSWORD}"
            - "kibana_system_password=${KIBANA_PASSWORD}"
            {{- else }}
            - "xpack.security.enabled=false"
            - "xpack.security.transport.ssl.enabled=false"
            {{- end}}
            {{- if .Values.BACKUP_VOLUME_NAME}}
            - "path.repo=/backup"
            {{- end}}
            - "cluster.routing.allocation.disk.watermark.high=95%"
            - "cluster.routing.allocation.disk.watermark.low=93%"
            - "TZ=${TZ}"
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${master_mem_limit}
        mem_reservation: ${master_mem_reservation}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes:
            - elastic-data:/usr/share/elasticsearch/data
            {{- if .Values.BACKUP_VOLUME_NAME}}
            - ${BACKUP_VOLUME_NAME}:/backup
            {{- end}}
            {{- if .Values.ELASTIC_PASSWORD }}  
            - elasticconfig:/usr/share/elasticsearch/config
            {{- end}}
       {{- if eq .Values.ES_PORT "true"}}
        ports:
            - "9200"
       {{- end}}


    es-data:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}
            io.rancher.container.hostname_override: container_name
        image: eeacms/elastic:7.17-1.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "cluster.initial_master_nodes=es-master"
            - "discovery.seed_hosts=es-master,es-data"
            - "bootstrap.memory_lock=true"
            - "node.roles=data"
            {{- if eq .Values.USE_MONITORING "true" }}
            - "xpack.monitoring.collection.enabled=true"
            {{- end}}
            {{- if .Values.ELASTIC_PASSWORD}}
            - "xpack.security.enabled=true"
            - "xpack.security.transport.ssl.enabled=true"
            - "xpack.security.transport.ssl.verification_mode=certificate"
            - "xpack.security.transport.ssl.keystore.path=elastic-certificates.p12"
            - "xpack.security.transport.ssl.truststore.path=elastic-certificates.p12"
            - "elastic_password=${ELASTIC_PASSWORD}"
            - "kibana_system_password=${KIBANA_PASSWORD}"
            - "DO_NOT_CREATE_USERS=yes"
            {{- else }}
            - "xpack.security.enabled=false"
            - "xpack.security.transport.ssl.enabled=false"
            {{- end}}
            {{- if .Values.BACKUP_VOLUME_NAME}}
            - "path.repo=/backup"
            {{- end}}
            - "TZ=${TZ}"
            - "ES_JAVA_OPTS=-Xms${data_heap_size} -Xmx${data_heap_size}"
            - "cluster.routing.allocation.disk.watermark.high=95%"
            - "cluster.routing.allocation.disk.watermark.low=93%"
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${data_mem_limit}
        mem_reservation: ${data_mem_reservation}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes:
            - elastic-data:/usr/share/elasticsearch/data
            {{- if .Values.BACKUP_VOLUME_NAME}}
            - ${BACKUP_VOLUME_NAME}:/backup
            {{- end}}
            {{- if .Values.ELASTIC_PASSWORD }}  
            - elasticconfig:/usr/share/elasticsearch/config
            {{- end}}
        depends_on:
            - es-master
        {{- if eq .Values.ES_PORT "true"}}
        ports:
            - "9200"
        {{- end}}
 

    cluster-health:
        image: eeacms/esclusterhealth:1.2
        depends_on:
            - es-data
        labels:
            io.rancher.container.hostname_override: container_name
            {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}
        mem_limit: 64m
        mem_reservation: 8m
        environment:
            - ES_URL=http://es-data:9200
            - PORT=12345
            - ES_USER=elastic
            - "ES_PASSWORD=${ELASTIC_PASSWORD}"

    {{- if eq .Values.UPDATE_SYSCTL "true" }}
    es-sysctl:
        labels:
            io.rancher.scheduler.global: 'true'
            {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}
            io.rancher.container.start_once: false
        network_mode: none
        image: eeacms/alpine-sysctl:0.3
        privileged: true
        mem_limit: 32m
        mem_reservation: 8m
        environment:
            - "SYSCTL_KEY=vm.max_map_count"
            - "SYSCTL_VALUE=262144"
            - "KEEP_ALIVE=1"
    {{- end}}

    cerebro:
        image: eeacms/cerebro:0.9.4-1
        depends_on:
            - es-master
        {{- if eq .Values.CEREBRO_PORT "true" }}
        ports:
            - "9000"
        {{- end}}
        environment:
            - ELASTIC_URL=http://es-master:9200
            - BASIC_AUTH_USER=${CEREBRO_USER}
            - BASIC_AUTH_PWD=${CEREBRO_PASSWORD}
            - "CEREBRO_SECRET=${CEREBRO_SECRET}"
            - "TZ=${TZ}"
            {{- if .Values.ELASTIC_PASSWORD }}
            - ELASTIC_USER=elastic
            - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
            {{- end}}
        mem_limit: ${cerebro_mem_limit}
        mem_reservation: ${cerebro_mem_reservation}
        labels:
            io.rancher.container.hostname_override: container_name
             {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}

    {{- if eq .Values.ADD_KIBANA "true" }}
    kibana:
        image: eeacms/elk-kibana:7.17.28
        depends_on:
            - es-data
        {{- if eq .Values.KIBANA_PORT "true" }}
        ports:
            - "5601"
        {{- end}}
        labels:
            io.rancher.container.hostname_override: container_name
            {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}
        mem_limit: ${kibana_mem_limit}
        mem_reservation: ${kibana_mem_reservation}
        environment:
            - ELASTICSEARCH_URL=http://es-data:9200
            {{- if (.Values.ELASTIC_PASSWORD) }}
            - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
            {{- if  eq .Values.ALLOW_ANON_RO "true" }}
            - "ALLOW_ANON_RO=true"
            - "ANON_PASSWORD=$ANON_PASSWORD"
            - "READ_ONLY_ROLE_JSON=$READ_ONLY_ROLE_JSON"
            - "elastic_password=$ELASTIC_PASSWORD"
            {{- end}}
            {{- end}}
            - NODE_OPTIONS=--max-old-space-size=${kibana_space_size}
            - "ELASTICSEARCH_REQUESTTIMEOUT=$ELASTICSEARCH_REQUESTTIMEOUT"
            - "TELEMETRY_ENABLED=false"
            - "KIBANA_AUTOCOMPLETETIMEOUT=$KIBANA_AUTOCOMPLETETIMEOUT"
            - "KIBANA_AUTOCOMPLETETERMINATEAFTER=$KIBANA_AUTOCOMPLETETERMINATEAFTER"
            - "SERVER_PUBLICBASEURL=$KIBANA_URL" 
            - "TZ=${TZ}"
    {{- end}}
