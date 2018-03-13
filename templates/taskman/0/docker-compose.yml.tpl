version: "2"
services:
  redmine:
    image: eeacms/redmine:test
    labels:
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
      eu.europa.eionet.taskman: "yes"
      io.rancher.container.hostname_override: container_name
      io.rancher.container.pull_image: always
    {{- if (.Values.EXPOSE_PORT)}}
    ports:
      - "${EXPOSE_PORT}:3000"
    {{- end}}   
    volumes:
      - redmine-files:/usr/src/redmine/files
      - redmine-tmp:/usr/src/redmine/tmp
      - redmine-plugins:/usr/src/redmine/plugins
      - redmine-github:/var/local/redmine/github/
      - redmine-plugins-zip:/install_plugins
    environment:
      TZ: "${TZ}"
      SYNC_API_KEY: "${SYNC_API_KEY}"
      SYNC_REDMINE_URL: "${REDMINE_URL}/sys/fetch_changesets?key=%s"
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
      REDMINE_HOST: "${REDMINE_HOST}"
    depends_on:
    - mysql
    - postfix
    - memcached

  mysql:
    image: mysql:5.7.10
    labels:
      eu.europa.eionet.taskman: "yes"
      io.rancher.scheduler.affinity:host_label: ${REDMINE_DB_LABEL}
    volumes:
    - mysql-data:/var/lib/mysql
    environment:
      TZ: "${TZ}"
      MYSQL_DATABASE: "${DB_NAME}"
      MYSQL_USER: "${DB_USERNAME}"
      MYSQL_PASSWORD: "${DB_PASSWORD}"
      MYSQL_ROOT_PASSWORD: "${DB_ROOT_PASSWORD}"
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
    image: eeacms/mysql-backup
    labels:
      eu.europa.eionet.taskman: "yes"
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${REDMINE_DB_LABEL}
    links:
     - mysql:db
    volumes:
     - mysql-data-backup:/db
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
  {{- else}}
  postfix:
    image: eeacms/postfix:2.10-3.1
    labels:
      eu.europa.eionet.taskman: "yes"
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
      io.rancher.container.hostname_override: container_name
    environment:
      TZ: "${TZ}"
      MTP_HOST: "rancher-alarms.eea.europa.eu"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"
  {{- end}}

  memcached:
    image: memcached:1.4.36
    labels:
      eu.europa.eionet.taskman: "yes"
      io.rancher.scheduler.affinity:host_label: ${REDMINE_SERVER_LABEL}
      io.rancher.container.hostname_override: container_name
    environment:
      TZ: "${TZ}"
    command:
    - "-m"
    - "2048"

volumes:
  redmine-files:
    driver: ${RDM_FILES_VOLUMEDRIVER}
    {{- if .Values.RDM_FILES_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.RDM_FILES_VOLUMEDRIVER_OPTS}}
    {{- end}}
  redmine-github:
    driver: ${RDM_GITHUB_VOLUMEDRIVER}
    {{- if .Values.RDM_GITHUB_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.RDM_GITHUB_VOLUMEDRIVER_OPTS}}
    {{- end}}
  redmine-tmp:
    driver: ${RDM_SMALL_VOLUMEDRIVER}
    {{- if .Values.RDM_SMALL_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.RDM_SMALL_VOLUMEDRIVER_OPTS}}
    {{- end}}
  redmine-plugins:
    driver: ${RDM_SMALL_VOLUMEDRIVER}
    {{- if .Values.RDM_SMALL_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.RDM_SMALL_VOLUMEDRIVER_OPTS}}
    {{- end}}
  redmine-plugins-zip:
    driver: ${RDM_SMALL_VOLUMEDRIVER}
    {{- if .Values.RDM_SMALL_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.RDM_SMALL_VOLUMEDRIVER_OPTS}}
    {{- end}}
  mysql-data:
    driver: ${MYSQL_VOLUMEDRIVER}
    {{- if .Values.MYSQL_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.MYSQL_VOLUMEDRIVER_OPTS}}
    {{- end}}
  mysql-backup-data:
    driver: ${MYSQL_VOLUMEDRIVER}
    {{- if .Values.MYSQL_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.MYSQL_VOLUMEDRIVER_OPTS}}
    {{- end}}



