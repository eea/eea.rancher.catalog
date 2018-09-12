version: '2'
services:

  mariadb:
    image: 'bitnami/mariadb:10.1'
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    environment:
      - "MARIADB_USER=${MARIADB_USER}"
      - "MARIADB_DATABASE=${MARIADB_DATABASE}"
      - "MARIADB_PASSWORD=${MARIADB_PASSWORD}"
      - "MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
    volumes:
      - mariadb_data:/bitnami
    mem_reservation: 512m
    mem_limit: 1g


  matomo:
    image: 'bitnami/matomo:3.5.1'
    environment:
      - "MARIADB_HOST=mariadb"
      - "MARIADB_PORT_NUMBER=3306"
      - "MATOMO_DATABASE_USER=${MARIADB_USER}"
      - "MATOMO_DATABASE_NAME=${MARIADB_DATABASE}"
      - "MATOMO_DATABASE_PASSWORD=${MARIADB_PASSWORD}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
    mem_reservation: 512m
    mem_limit: 2g


volumes:
  mariadb_data:
    driver: ${mariadb_storage_driver}
    {{- if .Values.mariadb_storage_driver_opt}}
    driver_opts:
      {{.Values.mariadb_storage_driver_opt}}
    {{- end}}
  matomo_data:
    driver: ${matomo_storage_driver}
    {{- if .Values.matomo_storage_driver_opt}}
    driver_opts:
      {{.Values.matomo_storage_driver_opt}}
    {{- end}}
