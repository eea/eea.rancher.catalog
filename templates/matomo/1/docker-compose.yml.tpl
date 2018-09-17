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
      - "TZ=${TZ}"
    volumes:
      - mariadb_data:/bitnami
    mem_reservation: 1g
    mem_limit: 2g


  matomo:
    image: 'bitnami/matomo:3.6.0'
    environment:
      - "MARIADB_HOST=mariadb"
      - "MARIADB_PORT_NUMBER=3306"
      - "MATOMO_DATABASE_USER=${MARIADB_USER}"
      - "MATOMO_DATABASE_NAME=${MARIADB_DATABASE}"
      - "MATOMO_DATABASE_PASSWORD=${MARIADB_PASSWORD}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
      - "TZ=${TZ}"
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.FRONT_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${FRONT_HOST_LABELS}
      {{- else}} 
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
      - matomo_misc:/opt/bitnami/matomo/misc/
    mem_reservation: 1g
    mem_limit: 3g

  postfix:
    image: eeacms/postfix:2.10-3.3
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    environment:
      TZ: "${TZ}"
      MTP_HOST: "${MATOMO_SERVER_NAME}"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"
    mem_reservation: 256m
    mem_limit: 256m

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
  matomo_misc:
    driver: local
