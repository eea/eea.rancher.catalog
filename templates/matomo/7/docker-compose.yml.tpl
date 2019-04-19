version: '2'
services:

  mariadb:
    image: 'mariadb:10.4'
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    environment:
      - "MYSQL_USER=${MARIADB_USER}"
      - "MYSQL_DATABASE=${MARIADB_DATABASE}"
      - "MYSQL_PASSWORD=${MARIADB_PASSWORD}"
      - "MYSQL_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}"
      - "MYSQL_ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
      - "TZ=${TZ}"
    {{- if .Values.EXPOSE_DB_PORT}}
    ports:
      - "${EXPOSE_DB_PORT}:3306"
    {{- end}}
    user: root
    command:
      - --max_allowed_packet=128M
    volumes:
      - matomo_mariadb_data:/var/lib/mysql
    mem_reservation: 3g
    mem_limit: 4g


  matomo:
    image: 'bitnami/matomo:3.9.1'
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
    mem_limit: 2g

  matomocron-archive:
    image: 'bitnami/matomo:3.9.1'
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
    mem_reservation: 2g
    mem_limit: 3g


  matomocron-ldapsync:
    image: 'bitnami/matomo:3.9.1'
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
    mem_limit: 256m
  
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
    volumes:
    - matomo_importer:/analytics
    - matomo_ssh-key:/root/.ssh
    command:
    - sh
    - -c
    - ${RSYNC_COMMANDS}


  matomo-analytics:
    image: eeacms/matomo-log-analytics:1.1
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
  matomo_mariadb_data:
    external: true
  matomo_data:
    external: true
  matomo_misc:
    external: true
  matomo_importer:
    external: true
  matomo_ssh-key:
    external: true
