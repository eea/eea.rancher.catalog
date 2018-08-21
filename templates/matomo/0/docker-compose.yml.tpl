version: '2'
services:
  mariadb:
    image: 'bitnami/mariadb:latest'
    environment:
      - "MARIADB_USER=${MARIADB_USER}"
      - "MARIADB_DATABASE=${MARIADB_DATABASE}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
    volumes:
      - mariadb_data:/bitnami
  matomo:
    image: 'bitnami/matomo:latest'
    environment:
      - "MARIADB_HOST=${MARIADB_HOST}"
      - "MARIADB_PORT_NUMBER=${MARIADB_PORT_NUMBER}"
      - "MATOMO_DATABASE_USER=${MATOMO_DATABASE_USER}"
      - "MATOMO_DATABASE_NAME=${MATOMO_DATABASE_NAME}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
    labels:
      kompose.service.type: nodeport
    ports:
      - '80'
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
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
