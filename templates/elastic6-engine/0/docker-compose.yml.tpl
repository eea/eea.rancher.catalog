version: '2'
services:
    es-master:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.container.hostname_override: container_name
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            io.rancher.sidekicks: es-storage{{- if eq .Values.UPDATE_SYSCTL "true" -}},es-sysctl{{- end}}
        image: eeacms/elastic:6.1.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "ES_JAVA_OPTS=-Xms${master_heap_size} -Xmx${master_heap_size}"
            - "discovery.zen.ping.unicast.hosts=es-master"
            - "discovery.zen.minimum_master_nodes=${minimum_master_nodes}"
            - "node.master=true"
            - "node.data=false"
            - "http.enabled=false"
            - "TZ=${TZ}"
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${master_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes_from:
            - es-storage

    es-worker:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            io.rancher.container.hostname_override: container_name
            io.rancher.sidekicks: es-storage{{- if eq .Values.UPDATE_SYSCTL "true" -}},es-sysctl{{- end}}
        image: eeacms/elastic:6.1.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "discovery.zen.ping.unicast.hosts=es-master"
            - "ES_JAVA_OPTS=-Xms${data_heap_size} -Xmx${data_heap_size}"
            - "node.master=false"
            - "node.data=true"
            - "http.enabled=false"
            - "TZ=${TZ}"
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${data_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes_from:
            - es-storage
        depends_on:
            - es-master

    es-client:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            io.rancher.container.hostname_override: container_name
            io.rancher.sidekicks: es-storage{{- if eq .Values.UPDATE_SYSCTL "true" -}},es-sysctl{{- end}}
        image: eeacms/elastic:6.1.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "RW_USER=${RW_USER}"
            - "RO_USER=${RO_USER}"
            - "KIBANA_USER=${KIBANA_USER}"
            - "RW_PASSWORD=${RW_PASSWORD}"
            - "KIBANA_PASSWORD=${KIBANA_PASSWORD}"
            - "RO_PASSWORD=${RO_PASSWORD}"
            - "bootstrap.memory_lock=true"
            - "discovery.zen.ping.unicast.hosts=es-master"
            - "ES_JAVA_OPTS=-Xms${client_heap_size} -Xmx${client_heap_size}"
            - "node.master=false"
            - "node.data=false"
            - "http.enabled=true"
            - "TZ=${TZ}"
    {{- if (.Values.ES_CLIENT_PORT)}}
        ports:
            - "${ES_CLIENT_PORT}:9200"
    {{- end}}
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${client_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes_from:
            - es-storage
        depends_on:
            - es-master

    es-storage:
        labels:
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            io.rancher.container.start_once: true
        network_mode: none
        image: rawmind/alpine-volume:0.0.2-1
        environment:
            - SERVICE_UID=1000
            - SERVICE_GID=1000
            - SERVICE_VOLUME=/usr/share/elasticsearch/data
        volumes:
            - es-storage-volume:/usr/share/elasticsearch/data

    {{- if eq .Values.UPDATE_SYSCTL "true" }}
    es-sysctl:
        labels:
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            io.rancher.container.start_once: true
        network_mode: none
        image: rawmind/alpine-sysctl:0.1
        privileged: true
        environment:
            - "SYSCTL_KEY=vm.max_map_count"
            - "SYSCTL_VALUE=262144"
    {{- end}}

    cerebro:
        image: eeacms/cerebro 
        depends_on:
            - es_client
       {{- if (.Values.CEREBRO_PORT)}}
        ports:
            - "${CEREBRO_PORT}:9000"
       {{- end}}
        environment:
            - CER_ES_URL=http://es-client:9200
            - CER_ES_USER=${RW_USER}
            - CER_ES_PASSWORD=${RW_PASSWORD}
            - "TZ=${TZ}"
        labels:
          io.rancher.container.hostname_override: container_name
          io.rancher.scheduler.affinity:host_label: ${host_labels}

   
    kibana:
        image: docker.elastic.co/kibana/kibana-oss:6.1.1
        depends_on:
            - es_client
       {{- if (.Values.KIBANA_PORT)}}
        ports:
            - "${KIBANA_PORT}:5601"
       {{- end}}
        labels:
          io.rancher.container.hostname_override: container_name
          io.rancher.scheduler.affinity:host_label: ${host_labels}
        environment:
            - ELASTICSEARCH_URL="http://es-client:9200"
            - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
            - ELASTICSEARCH_USERNAME=${KIBANA_USER}
            - "TZ=${TZ}"

volumes:
  es-storage-volume:
    driver: ${VOLUME_DRIVER}
    {{- if eq .Values.VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}} 
    per_container: true

