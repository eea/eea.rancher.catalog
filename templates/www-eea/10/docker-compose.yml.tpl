version: '2'
services:

{{- if ne .Values.DEBUG_ONLY "yes"}}

  apache:
    image: eeacms/apache-eea-www:5.0
    ports:
    - "80"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      SERVER_NAME: "${SERVER_NAME}"
      COUNTRIES_AND_REGIONS: "${COUNTRIES_AND_REGIONS}"
      TZ: "${TZ}"
    links:
    - varnish
    volumes:
    - www-static-resources:/var/www-static-resources:ro

  varnish:
    image: eeacms/varnish-eea-www:2.9
    ports:
    - "6081"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    links:
    - anon
    - auth
    - download
    environment:
      TZ: "${TZ}"

  auth:
    image: eeacms/haproxy:1.7-4.0
    ports:
    - "8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    links:
    - auth-instance
    environment:
      FRONTEND_PORT: "8080"
      BACKENDS_PORT: "8080"
      BACKENDS: "auth-instance"
      DNS_ENABLED: "true"
      HTTPCHK: "GET /health.check"
      INTER: "20s"
      DOWN_INTER: "5s"
      FAST_INTER: "15s"
      TIMEOUT_SERVER: "120s"
      TIMEOUT_CLIENT: "120s"
      TZ: "${TZ}"

  anon:
    image: eeacms/haproxy:1.7-4.0
    ports:
    - "8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    links:
    - anon-instance
    environment:
      FRONTEND_PORT: "8080"
      BACKENDS_PORT: "8080"
      BACKENDS: "anon-instance"
      DNS_ENABLED: "true"
      HTTPCHK: "GET /health.check"
      INTER: "5s"
      TIMEOUT_SERVER: "120s"
      TIMEOUT_CLIENT: "120s"
      TZ: "${TZ}"

  download:
    image: eeacms/haproxy:1.7-4.0
    ports:
    - "8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    links:
    - download-instance
    environment:
      FRONTEND_PORT: "8080"
      BACKENDS_PORT: "8080"
      BACKENDS: "download-instance"
      DNS_ENABLED: "true"
      HTTPCHK: "GET /health.check"
      INTER: "5s"
      TIMEOUT_SERVER: "120s"
      TIMEOUT_CLIENT: "120s"
      TZ: "${TZ}"

  anon-instance:
    image: eeacms/www-devel:18.1.19
    ports:
    - "8080"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      ZOPE_MODE: "rel_client"
      ZOPE_THREADS: "2"
      ZOPE_FORCE_CONNECTION_CLOSE: 'off'
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-anon-data:/data
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-source-code:/plone/instance/src

  auth-instance:
    image: eeacms/www-devel:18.1.19
    ports:
    - "8080"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      ZOPE_MODE: "rel_client"
      ZOPE_THREADS: "2"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-auth-data:/data
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-source-code:/plone/instance/src

  download-instance:
    image: eeacms/www-devel:18.1.19
    ports:
    - "8080"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      ZOPE_MODE: "rel_client"
      ZOPE_THREADS: "2"
      ZOPE_FORCE_CONNECTION_CLOSE: 'off'
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-download-data:/data
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-source-code:/plone/instance/src


{{- end}}

  async-instance:
    image: eeacms/www-devel:18.1.19
    ports:
    - "8080"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      ZOPE_MODE: "rel_async"
      ZOPE_THREADS: "2"
      ZOPE_FAST_LISTEN: 'on'
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-async-data:/data
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-source-code:/plone/instance/src

  debug-instance:
    image: eeacms/www-devel:18.1.19
    ports:
    - "8080"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      ZOPE_MODE: "rel_client"
      ZOPE_THREADS: "4"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    volumes:
    - www-debug-data:/data
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-source-code:/plone/instance/src
    tty: true
    stdin_open: true
    command:
    - "/debug.sh"

  cloud9-ide:
    image: eeacms/cloud9
    ports:
    - "8080"
    links:
    - debug-instance
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
    - www-source-code:/cloud9/workspace/www-source-code

  memcached:
    image: memcached:1.5.3
    ports:
    - "11211"
    environment:
      TZ: "${TZ}"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    command:
    - "-m"
    - "1024"

  postfix:
    image: eaudeweb/mailtrap
    ports:
    - "80"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      TZ: "${TZ}"

  rabbitmq:
    image: rancher/external-service

  postgres:
    image: rancher/dns-service
    external_links:
    - ${POSTGRES}:postgres

volumes:
  www-blobstorage:
    external: true
  www-downloads:
    external: true
  www-suggestions:
    external: true
  www-static-resources:
    external: true
  www-eea-controlpanel:
    external: true
  www-source-code:
    driver: rancher-nfs
  www-debug-data:
    driver: local
  www-async-data:
    driver: local
  www-anon-data:
    driver: local
  www-download-data:
    driver: local
  www-auth-data:
    driver: local
