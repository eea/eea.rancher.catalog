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
    mem_reservation: ${DB_MEM_RES}
    mem_limit: ${DB_MEM_LIM}

  clair:
    image: arminc/clair-local-scan:v2.1.0_1e2ed91d90973d68a9840e4f08798d045cf7c2d7
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
  clair-db:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}

