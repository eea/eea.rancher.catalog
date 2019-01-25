version: "2"
services:
  postgres:
    image: eeacms/postgres:9.6-3.4
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    volumes:
      - clair-db:/var/lib/postgresql/data
    environment:
      TZ: "${TZ}"
    mem_reservation: 1g
    mem_limit: 1g   

  clair:
    image: arminc/clair-local-scan:v2.0.5
    labels:
      {{- if .Values.HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.hostname_override: container_name
    links:
      - postgres:postgres
    environment:
      TZ: "${TZ}"
    mem_reservation: 1879048192 # = 1792m
    mem_limit: 1879048192 # = 1792m


  clair-scanner:
    image: eeacms/rancher-clairscanner:2.1 
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.global: 'true'
      io.rancher.container.start_once: 'true'
      cron.schedule: ${CRON_SCHEDULE}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    links:
      - clair:clair
    environment:
      TZ: "${TZ}"
      LEVEL: "${LEVEL}"
      DOCKER_API_VERSION: "${DOCKER_API_VERSION}"
      LOGGING: "${LOGGING}"
      RETRY_INTERVAL: "${RETRY_INTERVAL}"     
      RETRY_NR: "${RETRY_NR}"
      GRAYLOG_HOST: "${GRAYLOG_HOST}"
      GRAYLOG_PORT: "${GRAYLOG_PORT}"
      GRAYLOG_RETRY: "${GRAYLOG_RETRY}"
      GRAYLOG_WAIT: "${GRAYLOG_WAIT}"
    mem_reservation: 134217728 # = 128 MB


volumes:
  clair-db:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
