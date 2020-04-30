version: "2"
services:
  redmine:
    image: eeacms/redmine:4.1-1.1
    labels:
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
      eu.europa.eionet.taskman: "yes"
      io.rancher.container.hostname_override: container_name
    volumes:
    - ${REDMINE_FILES}:/usr/src/redmine/files
    - redminetmp:/usr/src/redmine/tmp
    - taskman-redmine-github:/var/local/redmine/github/
    - redmine-pluginzip:/install_plugins
    init: true
    depends_on:
    - mysql
    - postfix
    - memcached
    links:
    - mysql
    - postfix
    - memcached
    mem_reservation: ${RDM_MEMORY_RESERVATION}
    mem_limit: ${RDM_MEMORY_LIMIT}
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
      RESTART_CRON: "${RESTART_CRON}"

  mysql:
    image: mysql:5.7.29
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
    - taskman-mysql-backup-data:/db
    mem_reservation: 512m
    mem_limit: 512m
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
    image: eaudeweb/mailtrap:2.3
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
    image: eeacms/postfix:2.10-3.6
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
    image: memcached:1.6.5
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
    image: eeacms/apache-taskman:2.4-2.6
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

  drawio:
    image: eeacms/redmine-drawio-alpine:12.2-1.0
    labels:
      io.rancher.scheduler.affinity:host_label: ${REDMINE_FRONT_LABEL}
      eu.europa.eionet.taskman: "yes"
      io.rancher.container.hostname_override: container_name
    mem_reservation: 512m
    mem_limit: 512m
    environment:
      TZ: "Europe/Copenhagen"

volumes:
  {{.Values.REDMINE_FILES}}:
    driver: ${RDM_FILES_VOLUMEDRIVER}
    {{- if eq .Values.REDMINE_FILES_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.RDM_FILES_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.RDM_FILES_VOLUMEDRIVER_OPTS}}
    {{- end}}
  taskman-redmine-github:
    external: true
    driver: ${RDM_GITHUB_VOLUMEDRIVER}
  redminetmp:
    driver: {{.Values.REDMINE_SMALL_VOLUMEDRIVER}}
  redmine-pluginzip:
    driver: {{.Values.REDMINE_SMALL_VOLUMEDRIVER}}
  {{.Values.MYSQL_VOLUME}}:
    driver: ${MYSQL_VOLUMEDRIVER}
    {{- if eq .Values.MYSQL_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.MYSQL_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.MYSQL_VOLUMEDRIVER_OPTS}}
    {{- end}}
  taskman-mysql-backup-data:
    external: true
    driver: ${MYSQL_BACKUP_VOLUMEDRIVER}
