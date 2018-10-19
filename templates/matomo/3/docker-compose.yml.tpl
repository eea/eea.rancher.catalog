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
    user: root
    volumes:
      {{- if and (.Values.HOST_LABELS) (.Values.mariadb_volume_location) }}
      - ${mariadb_volume_location}:/bitnami
      {{- else}}
      - mariadb_data:/bitnami
      {{- end}}
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

  matomocron-archive:
    image: 'bitnami/matomo:3.6.0'
    environment:
      - "MARIADB_HOST=mariadb"
      - "MARIADB_PORT_NUMBER=3306"
      - "MATOMO_DATABASE_USER=${MARIADB_USER}"
      - "MATOMO_DATABASE_NAME=${MARIADB_DATABASE}"
      - "MATOMO_DATABASE_PASSWORD=${MARIADB_PASSWORD}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
      - "MATOMO_URL=${MATOMO_URL}"
      - "TZ=${TZ}"
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.FRONT_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${FRONT_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.start_once: 'true'
      cron.schedule: '0 5 * * * *'
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
    command:
      - /bin/bash
      - -c
      - . /opt/bitnami/base/functions ; . /opt/bitnami/base/helpers; . /init.sh; nami_initialize apache php mysql-client matomo; php /opt/bitnami/matomo/console core:archive --url=${MATOMO_URL}
    mem_reservation: 512m
    mem_limit: 1g


  matomocron-ldapsync:
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
      io.rancher.container.start_once: 'true'
      cron.schedule: '0 10 1 * * *'
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
    command:
      - /bin/bash
      - -c
      - . /opt/bitnami/base/functions ; . /opt/bitnami/base/helpers; . /init.sh; nami_initialize apache php mysql-client matomo; php /opt/bitnami/matomo/console loginldap:synchronize-users
    mem_reservation: 256m
    mem_limit: 512m
  
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


  rsync-analytics:
    image: eeacms/rsync:1.2
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.LOGS_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${LOGS_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.start_once: 'true'
      cron.schedule: '0 5 * * * *'
    environment:
      TZ: "${TZ}"
      RSYNC_SERVER_IP_1: "${RSYNC_SERVER_IP_1}"
      SITE_ID_1:  "${SIDE_ID_1}"
    volumes:
    - matomo_importer:/analytics
    - ssh-key:/root/.ssh
    command:
    - sh
    - -c
    - rsync -e 'ssh -p 2222' -avz --delete root@${RSYNC_SERVER_IP_1}:/data/apache-logs /analytics/logs/${SIDE_ID_1}


  matomo-analytics:
    image: eeacms/matomo-log-analytics
    labels:
      {{- if .Values.LOGS_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${LOGS_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.hostname_override: container_name
      io.rancher.container.start_once: 'true'
      cron.schedule: '0 30 * * * *'
    environment:
      TZ: "${TZ}"
      MATOMO_URL: "${MATOMO_URL}"
      MATOMO_USERNAME: "${MATOMO_ANALYTICS_USER}"
      MATOMO_PASSWORD: "${MATOMO_ANALYTICS_PASSWORD}"
    volumes:
    - matomo_importer:/analytics




volumes:
  {{- if not ( and (.Values.HOST_LABELS) (.Values.mariadb_volume_location) ) }} 
  mariadb_data:
    driver: ${mariadb_storage_driver}
    {{- if .Values.mariadb_storage_driver_opt}}
    driver_opts:
      {{.Values.mariadb_storage_driver_opt}}
    {{- end}}
  {{- end }}
  matomo_data:
    driver: ${matomo_storage_driver}
    {{- if .Values.matomo_storage_driver_opt}}
    driver_opts:
      {{.Values.matomo_storage_driver_opt}}
    {{- end}}
  matomo_misc:
    driver: ${matomomisc_storage_driver}
    {{- if .Values.matomomisc_storage_driver_opt}}
    driver_opts:
      {{.Values.matomomisc_storage_driver_opt}}
    {{- end}}
  matomo_importer:
    driver: ${matomologs_storage_driver}
    {{- if .Values.matomologs_storage_driver_opt}}
    driver_opts:
      {{.Values.matomologs_storage_driver_opt}}
    {{- end}}

