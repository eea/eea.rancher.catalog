version: "2"
services:
  apache:
    image: eeacms/apache:2.4-2.3
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_frontend_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      APACHE_MODULES: "http2_module"
      APACHE_CONFIG: |-
        Listen 8443
        <VirtualHost *:80>
            ServerName logs.apps.eea.europa.eu
            RewriteEngine On
            RewriteRule ^(.*)$$ https://${graylog_master_url} [R=permanent,L]
        </VirtualHost>

        <VirtualHost *:80>
            ServerName ${graylog_master_url}
            RewriteEngine On
            RewriteRule ^(.*)$$ https://%{HTTP_HOST}$$1 [R=permanent,L]
        </VirtualHost>

        <VirtualHost *:8443>
            ServerName ${graylog_master_url}

            <Proxy *>
                Order deny,allow
                Allow from all
            </Proxy>

            <Location />
                RequestHeader set X-Graylog-Server-URL "https://${graylog_master_url}/api/"
                ProxyPass http://graylog-master:9000/
                ProxyPassReverse http://graylog-master:9000/
            </Location>
        </VirtualHost>
      TZ: "${TZ}"
      LOGSPOUT: "ignore"
    mem_limit: ${apache_mem_limit}
    mem_reservation: ${apache_mem_reservation}
    depends_on:
    - graylog-master

  postfix:
    image: eeacms/postfix:2.10-3.3
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
    image: mongo:3.6.6
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_db_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
    - logcentral-db:/data/db
    - logcentral-configdb:/data/configdb
    environment:
      TZ: "${TZ}"
    mem_limit: ${mongo_mem_limit}
    mem_reservation: ${mongo_mem_reservation}


  graylog-master:
    image: graylog2/server:2.4.6-1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_master_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      GRAYLOG_IS_MASTER: "true"
      GRAYLOG_REST_LISTEN_URI: "http://0.0.0.0:9000/api/"
      GRAYLOG_WEB_LISTEN_URI: "http://0.0.0.0:9000/"
      GRAYLOG_REST_TRANSPORT_URI: "https://${graylog_master_url}/api/"
      GRAYLOG_WEB_ENDPOINT_URI: "https://${graylog_master_url}/api/"
      GRAYLOG_TRANSPORT_EMAIL_ENABLED: "true"
      GRAYLOG_TRANSPORT_EMAIL_HOSTNAME: "postfix"
      GRAYLOG_TRANSPORT_EMAIL_PORT: "25"
      GRAYLOG_TRANSPORT_EMAIL_SUBJECT_PREFIX: "[graylog2]"
      GRAYLOG_TRANSPORT_EMAIL_FROM_EMAIL: "noreply@eea.europa.eu"
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
    mem_limit: ${master_mem_limit}
    mem_reservation: ${master_mem_reservation}
    volumes:
    - logcentral-data:/usr/share/graylog/data
    external_links:
    - ${elasticsearch_link}:elasticsearch

  graylog-client:
    image: graylog2/server:2.4.6-1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${graylog_client_host_labels}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      GRAYLOG_IS_MASTER: "false"
      GRAYLOG_REST_LISTEN_URI: "http://0.0.0.0:9000/api/"
      GRAYLOG_WEB_LISTEN_URI: "http://0.0.0.0:9000/"
      GRAYLOG_REST_TRANSPORT_URI: "https://${graylog_master_url}/api/"
      GRAYLOG_WEB_ENDPOINT_URI: "https://${graylog_master_url}/api/"
      GRAYLOG_TRANSPORT_EMAIL_ENABLED: "true"
      GRAYLOG_TRANSPORT_EMAIL_HOSTNAME: "postfix"
      GRAYLOG_TRANSPORT_EMAIL_PORT: "25"
      GRAYLOG_TRANSPORT_EMAIL_SUBJECT_PREFIX: "[graylog2]"
      GRAYLOG_TRANSPORT_EMAIL_FROM_EMAIL: "noreply@eea.europa.eu"
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
    mem_limit: ${client_mem_limit}
    mem_reservation: ${client_mem_reservation}
    external_links:
    - ${elasticsearch_link}:elasticsearch

  loadbalancer:
    image: eeacms/logcentralbalancer:2.4
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
      GRAYLOG_HOSTS: "graylog-master,graylog-client"
      LOGSPOUT: "ignore"
      TZ: "${TZ}"
    mem_limit: ${lb_mem_limit}
    mem_reservation: ${lb_mem_reservation}
    depends_on:
    - graylog-master
    - graylog-client

volumes:
  logcentral-data:
    driver: ${data_volume_driver}
{{- if eq .Values.volume_driver "rancher-ebs"}}
    driver_opts:
      {{.Values.data_volume_driver_opts}}
{{- end}}
  logcentral-db:
    driver: ${volume_driver}
{{- if eq .Values.volume_driver "rancher-ebs"}}
    driver_opts:
      {{.Values.volume_driver_opts}}
{{- end}}
