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
      - --wait_timeout=999999 
      - --interactive_timeout=999999
      - --net_read_timeout=60
      - --net_write_timeout=120
      - --connect_timeout=10
    volumes:
      - matomo_mariadb_data:/var/lib/mysql
    mem_reservation: 3g
    mem_limit: 5g


  matomo:
    image: 'bitnami/matomo:3.11.0'
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
      - matomo_php_conf:/opt/bitnami/php/conf
      - matomo_apache_conf:/opt/bitnami/apache/conf
    command:
      - /bin/bash
      - -c
      - . /opt/bitnami/base/functions ; . /opt/bitnami/base/helpers; . /apache-init.sh; . /matomo-init.sh; nami_initialize apache php mysql-client matomo; sed -i 's/memory_limit = .*/memory_limit = {{ .Values.PHP_MEM_LIMIT }}/g' /opt/bitnami/php/conf/php.ini; httpd -f /opt/bitnami/apache/conf/httpd.conf -DFOREGROUND
    mem_reservation: {{ .Values.MATOMO_MEM_RES }}
    mem_limit: {{ .Values.MATOMO_MEM_LIMIT }}

  matomocron-archive:
    image: 'bitnami/matomo:3.11.0'
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
      cron.schedule: "${MATOMO_ARCHIVE_CRON}"
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
      - matomo_php_conf:/opt/bitnami/php/conf
      - matomo_apache_conf:/opt/bitnami/apache/conf
    command:
      - /bin/bash
      - -c
      - . /opt/bitnami/base/functions ; . /opt/bitnami/base/helpers; . /apache-init.sh; . /matomo-init.sh; nami_initialize apache php mysql-client matomo; sed -i 's/memory_limit = .*/memory_limit = {{ .Values.PHP_MEM_LIMIT }}/g' /opt/bitnami/php/conf/php.ini; php /opt/bitnami/matomo/console core:archive --url=${MATOMO_URL}
    mem_reservation: {{ .Values.ARCHIVE_MEM_RES }}
    mem_limit: {{ .Values.ARCHIVE_MEM_LIMIT }}



  matomocron-ldapsync:
    image: 'bitnami/matomo:3.11.0'
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
      cron.schedule: "${MATOMO_LDAP_CRON}"
    depends_on:
      - mariadb
    volumes:
      - matomo_php_conf:/opt/bitnami/php/conf
      - matomo_apache_conf:/opt/bitnami/apache/conf
      - matomo_data:/bitnami
    command:
      - /bin/bash
      - -c
      - . /opt/bitnami/base/functions ; . /opt/bitnami/base/helpers; . /apache-init.sh; . /matomo-init.sh; nami_initialize apache php mysql-client matomo; php /opt/bitnami/matomo/console loginldap:synchronize-users
    mem_reservation: 256m
    mem_limit: 256m

  matomocron-delete-data:
    image: 'bitnami/matomo:3.11.0'
    environment:
      - "MARIADB_HOST=mariadb"
      - "MARIADB_PORT_NUMBER=3306"
      - "MATOMO_DATABASE_USER=${MARIADB_USER}"
      - "MATOMO_DATABASE_NAME=${MARIADB_DATABASE}"
      - "MATOMO_DATABASE_PASSWORD=${MARIADB_PASSWORD}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
      - "MATOMO_URL=${MATOMO_URL}"
      - "TZ=${TZ}"
      - "DAYS_TO_KEEP=${DAYS_TO_KEEP}"
      - "SITE_TO_DELETE=${DAYS_TO_KEEP}"
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.FRONT_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${FRONT_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.start_once: 'true'
      cron.schedule: "${MATOMO_DELETE_CRON}"
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
      - matomo_php_conf:/opt/bitnami/php/conf
      - matomo_apache_conf:/opt/bitnami/apache/conf
    command:
      - /bin/bash
      - -c
      - . /opt/bitnami/base/functions ; . /opt/bitnami/base/helpers; . /apache-init.sh; . /matomo-init.sh; nami_initialize apache php mysql-client matomo; sed -i 's/memory_limit = .*/memory_limit = {{ .Values.PHP_MEM_LIMIT }}/g' /opt/bitnami/php/conf/php.ini; php /opt/bitnami/matomo/console core:delete-logs-data --dates 2018-01-01,$$(date --date="$${DAYS_TO_KEEP} days ago" +%F) --idsite $${SITE_TO_DELETE} -n
    mem_reservation: {{ .Values.DEL_MEM_RES }}
    mem_limit: {{ .Values.DEL_MEM_LIMIT }}



  
  postfix:
    image: eeacms/postfix:2.10-3.4
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
      cron.schedule: "${MATOMO_RSYNC_LOGS_CRON}"
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
    image: eeacms/matomo-log-analytics:1.2
    labels:
      {{- if .Values.LOGS_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${LOGS_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.hostname_override: container_name
      io.rancher.container.start_once: 'true'
      cron.schedule: "${MATOMO_IMPORT_LOGS_CRON}"
    environment:
      TZ: "${TZ}"
      MATOMO_URL: "${MATOMO_URL}"
      MATOMO_TOKEN: "${MATOMO_TOKEN}"
    volumes:
    - matomo_importer:/analytics
    mem_reservation: 64m
    mem_limit: 256m




volumes:
  matomo_mariadb_data:
    external: true
  matomo_data:
    external: true
  matomo_php_conf:
    external: true
  matomo_apache_conf:
    external: true
  matomo_misc:
    external: true
  matomo_importer:
    external: true
  matomo_ssh-key:
    external: true
