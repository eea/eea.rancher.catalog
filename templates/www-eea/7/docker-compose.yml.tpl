version: '2'
services:
  apache:
    image: eeacms/apache-eea-www:3.2
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.apache=yes
      eu.europa.eea.apache: "yes"
    environment:
      SERVER_NAME: "${SERVER_NAME}"
      APACHE_MODULES: "http2_module mime_magic_module data_module unique_id_module remoteip_module negotiation_module"
      APACHE_INCLUDE: "conf/extra/httpd-languages.conf conf/extra/httpd-default.conf"
      APACHE_TIMEOUT: "120"
      APACHE_KEEPALIVE_TIMEOUT: "8"
      TRACEVIEW: "${TRACEVIEW}"
      TZ: "${TZ}"
    depends_on:
    - varnish
    volumes:
    - www-static-resources:/var/www-static-resources
  varnish:
    image: eeacms/varnish-eea-www:2.1
    ports:
    - "6081"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.varnish=yes
      eu.europa.eea.varnish: "yes"
    depends_on:
    - anon
    - auth
    - download
    environment:
      CACHE_SIZE: "${VARNISH_CACHE_SIZE}"
      PARAM_VALUE: "-p thread_pools=8 -p thread_pool_timeout=120 -p thread_pool_add_delay=0.002 -p ban_lurker_sleep=0.1 -p send_timeout=3600"
      TZ: "${TZ}"
      BACKENDS: "anon auth download"
      BACKENDS_PORT: "8080"
      BACKENDS_PROBE_ENABLED: "false"
      DNS_ENABLED: "true"
  auth:
    image: eeacms/haproxy:1.7-3.0
    ports:
    - "7990:8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.auth=yes
      eu.europa.eea.auth: "yes"
    depends_on:
    - auth-instance
    environment:
      FRONTEND_PORT: "8080"
      BACKENDS: "auth-instance"
      BACKENDS_PORT: "8080"
      DNS_ENABLED: "True"
      TZ: "${TZ}"
      HTTPCHK: "GET /health.check"
      INTER: "20s"
      DOWN_INTER: "5s"
      FAST_INTER: "15s"
      TIMEOUT_SERVER: "120s"
      TIMEOUT_CLIENT: "120s"
  anon:
    image: eeacms/haproxy:1.7-3.0
    ports:
    - "7994:8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.anon=yes
      eu.europa.eea.anon: "yes"
    depends_on:
    - anon-instance
    environment:
      FRONTEND_PORT: "8080"
      BACKENDS: "anon-instance"
      BACKENDS_PORT: "8080"
      DNS_ENABLED: "True"
      TZ: "${TZ}"
      HTTPCHK: "GET /health.check"
      INTER: "5s"
      TIMEOUT_SERVER: "120s"
      TIMEOUT_CLIENT: "120s"
  download:
    image: eeacms/haproxy:1.7-3.0
    ports:
    - "7998:8080"
    - "1936"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.download=yes
      eu.europa.eea.download: "yes"
    depends_on:
    - download-instance
    environment:
      FRONTEND_PORT: "8080"
      BACKENDS: "download-instance"
      BACKENDS_PORT: "8080"
      DNS_ENABLED: "True"
      TZ: "${TZ}"
      HTTPCHK: "GET /health.check"
      INTER: "5s"
      TIMEOUT_SERVER: "120s"
      TIMEOUT_CLIENT: "120s"
  anon-instance:
    image: eeacms/www:${KGS_VERSION}
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.anon-instance=yes
      eu.europa.eea.anon-instance: "yes"
    environment:
      ZOPE_MODE: "rel_client"
      RELSTORAGE_KEEP_HISTORY: "${RELSTORAGE_KEEP_HISTORY}"
      ZOPE_THREADS: "2"
      ZOPE_FORCE_CONNECTION_CLOSE: 'off'
      GRAYLOG: "${GRAYLOG}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "${WARMUP}"
      TRACEVIEW: "${TRACEVIEW}"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
      {{- if eq .Values.KGS_VERSION "devel"}}
      ENABLE_PRINTING_MAILHOST: "True"
      {{- end}}
    depends_on:
    - postgres
    - postfix
    - relcached
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-anon-data:/data
    {{- if eq .Values.KGS_VERSION "devel"}}
    - www-source-code:/plone/instance/src
    {{- end}}
  auth-instance:
    image: eeacms/www:${KGS_VERSION}
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.auth-instance=yes
      eu.europa.eea.auth-instance: "yes"
    environment:
      ZOPE_MODE: "rel_client"
      RELSTORAGE_KEEP_HISTORY: "${RELSTORAGE_KEEP_HISTORY}"
      ZOPE_THREADS: "2"
      GRAYLOG: "${GRAYLOG}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "${WARMUP}"
      TRACEVIEW: "${TRACEVIEW}"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
      {{- if eq .Values.KGS_VERSION "devel"}}
      ENABLE_PRINTING_MAILHOST: "True"
      {{- end}}
    depends_on:
    - postgres
    - postfix
    - relcached
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-auth-data:/data
    {{- if eq .Values.KGS_VERSION "devel"}}
    - www-source-code:/plone/instance/src
    {{- end}}
  download-instance:
    image: eeacms/www:${KGS_VERSION}
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.download-instance=yes
      eu.europa.eea.download-instance: "yes"
    environment:
      ZOPE_MODE: "rel_client"
      RELSTORAGE_KEEP_HISTORY: "${RELSTORAGE_KEEP_HISTORY}"
      ZOPE_THREADS: "2"
      ZOPE_FORCE_CONNECTION_CLOSE: 'off'
      GRAYLOG: "${GRAYLOG}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "${WARMUP}"
      TRACEVIEW: "${TRACEVIEW}"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
      {{- if eq .Values.KGS_VERSION "devel"}}
      ENABLE_PRINTING_MAILHOST: "True"
      {{- end}}
    depends_on:
    - postgres
    - postfix
    - relcached
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-download-data:/data
    {{- if eq .Values.KGS_VERSION "devel"}}
    - www-source-code:/plone/instance/src
    {{- end}}
  async-instance:
    image: eeacms/www:${KGS_VERSION}
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.async-instance=yes
      eu.europa.eea.async-instance: "yes"
    environment:
      ZOPE_MODE: "rel_async"
      RELSTORAGE_KEEP_HISTORY: "${RELSTORAGE_KEEP_HISTORY}"
      ZOPE_THREADS: "2"
      ZOPE_FAST_LISTEN: 'on'
      GRAYLOG: "${GRAYLOG}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      TRACEVIEW: "${TRACEVIEW}"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
      {{- if eq .Values.KGS_VERSION "devel"}}
      ENABLE_PRINTING_MAILHOST: "True"
      {{- end}}
    depends_on:
    - postgres
    - postfix
    - relcached
    - memcached
    - rabbitmq
    - debug-instance
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-async-data:/data
    {{- if eq .Values.KGS_VERSION "devel"}}
    - www-source-code:/plone/instance/src
    {{- end}}
  debug-instance:
    image: eeacms/www:${KGS_VERSION}
    ports:
    - "8080"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.debug-instance=yes
      eu.europa.eea.debug-instance: "yes"
      {{- if eq .Values.KGS_VERSION "devel"}}
      io.rancher.sidekicks: source-code
      {{- end}}
    environment:
      ZOPE_MODE: "rel_client"
      RELSTORAGE_KEEP_HISTORY: "${RELSTORAGE_KEEP_HISTORY}"
      ZOPE_THREADS: "4"
      GRAYLOG: "${GRAYLOG}"
      GRAYLOG_FACILITY: "${SERVER_NAME}"
      WARMUP_HEALTH_THRESHOLD: "1"
      TRACEVIEW: "${TRACEVIEW}"
      RABBITMQ_USER: "${RABBITMQ_USER}"
      RABBITMQ_PASS: "${RABBITMQ_PASS}"
      TZ: "${TZ}"
      {{- if eq .Values.KGS_VERSION "devel"}}
      ENABLE_PRINTING_MAILHOST: "True"
      {{- end}}
    depends_on:
    - postgres
    - postfix
    - relcached
    - memcached
    - rabbitmq
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-debug-data:/data
    {{- if eq .Values.KGS_VERSION "devel"}}
    - www-source-code:/plone/instance/src
    {{- end}}
    tty: true
    stdin_open: true
    command:
    - cat
  memcached:
    image: memcached:1.4.36
    environment:
      TZ: "${TZ}"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.memcached=yes
      eu.europa.eea.memcached: "yes"
    command:
    - "-m"
    - "2048"
  relcached:
    image: memcached:1.4.36
    environment:
      TZ: "${TZ}"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.relcached=yes
      eu.europa.eea.relcached: "yes"
    command:
    - "-m"
    - "2048"
  postfix:
    image: eeacms/postfix:2.10-3.1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.postfix=yes
      eu.europa.eea.postfix: "yes"
    environment:
      TZ: "${TZ}"
      MTP_HOST: "${SERVER_NAME}"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"
  rabbitmq:
    image: rancher/external-service
  postgres:
    image: rancher/dns-service
    external_links:
    - ${POSTGRES}:postgres
  {{- if eq .Values.KGS_VERSION "devel"}}
  source-code:
    image: eeacms/www:${KGS_VERSION}
    labels:
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.container.pull_image: always
      io.rancher.container.start_once: 'true'
    environment:
      ZOPE_MODE: "rel_client"
      RELSTORAGE_KEEP_HISTORY: "${RELSTORAGE_KEEP_HISTORY}"
      TZ: "${TZ}"
    volumes:
    - www-blobstorage:/data/blobstorage
    - www-downloads:/data/downloads
    - www-suggestions:/data/suggestions
    - www-static-resources:/data/www-static-resources
    - www-eea-controlpanel:/data/eea.controlpanel
    - www-source-code-data:/data
    - www-source-code:/plone/instance/src
    tty: true
    stdin_open: true
    command:
    - "bin/develop"
    - "up"
  cloud9:
    image: eeacms/cloud9
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: eu.europa.eea.cloud9=yes
      eu.europa.eea.cloud9: "yes"
    ports:
    - "8080"
    volumes:
    - www-source-code:/cloud9/workspace
  {{- end}}

volumes:
  www-anon-data:
    per_container: true
  www-download-data:
    per_container: true
  www-auth-data:
    per_container: true
  www-async-data:
    per_container: true
  www-debug-data:
    per_container: true
  www-blobstorage:
    external: true
    driver: rancher-nfs
  www-downloads:
    {{- if ne .Values.KGS_VERSION "devel"}}
    external: true
    {{- end}}
    driver: rancher-nfs
  www-static-resources:
    {{- if ne .Values.KGS_VERSION "devel"}}
    external: true
    {{- end}}
    driver: rancher-nfs
  www-eea-controlpanel:
    {{- if ne .Values.KGS_VERSION "devel"}}
    external: true
    {{- end}}
    driver: rancher-nfs
  www-suggestions:
    {{- if ne .Values.KGS_VERSION "devel"}}
    external: true
    {{- end}}
    driver: rancher-nfs
  {{- if eq .Values.KGS_VERSION "devel"}}
  www-source-code-data:
    per_container: true
  www-source-code:
    driver: rancher-nfs
  {{- end}}

