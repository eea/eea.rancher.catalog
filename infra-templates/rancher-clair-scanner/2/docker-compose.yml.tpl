version: "2"
services:
  postgres:
    image: eeacms/postgres:9.6-3.4
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    volumes:
      - clair-db:/var/lib/postgresql/data
    environment:
      TZ: "${TZ}"

  clair:
    image: arminc/clair-local-scan:v2.0.3
    labels:
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.container.hostname_override: container_name
    {{- if (.Values.CLAIR_PORT)}}
    ports:
      - "${CLAIR_PORT}:6060"
    {{- end}}    
    links:
      - postgres:postgres
    environment:
      TZ: "${TZ}"

  clair-scanner:
    image: eeacms/rancher-clairscanner:2.0 
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

volumes:
  clair-db:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
