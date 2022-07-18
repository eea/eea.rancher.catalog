version: '2'
services:

  mariadb:
    image: mariadb:10.6.8
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
      - --innodb_flush_log_at_trx_commit=2
      - --max_connections=200
      - --table_open_cache=800
      - --table_definition_cache=800
      - --innodb_buffer_pool_size=8G
      - --innodb_log_file_size=512M
      - --query_cache_size=0
      - --query_cache_type=0 
    volumes:
      - matomo_mariadb_data:/var/lib/mysql
    mem_reservation: {{ .Values.DB_MEM_RES }}
    mem_limit: {{ .Values.DB_MEM_LIM }}


  matomo:
    image: bitnami/matomo:4.10.1-debian-10-r11
    environment:
      - "MARIADB_HOST=mariadb"
      - "MARIADB_PORT_NUMBER=3306"
      - "MATOMO_DATABASE_USER=${MARIADB_USER}"
      - "MATOMO_DATABASE_NAME=${MARIADB_DATABASE}"
      - "MATOMO_DATABASE_PASSWORD=${MARIADB_PASSWORD}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
      - "TZ=${TZ}"
      - "PHP_MEMORY_LIMIT={{ .Values.PHP_MEM_LIMIT }}"
      - "PHP_MAX_EXECUTION_TIME=0"
      - "APACHE_HTTP_PORT_NUMBER=80"
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.FRONT_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${FRONT_HOST_LABELS}
      {{- else}} 
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    user: root
    command:
    - /bin/bash
    - -c
    - /opt/bitnami/scripts/apache/setup.sh; /opt/bitnami/scripts/php/setup.sh ; /opt/bitnami/scripts/mysql-client/setup.sh; /opt/bitnami/scripts/matomo/setup.sh; rm -f /etc/cron.d/matomo; service cron stop; sed -i "s/LogFormat \"%h/LogFormat \"%{X-Forwarded-For}i/g" /opt/bitnami/apache/conf/httpd.conf; /opt/bitnami/scripts/matomo/run.sh
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
      - matomo_misc:/opt/bitnami/matomo/misc
    mem_reservation: {{ .Values.MATOMO_MEM_RES }}
    mem_limit: {{ .Values.MATOMO_MEM_LIMIT }}

  matomocron-archive:
    image: bitnami/matomo:4.10.1-debian-10-r11
    environment:
      - "MARIADB_HOST=mariadb"
      - "MARIADB_PORT_NUMBER=3306"
      - "MATOMO_DATABASE_USER=${MARIADB_USER}"
      - "MATOMO_DATABASE_NAME=${MARIADB_DATABASE}"
      - "MATOMO_DATABASE_PASSWORD=${MARIADB_PASSWORD}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
      - "TZ=${TZ}"
      - "PHP_MEMORY_LIMIT={{ .Values.ARCHPHP_MEM_LIMIT }}"
      - "PHP_MAX_EXECUTION_TIME=0"
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.ARCH_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${ARCH_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.start_once: 'true'
      cron.schedule: "${MATOMO_ARCHIVE_CRON}"
    depends_on:
      - mariadb
    user: root  
    volumes:
      - matomo_data:/bitnami
    command:
      - /bin/bash
      - -c
      - /opt/bitnami/scripts/apache/setup.sh; /opt/bitnami/scripts/php/setup.sh; /opt/bitnami/scripts/mysql-client/setup.sh; /opt/bitnami/scripts/matomo/setup.sh; rm -f /etc/cron.d/matomo; service cron stop; php /opt/bitnami/matomo/console core:archive --url=http://matomo --concurrent-archivers=8 --concurrent-requests-per-website=6 -vvv
    mem_reservation: {{ .Values.ARCHIVE_MEM_RES }}
    mem_limit: {{ .Values.ARCHIVE_MEM_LIMIT }}



  matomocron-ldapsync:
    image: bitnami/matomo:4.10.1-debian-10-r11
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
    user: root  
    volumes:
      - matomo_data:/bitnami
    command:
      - /bin/bash
      - -c
      - /opt/bitnami/scripts/matomo/entrypoint.sh;     /opt/bitnami/scripts/apache/setup.sh;     /opt/bitnami/scripts/php/setup.sh  ;   /opt/bitnami/scripts/mysql-client/setup.sh;     /opt/bitnami/scripts/matomo/setup.sh ; rm -f /etc/cron.d/matomo; service cron stop; php /opt/bitnami/matomo/console loginldap:synchronize-users
    mem_reservation: 256m
    mem_limit: 256m

  matomocron-delete-data:
    image: bitnami/matomo:4.10.1-debian-10-r11
    environment:
      - "MARIADB_HOST=mariadb"
      - "MARIADB_PORT_NUMBER=3306"
      - "MATOMO_DATABASE_USER=${MARIADB_USER}"
      - "MATOMO_DATABASE_NAME=${MARIADB_DATABASE}"
      - "MATOMO_DATABASE_PASSWORD=${MARIADB_PASSWORD}"
      - "ALLOW_EMPTY_PASSWORD=${ALLOW_EMPTY_PASSWORD}"
      - "MATOMO_URL=${MATOMO_URL}"
      - "TZ=${TZ}"
      - "PHP_MEMORY_LIMIT=512M"
      - "DAYS_TO_KEEP=${DAYS_TO_KEEP}"
      - "SITE_TO_DELETE=${SITE_TO_DELETE}"
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.FRONT_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${FRONT_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.start_once: 'true'
      cron.schedule: "${MATOMO_DELETE_CRON}"
    user: root  
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
    command:
      - /bin/bash
      - -c
      - /opt/bitnami/scripts/apache/setup.sh;     /opt/bitnami/scripts/php/setup.sh  ;   /opt/bitnami/scripts/mysql-client/setup.sh;     /opt/bitnami/scripts/matomo/setup.sh ;    rm -f /etc/cron.d/matomo; service cron stop;  /post-init.sh;   php /opt/bitnami/matomo/console  core:delete-logs-data --dates 2018-01-01,$$(date --date="$${DAYS_TO_KEEP} days ago" +%F) --idsite $${SITE_TO_DELETE} -n
    mem_reservation: {{ .Values.DEL_MEM_RES }}
    mem_limit: {{ .Values.DEL_MEM_LIMIT }}



  
  postfix:
    image: eeacms/postfix:2.10-3.8
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
    image: eeacms/rsync:2.3
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
    image: eeacms/matomo-log-analytics:2.3
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
      MATOMO_URL: http://matomo
      MATOMO_TOKEN: "${MATOMO_TOKEN}"
    volumes:
    - matomo_importer:/analytics
    mem_reservation: 512m
    mem_limit: 1g




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
