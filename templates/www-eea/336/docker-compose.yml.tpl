version: '2'
services:

{{- if ne .Values.DEBUG_ONLY "yes"}}

  apache:
    image: eeacms/apache-eea-www:24.7.23
    mem_limit: 512m
    mem_reservation: 512m
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
    depends_on:
    - varnish
    volumes:
    - www-static-resources:/var/www-static-resources

  varnish:
    image: eeacms/varnish-eea-www:22.3.14
    mem_limit: 512m
    mem_reservation: 512m
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
    depends_on:
    - anon
    - auth
    - download
    environment:
      TZ: "${TZ}"
      CACHE_SIZE: "200M"
      DASHBOARD_USER: "${DASHBOARD_USER}"
      DASHBOARD_PASSWORD: "${DASHBOARD_PASSWORD}"

  auth:
    image: eeacms/haproxy:1.8-1.2
    mem_limit: 128m
    mem_reservation: 128m
    ports:
    - "8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    links:
    - auth-instance
    depends_on:
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
    image: eeacms/haproxy:1.8-1.2
    mem_limit: 128m
    mem_reservation: 128m
    ports:
    - "8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    links:
    - anon-instance
    depends_on:
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
    image: eeacms/haproxy:1.8-1.2
    mem_limit: 128m
    mem_reservation: 128m
    ports:
    - "8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    links:
    - download-instance
    depends_on:
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
    image: eeacms/www-devel:23.9.14
    mem_limit: ${MEM_LIMIT}
    mem_reservation: 1g
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
      CORS_ALLOW_ORIGIN: "${CORS_ALLOW_ORIGIN}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    depends_on:
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
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - ${SRC_VOLUME_NAME}:/plone/instance/src
    {{- end}}

  auth-instance:
    image: eeacms/www-devel:23.9.14
    mem_limit: ${MEM_LIMIT}
    mem_reservation: 1g
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
      CORS_ALLOW_ORIGIN: "${CORS_ALLOW_ORIGIN}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    depends_on:
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
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - ${SRC_VOLUME_NAME}:/plone/instance/src
    {{- end}}

  download-instance:
    image: eeacms/www-devel:23.9.14
    mem_limit: ${MEM_LIMIT}
    mem_reservation: 1g
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
      CORS_ALLOW_ORIGIN: "${CORS_ALLOW_ORIGIN}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    depends_on:
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
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - ${SRC_VOLUME_NAME}:/plone/instance/src
    {{- end}}


{{- end}}

  async-instance:
    image: eeacms/www-devel:23.9.14
    mem_limit: ${MEM_LIMIT}
    mem_reservation: 1g
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
      CORS_ALLOW_ORIGIN: "${CORS_ALLOW_ORIGIN}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    - debug-instance
    depends_on:
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
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - ${SRC_VOLUME_NAME}:/plone/instance/src
    {{- end}}

  debug-instance:
    image: eeacms/www-devel:23.9.14
    mem_limit: 4g
    mem_reservation: 2g
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
      GIT_BRANCH: "${GIT_BRANCH}"
      GIT_NAME: "${GIT_NAME}"
      CORS_ALLOW_ORIGIN: "${CORS_ALLOW_ORIGIN}"
      TZ: "${TZ}"
    links:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    depends_on:
    - postgres
    - postfix
    - memcached
    - rabbitmq
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
    - ${SRC_VOLUME_NAME}:/plone/instance/src
    {{- end}}
    tty: true
    stdin_open: true
    command:
    - "/debug.sh"

  {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
  cloud9-ide:
    image: eeacms/cloud9
    mem_limit: 512m
    mem_reservation: 512m
    ports:
    - "8080"
    links:
    - debug-instance
    depends_on:
    - debug-instance
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
    - ${SRC_VOLUME_NAME}:/cloud9/workspace/www-source-code
  {{- end}}

  memcached:
    image: rancher/dns-service
    external_links:
    - ${MEMCACHED}:memcached

  postfix:
    image: eaudeweb/mailtrap:2.3
    mem_limit: 128m
    mem_reservation: 128m
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
    driver: rancher-nfs
  {{- if ne .Values.SRC_VOLUME_DRIVER "disabled"}}
  {{.Values.SRC_VOLUME_NAME}}:
    driver: ${SRC_VOLUME_DRIVER}
    {{- if .Values.SRC_VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.SRC_VOLUME_DRIVER_OPTS}}
    {{- end}}
  {{- end}}
