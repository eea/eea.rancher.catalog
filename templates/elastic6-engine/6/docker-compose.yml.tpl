version: '2'
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
        image: eeacms/elastic:6.3-1.1
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
            - "path.repo=/backup"
            - "ENABLE_READONLY_REST=${ENABLE_READONLY_REST}"
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
            - es-data:/usr/share/elasticsearch/data
            - ${BACKUP_VOLUME_NAME}:/backup

    es-worker:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}
            io.rancher.container.hostname_override: container_name
        image: eeacms/elastic:6.3-1.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "discovery.zen.ping.unicast.hosts=es-master"
            - "ES_JAVA_OPTS=-Xms${data_heap_size} -Xmx${data_heap_size}"
            - "node.master=false"
            - "node.data=true"
            - "http.enabled=false"
            - "path.repo=/backup"
            - "ENABLE_READONLY_REST=${ENABLE_READONLY_REST}"
            - "TZ=${TZ}"
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
            - es-data:/usr/share/elasticsearch/data
            - ${BACKUP_VOLUME_NAME}:/backup
        depends_on:
            - es-master

    es-client:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.container.hostname_override: container_name
            {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}
        image: eeacms/elastic:6.3-1.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            {{- if eq .Values.ENABLE_READONLY_REST "true" }}
            - "RW_USER=${RW_USER}"
            - "RO_USER=${RO_USER}"
            - "KIBANA_USER=${KIBANA_USER}"
            - "RW_PASSWORD=${RW_PASSWORD}"
            - "KIBANA_PASSWORD=${KIBANA_PASSWORD}"
            - "RO_PASSWORD=${RO_PASSWORD}"
            {{- end}}
            - "KIBANA_HOSTNAME=kibana"
            - "bootstrap.memory_lock=true"
            - "discovery.zen.ping.unicast.hosts=es-master"
            - "ES_JAVA_OPTS=-Xms${client_heap_size} -Xmx${client_heap_size}"
            - "node.master=false"
            - "node.data=false"
            - "http.enabled=true"
            - "path.repo=/backup"
            - "ENABLE_READONLY_REST=${ENABLE_READONLY_REST}"
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
        mem_reservation: ${client_mem_reservation}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes:
            - es-data:/usr/share/elasticsearch/data
            - ${BACKUP_VOLUME_NAME}:/backup
        depends_on:
            - es-worker


    cluster-health:
        image: eeacms/esclusterhealth:1.1
        depends_on:
            - es-client
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
            - ES_URL=http://es-client:9200
            - PORT=12345
            - ES_USER=${RO_USER}
            - "ES_PASSWORD=${RO_PASSWORD}"

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
        image: rawmind/alpine-sysctl:0.1
        privileged: true
        mem_limit: 32m
        mem_reservation: 8m
        environment:
            - "SYSCTL_KEY=vm.max_map_count"
            - "SYSCTL_VALUE=262144"
            - "KEEP_ALIVE=1"
    {{- end}}

    cerebro:
        image: eeacms/cerebro:0.8.1
        depends_on:
            - es_client
       {{- if (.Values.CEREBRO_PORT)}}
        ports:
            - "${CEREBRO_PORT}:9000"
       {{- end}}
        environment:
            - CER_ES_URL=http://es-client:9200
            {{- if eq .Values.ENABLE_READONLY_REST "true" }}
            - CER_ES_USER=${RW_USER}
            - CER_ES_PASSWORD=${RW_PASSWORD}
            {{- end}}
            - CER_JAVA_OPTS=${CER_JAVA_OPTS}
            - "TZ=${TZ}"
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
        image: eeacms/elk-kibana:6.3.1
        depends_on:
            - es_client
       {{- if (.Values.KIBANA_PORT)}}
        ports:
            - "${KIBANA_PORT}:5601"
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
            - ELASTICSEARCH_URL=http://es-client:9200
            {{- if eq .Values.ENABLE_READONLY_REST "true" }}
            - KIBANA_RW_PASSWORD=${KIBANA_PASSWORD}
            - KIBANA_RW_USERNAME=${KIBANA_USER}
            {{- end}}
            - NODE_OPTIONS=--max-old-space-size=${kibana_space_size}
            - "TZ=${TZ}"
    {{- end}}


volumes:
  es-data:
    driver: ${VOLUME_DRIVER}
    {{- if eq .Values.VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
    per_container: true
  {{ .Values.BACKUP_VOLUME_NAME }}:
    driver: ${BACKUP_VOLUME_DRIVER}
    {{- if eq .Values.BACKUP_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.BACKUP_VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.BACKUP_VOLUME_DRIVER_OPTS}}
    {{- end}}
