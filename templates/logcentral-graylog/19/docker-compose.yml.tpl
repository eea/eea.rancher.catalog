version: "2"
services:

  postfix:
    image: eeacms/postfix:2.10-3.8
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_frontend_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    mem_limit: ${postfix_mem_limit}
    mem_reservation: ${postfix_mem_reservation}
    environment:
      MTP_USER: "${postfix_mtp_user}"
      MTP_PASS: "${postfix_mtp_password}"
      MTP_HOST: "${graylog_master_url}"
      MTP_RELAY: "ironports.eea.europa.eu"
      MTP_PORT: "8587"
      TZ: "${TZ}"

  mongo:
    image: mongo:4.4.19
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_db_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
    - logcentraldb:/data/db
    environment:
      TZ: "${TZ}"
    mem_limit: ${mongo_mem_limit}
    mem_reservation: ${mongo_mem_reservation}


  graylog-master:
    image: eeacms/graylog:4.3.12
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_master_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      GRAYLOG_IS_MASTER: "true"
      GRAYLOG_HTTP_BIND_ADDRESS: "0.0.0.0:9000"
      GRAYLOG_HTTP_EXTERNAL_URI: "https://${graylog_master_url}/"
      GRAYLOG_TRANSPORT_EMAIL_ENABLED: "true"
      GRAYLOG_TRANSPORT_EMAIL_HOSTNAME: "postfix"
      GRAYLOG_TRANSPORT_EMAIL_PORT: "25"
      GRAYLOG_TRANSPORT_EMAIL_SUBJECT_PREFIX: "[graylog2]"
      GRAYLOG_TRANSPORT_EMAIL_FROM_EMAIL: "graylog@eea.europa.eu"
      GRAYLOG_TRANSPORT_EMAIL_WEB_INTERFACE_URL: "https://${graylog_master_url}"
      GRAYLOG_TRANSPORT_EMAIL_USE_AUTH: "false"
      GRAYLOG_TRANSPORT_EMAIL_USE_TLS: "false"
      GRAYLOG_TRANSPORT_EMAIL_USE_SSL: "false"
      GRAYLOG_SERVER_JAVA_OPTS: "${graylog_heap_size} -XX:NewRatio=1 -XX:MaxMetaspaceSize=256m -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow"
      GRAYLOG_PROCESSBUFFER_PROCESSORS: "${graylog_processbuffer_processors}"
      GRAYLOG_PASSWORD_SECRET: "${graylog_secret}"
      GRAYLOG_ROOT_PASSWORD_SHA2: "${graylog_root_password}"
      GRAYLOG_ELASTICSEARCH_HOSTS: "http://elasticsearch:9200"
      TZ: "${TZ}"
    depends_on:
    - mongo
    - postfix
    user: root
    mem_limit: ${master_mem_limit}
    mem_reservation: ${master_mem_reservation}
    volumes:
    - logcentralgraylogdata:/usr/share/graylog/data
    - logcentraljournals:/usr/share/graylog/data/journal
    - logcentralplugins:/usr/share/graylog/plugin
    external_links:
    - ${elasticsearch_link}:elasticsearch

  graylog-client:
    image: eeacms/graylog:4.3.12
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_client_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      GRAYLOG_IS_MASTER: "false"
      GRAYLOG_HTTP_BIND_ADDRESS: "0.0.0.0:9000"
      GRAYLOG_HTTP_EXTERNAL_URI: "https://${graylog_master_url}/"
      GRAYLOG_TRANSPORT_EMAIL_ENABLED: "true"
      GRAYLOG_TRANSPORT_EMAIL_HOSTNAME: "postfix"
      GRAYLOG_TRANSPORT_EMAIL_PORT: "25"
      GRAYLOG_TRANSPORT_EMAIL_SUBJECT_PREFIX: "[graylog2]"
      GRAYLOG_TRANSPORT_EMAIL_FROM_EMAIL: "graylog@eea.europa.eu"
      GRAYLOG_TRANSPORT_EMAIL_WEB_INTERFACE_URL: "https://${graylog_master_url}"
      GRAYLOG_TRANSPORT_EMAIL_USE_AUTH: "false"
      GRAYLOG_TRANSPORT_EMAIL_USE_TLS: "false"
      GRAYLOG_TRANSPORT_EMAIL_USE_SSL: "false"
      GRAYLOG_SERVER_JAVA_OPTS: "${graylog_heap_size} -XX:NewRatio=1 -XX:MaxMetaspaceSize=256m -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:+CMSClassUnloadingEnabled -XX:+UseParNewGC -XX:-OmitStackTraceInFastThrow"
      GRAYLOG_PROCESSBUFFER_PROCESSORS: "${graylog_processbuffer_processors}"
      GRAYLOG_PASSWORD_SECRET: "${graylog_secret}"
      GRAYLOG_ROOT_PASSWORD_SHA2: "${graylog_root_password}"
      GRAYLOG_ELASTICSEARCH_HOSTS: "http://elasticsearch:9200"
      TZ: "${TZ}"
    depends_on:
    - mongo
    - postfix
    - graylog-master
    user: root
    volumes:
    - logcentralgraylogdata:/usr/share/graylog/data
    - logcentraljournals:/usr/share/graylog/data/journal
    - logcentralplugins:/usr/share/graylog/plugin
    mem_limit: ${client_mem_limit}
    mem_reservation: ${client_mem_reservation}
    external_links:
    - ${elasticsearch_link}:elasticsearch

  loadbalancer:
    image: eeacms/logcentralbalancer:3.1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_frontend_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    ports:
    - "1514:1514/tcp"
    - "1514:1514/udp"
    - "12201:12201/udp"
    - "12201:12201/tcp"
    environment:
      GRAYLOG_HOST: "graylog-client"
      LOGSPOUT: "ignore"
      TZ: "${TZ}"
    mem_limit: ${lb_mem_limit}
    mem_reservation: ${lb_mem_reservation}
    depends_on:
    - graylog-client

volumes:
  logcentralgraylogdata:
    driver: ${local_volume_driver}
    per_container: true
  logcentraljournals:
    driver: ${data_volume_driver}
    per_container: true
{{- if .Values.data_volume_driver_opts}}
    driver_opts:
      {{.Values.data_volume_driver_opts}}
{{- end}}
  logcentralplugins:
{{- if eq .Values.plugin_volume_external "yes"}}
    external: true
{{- else}}
    driver: ${plugin_volume_driver}
    driver_opts:
      {{.Values.plugin_volume_driver_opts}}
{{- end}}
  logcentraldb:
    driver: ${volume_driver}
{{- if .Values.volume_driver_opts}}
    driver_opts:
      {{.Values.volume_driver_opts}}
{{- end}}
