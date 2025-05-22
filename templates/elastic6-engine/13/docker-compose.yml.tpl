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
        image: eeacms/elastic:7.10.2-oss
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "ES_JAVA_OPTS=-Xms${master_heap_size} -Xmx${master_heap_size}"
            - "bootstrap.memory_lock=true"
            - "cluster.name=${cluster_name}"
            - "cluster.initial_master_nodes=$${HOSTNAME}"
            - "discovery.seed_hosts=es-master"
            - "node.role=master"
            - "node.name=$${HOSTNAME}"
            {{- if .Values.BACKUP_VOLUME_NAME}}
            - "path.repo=/backup"
            {{- end}}
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
            {{- if .Values.BACKUP_VOLUME_NAME}}
            - ${BACKUP_VOLUME_NAME}:/backup
            {{- end}}


    es-worker:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            {{- if .Values.host_labels}}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            {{- else}}
            io.rancher.scheduler.affinity:host_label_ne: reserved=yes
            {{- end}}
            io.rancher.container.hostname_override: container_name
        image: eeacms/elastic:7.10.2-oss
        environment:
            - "ES_JAVA_OPTS=-Xms${data_heap_size} -Xmx${data_heap_size}"
            - "bootstrap.memory_lock=true"
            - "cluster.name=${cluster_name}"
            - "discovery.seed_hosts=es-master"
            - "node.roles=data"
            - "node.name=$${HOSTNAME}"
            {{- if .Values.BACKUP_VOLUME_NAME}}
            - "path.repo=/backup"
            {{- end}}
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
            {{- if .Values.BACKUP_VOLUME_NAME}}
            - ${BACKUP_VOLUME_NAME}:/backup
            {{- end}}
        depends_on:
            - es-master

    cluster-health:
        image: eeacms/esclusterhealth:1.1
        depends_on:
            - es-master
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
            - ES_URL=http://es-master:9200
            - PORT=12345

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
        image: eeacms/cerebro:0.9.0
        depends_on:
            - es_client
       {{- if (.Values.CEREBRO_PORT)}}
        ports:
            - "${CEREBRO_PORT}:9000"
       {{- end}}
        environment:
            - ELASTIC_URL=http://es-master:9200
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

volumes:
  es-data:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
    per_container: true
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
