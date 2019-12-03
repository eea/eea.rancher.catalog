version: "2"
services:
  db:
    image: postgres:11.6
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    volumes:
      - dbdata:/var/lib/postgresql/data
    environment:
      TZ: "${TZ}"
    mem_reservation: ${DB_MEM_RES}
    mem_limit: ${DB_MEM_LIM}

  clair:
    image: arminc/clair-local-scan:v2.1.0_1e2ed91d90973d68a9840e4f08798d045cf7c2d7
    labels:
      {{- if .Values.HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.hostname_override: container_name
    links:
      - db:postgres
    environment:
      TZ: "${TZ}"
    mem_reservation:  ${CLAIR_MEM_RES}
    mem_limit: ${CLAIR_MEM_LIM}


  clair-scanner:
    image: eeacms/rancher-clairscanner:2.3
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
    mem_reservation: ${SCAN_MEM_RES} 

volumes:
  dbdata:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
