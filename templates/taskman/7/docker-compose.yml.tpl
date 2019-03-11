version: "2"
services:
  redmine:
    image: eeacms/redmine:3.4.6-1
    labels:
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
      eu.europa.eionet.taskman: "yes"
      io.rancher.container.hostname_override: container_name
    volumes:
    - redmine-files:/usr/src/redmine/files
    - redmine-tmp:/usr/src/redmine/tmp
    - redmine-github:/var/local/redmine/github/
    - redmine-plugins-zip:/install_plugins
    depends_on:
    - mysql
    - postfix
    - memcached
    links:
    - mysql
    - postfix
    - memcached
    mem_reservation: ${RDM_MEMORY_RESERVATION}
    mem_limit: 6g
    environment:
      TZ: "${TZ}"
      SYNC_API_KEY: "${SYNC_API_KEY}"
      SYNC_REDMINE_URL: "http://redmine:3000/sys/fetch_changesets?key=%s"
      REDMINE_DB_MYSQL: "mysql"
      REDMINE_DB_DATABASE: "${DB_NAME}"
      REDMINE_DB_USERNAME: "${DB_USERNAME}"
      REDMINE_DB_PASSWORD: "${DB_PASSWORD}"
      PLUGINS_URL: "${PLUGINS_URL}"
      PLUGINS_USER: "${PLUGINS_USER}"
      PLUGINS_PASSWORD: "${PLUGINS_PASSWORD}"
      T_EMAIL_HOST: "${T_EMAIL_HOST}"
      T_EMAIL_PORT: "${T_EMAIL_PORT}"
      T_EMAIL_USER: "${T_EMAIL_USER}"
      T_EMAIL_PASS: "${T_EMAIL_PASS}"
      HELPDESK_EMAIL_KEY: "${INCOMING_MAIL_API_KEY}"
      H_EMAIL_HOST: "${H_EMAIL_HOST}"
      H_EMAIL_PORT: "${H_EMAIL_PORT}"
      H_EMAIL_USER: "${H_EMAIL_USER}"
      H_EMAIL_PASS: "${H_EMAIL_PASS}"
      REDMINE_HOST: "redmine:3000"

  mysql:
    image: mysql:5.7.21
    labels:
      eu.europa.eionet.taskman: "yes"
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
    volumes:
    - ${MYSQL_VOLUME}:/var/lib/mysql
    environment:
      TZ: "${TZ}"
      MYSQL_DATABASE: "${DB_NAME}"
      MYSQL_USER: "${DB_USERNAME}"
      MYSQL_PASSWORD: "${DB_PASSWORD}"
      MYSQL_ROOT_PASSWORD: "${DB_ROOT_PASSWORD}"
    mem_reservation: 2g
    mem_limit: 3g
    command:
    - "--query-cache-size=0"
    - "--query-cache-limit=64M"
    - "--query-cache-type=0"
    - "--innodb-buffer-pool-size=1G"
    - "--innodb-buffer-pool-instances=4"
    - "--net-read-timeout=7200"
    - "--net-write-timeout=7200"
    - "--max-allowed-packet=128M"
    - "--tmp-table-size=384M"
    - "--max-heap-table-size=384M"
    - "--join-buffer-size=256M"

  mysql-backup:
    image: eeacms/mysql-backup:0.9.0
    labels:
      eu.europa.eionet.taskman: "yes"
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
    depends_on:
    - mysql
    links:
    - mysql:db
    volumes:
    - mysql-data-backup:/db
    mem_reservation: 126m
    mem_limit: 256m
    environment:
      DB_USER: "root"
      DB_PASS: "${DB_ROOT_PASSWORD}"
      DB_DUMP_TARGET: "/db"
      DB_DUMP_FREQ: "${DB_DUMP_FREQ}"
      DB_DUMP_BEGIN: "${DB_DUMP_TIME}"
      DB_DUMP_FILENAME: "${DB_DUMP_FILENAME}"
      DB_DUMP_FILEDATE: "no"

  {{- if eq .Values.TASKMAN_DEV "yes"}}
  postfix:
    image: eaudeweb/mailtrap
    labels:
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
      io.rancher.container.hostname_override: container_name
    {{- if (.Values.EXPOSE_PORT_MAIL)}}
    mem_reservation: 64m
    mem_limit: 126m
    ports:
      - "${EXPOSE_PORT_MAIL}:80"
    {{- end}}
  {{- else}}
  postfix:
    image: eeacms/postfix:2.10-3.3
    labels:
      eu.europa.eionet.taskman: "yes"
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
      io.rancher.container.hostname_override: container_name
    mem_reservation: 64m
    mem_limit: 126m
    environment:
      TZ: "${TZ}"
      MTP_HOST: "taskman.eionet.europa.eu"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"
  {{- end}}

  memcached:
    image: memcached:1.5.8
    labels:
      eu.europa.eionet.taskman: "yes"
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
      io.rancher.container.hostname_override: container_name
    environment:
      TZ: "${TZ}"
    mem_reservation: 32m
    mem_limit: 64m
    command:
    - "-m"
    - "2048"

  apache:
    image: eeacms/apache-taskman:2.4-2.4
    labels:
      io.rancher.scheduler.affinity:host_label: ${REDMINE_FRONT_LABEL}
      eu.europa.eionet.taskman: "yes"
      io.rancher.container.hostname_override: container_name
    {{- if (.Values.EXPOSE_PORT)}}
    ports:
      - "${EXPOSE_PORT}:80"
    {{- end}}
    depends_on:
    - redmine
    mem_reservation: 140m
    mem_limit: 256m
    links:
    - redmine
    environment:
      APACHE_MODULES: "http2_module"
      APACHE_CONFIG: "${APACHE_CONFIG}"
      TZ: "Europe/Copenhagen"


volumes:
  redmine-files:
    driver: ${RDM_FILES_VOLUMEDRIVER}
  redmine-github:
    driver: ${RDM_GITHUB_VOLUMEDRIVER}
  redmine-tmp:
    driver: local
  redmine-plugins-zip:
    driver: local
  {{.Values.MYSQL_VOLUME}}:
    driver: ${MYSQL_VOLUMEDRIVER}
    {{- if .Values.MYSQL_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.MYSQL_VOLUMEDRIVER_OPTS}}
    {{- end}}
  mysql-backup-data:
    driver: ${MYSQL_BACKUP_VOLUMEDRIVER}
