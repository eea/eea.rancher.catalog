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
    mem_reservation: 536870912 # = 512m
    mem_limit: 536870912 # = 512m


  clair:
    image: arminc/clair-local-scan:v2.0.5
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
    mem_reservation: 1879048192 # = 1792m
    mem_limit: 1879048192 # = 1792m


volumes:
  clair-db:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}

