version: '2'
services:
  cachet:
    image: cachethq/docker:2.3.15 
    links:
      - postgres:postgres
    environment:
      - DB_DRIVER=pgsql
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_DATABASE=${POSTGRES_DB}
      - DB_USERNAME=${POSTGRES_USER}
      - DB_PASSWORD=${POSTGRES_PASSWORD}
      - DB_PREFIX=chq_
      - APP_KEY=${CACHET_KEY}
      - APP_LOG=errorlog
      - TZ=${TZ}
      - DEBUG=${DEBUG_ON}
    labels:
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.hostname_override: container_name
    
  postgres:
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.DB_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${DB_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    image: eeacms/postgres:9.6
    volumes:
      - postgresdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DBUSER:  ${POSTGRES_USER}
      POSTGRES_DBPASS:  ${POSTGRES_PASSWORD}
      POSTGRES_DBNAME:  ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_ADMIN_USER}
      POSTGRES_PASSWORD: ${POSTGRES_ADMIN_PASSWORD}
      TZ: ${TZ}
    mem_limit: 512m
    mem_reservation: 512m


  postfix:
    image: eeacms/postfix:2.10-3.3
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    environment:
      TZ: "${TZ}"
      MTP_HOST: "${CACHET_SERVER_NAME}"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"
    mem_limit: 124m
    mem_reservation: 62m


  cachet-monitor:
    image: eeacms/cachet-monitor
    depends_on: cachet
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    environment:
      CONFIG: "${CONFIG}"
      CACHET_API: http://cachet:8000/api/v1
      CACHET_TOKEN: "${CACHET_MONITOR_TOKEN}"
      CACHET_DEV: "${DEBUG_ON}"



volumes:
  postgresdata:
    driver: ${DB_STORAGE_DRIVER}
    {{- if .Values.DB_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.DB_STORAGE_DRIVER_OPT}}
    {{- end}}
