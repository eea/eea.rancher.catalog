version: '2'
services:

  mariadb:
    image: mariadb:10.6.12
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
    image: eeacms/matomo:4.15.1-5
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
      - "PHP_MAX_INPUT_TIME=0"
      - "APACHE_HTTP_PORT_NUMBER=80"
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.FRONT_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${FRONT_HOST_LABELS}
      {{- else}} 
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    user: root
    depends_on:
      - mariadb
    volumes:
      - matomo_data:/bitnami
      - matomo_geoupdate:/geoupdate
    mem_reservation: {{ .Values.MATOMO_MEM_RES }}
    mem_limit: {{ .Values.MATOMO_MEM_LIMIT }}

  matomocron-archive:
    image: eeacms/matomo:4.15.1-1
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
      - "PHP_MAX_INPUT_TIME=0"
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
    - run_archiving.sh
    mem_reservation: {{ .Values.ARCHIVE_MEM_RES }}
    mem_limit: {{ .Values.ARCHIVE_MEM_LIMIT }}



  matomocron-ldapsync:
    image: eeacms/matomo:4.15.1-1
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
    - run_ldapsync.sh
    mem_reservation: 256m
    mem_limit: 256m

  matomocron-delete-data:
    image: eeacms/matomo:4.15.1-1
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
      - run_delete_data.sh
    mem_reservation: {{ .Values.DEL_MEM_RES }}
    mem_limit: {{ .Values.DEL_MEM_LIMIT }}


  geoipupdate:
    image: maxmindinc/geoipupdate:v4.11
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.start_once: 'true'
      cron.schedule: 0 0 4 5 * *
    environment:
      GEOIPUPDATE_ACCOUNT_ID: $GEOIPUPDATE_ACCOUNT_ID
      GEOIPUPDATE_LICENSE_KEY: $GEOIPUPDATE_LICENSE_KEY
      GEOIPUPDATE_EDITION_IDS: GeoLite2-City
      GEOIPUPDATE_VERBOSE: 1
    volumes:
      - matomo_geoupdate:/usr/share/GeoIP

  
  postfix:
    image: eeacms/postfix:3.5-1.0
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
  matomo_importer:
    external: true
  matomo_ssh-key:
    external: true
  matomo_geoupdate:
    driver: rancher-nfs
    external: true
