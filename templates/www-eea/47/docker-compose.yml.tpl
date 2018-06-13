version: '2'
services:

{{- if ne .Values.DEBUG_ONLY "yes"}}

  apache:
    image: eeacms/apache-eea-www:5.8
    ports:
    - "80"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      SERVER_NAME: "${SERVER_NAME}"
      TZ: "${TZ}"
    links:
    - varnish
    volumes:
    - www-static-resources:/var/www-static-resources:ro

  varnish:
    image: eeacms/varnish-eea-www:3.8
    ports:
    - "6081"
    - "6085"
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
      DASHBOARD_USER: "${DASHBOARD_USER}"
      DASHBOARD_PASSWORD: "${DASHBOARD_PASSWORD}"

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
    image: eeacms/www-devel:18.6.13
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
      SERVER_NAME: "${SERVER_NAME}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      SENTRY_DSN: "${SENTRY_DSN}"
      LOGSPOUT: "ignore"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - www-source-code:/plone/instance/src
    {{- end}}

  auth-instance:
    image: eeacms/www-devel:18.6.13
    ports:
    - "8080"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      ZOPE_MODE: "rel_client"
      ZOPE_THREADS: "2"
      SERVER_NAME: "${SERVER_NAME}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      SENTRY_DSN: "${SENTRY_DSN}"
      LOGSPOUT: "ignore"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - www-source-code:/plone/instance/src
    {{- end}}

  download-instance:
    image: eeacms/www-devel:18.6.13
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
      SERVER_NAME: "${SERVER_NAME}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      SENTRY_DSN: "${SENTRY_DSN}"
      LOGSPOUT: "ignore"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - www-source-code:/plone/instance/src
    {{- end}}


{{- end}}

  async-instance:
    image: eeacms/www-devel:18.6.13
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
      SERVER_NAME: "${SERVER_NAME}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      SENTRY_DSN: "${SENTRY_DSN}"
      LOGSPOUT: "ignore"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - www-source-code:/plone/instance/src
    {{- end}}

  debug-instance:
    image: eeacms/www-devel:18.6.13
    ports:
    - "8080"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      ZOPE_MODE: "rel_client"
      ZOPE_THREADS: "4"
      SERVER_NAME: "${SERVER_NAME}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      SENTRY_DSN: "${SENTRY_DSN}"
      LOGSPOUT: "ignore"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - www-source-code:/plone/instance/src
    {{- end}}
    tty: true
    stdin_open: true
    command:
    - "/debug.sh"

  {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
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
  {{- end}}

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
  www-eea-controlpanel:
    external: true
  www-static-resources:
    driver: rancher-nfs
  {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
  www-source-code:
    driver: ${SRC_VOLUME_DRIVER}
    {{- if .Values.SRC_VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.SRC_VOLUME_DRIVER_OPTS}}
    {{- end}}
  {{- end}}
