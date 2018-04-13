version: '2'
services:
  master:
    image: eeacms/postgres:9.6-3.1
    {{- if (.Values.POSTGRES_HOST_PORT)}}
    ports:
    - "${POSTGRES_HOST_PORT}:5432"
    {{- end}}
    labels:
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    environment:
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DBNAME: "${POSTGRES_DBNAME}"
      POSTGRES_DBUSER: "${POSTGRES_DBUSER}"
      POSTGRES_DBPASS: "${POSTGRES_DBPASS}"
      POSTGRES_CONFIG: "${POSTGRES_CONFIG}"
      POSTGRES_CRONS: "${POSTGRES_CRONS}"
      POSTGRES_REPLICATION_NETWORK: "${POSTGRES_REPLICATION_NETWORK}"
      TZ: "${TZ}"
    volumes:
    - ${DATA_VOLUME_NAME}:/var/lib/postgresql/data
    - www-postgres-dump:/postgresql.backup
    - www-postgres-archive:/var/lib/postgresql/archive
  memcached:
    image: memcached:1.5.7
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      TZ: "${TZ}"
    command:
    - "-m"
    - "${CACHE_SIZE}"
volumes:
  {{ .Values.DATA_VOLUME_NAME }}:
    driver: ${DATA_VOLUME_DRIVER}
    {{- if eq .Values.DATA_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.DATA_VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.DATA_VOLUME_DRIVER_OPTS}}
    {{- end}}
  www-postgres-dump:
    driver: ${DUMP_VOLUME_DRIVER}
    {{- if eq .Values.DUMP_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
  www-postgres-archive:
    driver: ${ARCHIVE_VOLUME_DRIVER}
    {{- if eq .Values.ARCHIVE_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
