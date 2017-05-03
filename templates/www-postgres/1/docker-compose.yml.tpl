version: '2'
services:
  master:
    image: eeacms/postgres:9.5-3.0
    labels:
      io.rancher.scheduler.affinity:host_label: ${POSTGRES_HOST_LABELS}
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
    - www-postgres-data:/var/lib/postgresql/data
    - www-postgres-dump:/postgresql.backup
    - www-postgres-archive:/var/lib/postgresql/archive
volumes:
  www-postgres-data:
    driver: ${DATA_VOLUME_DRIVER}
    {{- if eq .Values.DATA_VOLUME_EXTERNAL "yes"}}
    external: true
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

