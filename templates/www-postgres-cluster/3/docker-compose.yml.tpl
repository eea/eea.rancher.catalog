version: "2"
services:
  master:
    image: eeacms/postgres:9.6-3.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: "${POSTGRES_MASTER_HOST_LABELS}"
      io.rancher.scheduler.affinity:container_label_soft_ne: "eu.europa.eea.postgres=yes"
      eu.europa.eea.postgres: "yes"
    environment:
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DBUSER: "${POSTGRES_DBUSER}"
      POSTGRES_DBPASS: "${POSTGRES_DBPASS}"
      POSTGRES_DBNAME: "${POSTGRES_DBNAME}"
      POSTGRES_CONFIG: "${POSTGRES_CONFIG}"
      POSTGRES_CRONS: "${POSTGRES_CRONS}"
      TZ: "${TZ}"
    volumes:
    - www-postgres-data:/var/lib/postgresql/data
    - www-postgres-dump:/postgresql.backup
    - www-postgres-archive:/var/lib/postgresql/archive
  replica:
    image: eeacms/postgres:9.6-3.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${POSTGRES_REPLICA_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: "eu.europa.eea.postgres=yes"
      eu.europa.eea.postgres: "yes"
    depends_on:
    - master
    environment:
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_REPLICATE_FROM: "master"
      POSTGRES_CONFIG: "${POSTGRES_CONFIG}"
      RECOVERY_CONFIG: "${RECOVERY_CONFIG}"
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
    {{- else}}
    per_container: true
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
