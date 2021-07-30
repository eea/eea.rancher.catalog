version: "2"
services:
  postgres:
    image: postgres:11.6
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    volumes:
      - clairdb:/var/lib/postgresql/data
    environment:
      TZ: "${TZ}"
    mem_reservation: ${DB_MEM_RES}
    mem_limit: ${DB_MEM_LIM}

  clair:
    image: arminc/clair-local-scan:v2.1.7_1b14f0a10e56684a3f000a5f76c8677f3b5f2519
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
    mem_reservation:  ${CLAIR_MEM_RES}
    mem_limit: ${CLAIR_MEM_LIM}


volumes:
  clairdb:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}

