version: '2'
services:
  sonarqube:
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.sidekicks: es-sysctl
    image: sonarqube:7.9-community
    environment:
      SONARQUBE_WEB_JVM_OPTS: ${JVM_OPTS}
      sonar.jdbc.username: ${POSTGRES_USER}
      sonar.jdbc.password: ${POSTGRES_PASSWORD}
      sonar.jdbc.url: jdbc:postgresql://db/${POSTGRES_DB}
      TZ: ${TZ}
    volumes:
      - ${volume_sonarqubedata}:/opt/sonarqube/data
      - ${volume_sonarqubeextensions}:/opt/sonarqube/extensions
    depends_on:
      - db
      - postfix
      - es-sysctl
    mem_limit: 3g
    mem_reservation: 3g
    
  es-sysctl:
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    network_mode: none
    image: rawmind/alpine-sysctl:0.1
    privileged: true
    mem_limit: 32m
    mem_reservation: 8m
    environment:
      - "SYSCTL_KEY=vm.max_map_count"
      - "SYSCTL_VALUE=262144"
      - "KEEP_ALIVE=1"
            
  db:
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.DB_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${DB_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    image: eeacms/postgres:9.6-3.5
    volumes:
      - ${volume_postgresdata}:/var/lib/postgresql/data
    environment:
      POSTGRES_DBUSER:  ${POSTGRES_USER}
      POSTGRES_DBPASS:  ${POSTGRES_PASSWORD}
      POSTGRES_DBNAME:  ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_ADMIN_USER}
      POSTGRES_PASSWORD: ${POSTGRES_ADMIN_PASSWORD}
      TZ: ${TZ}
    mem_limit: 1g
    mem_reservation: 1g



  postfix:
    image: eeacms/postfix:2.10-3.6
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    environment:
      TZ: "${TZ}"
      MTP_HOST: "${SONARQUBE_SERVER_NAME}"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"
    mem_limit: 124m
    mem_reservation: 124m


volumes:
  ${volume_postgresdata}:
    {{- if eq .Values.VOLUMES_EXTERNAL "Yes"}} 
    external: true
    {{- end}}
    driver: ${DB_STORAGE_DRIVER}
    {{- if .Values.DB_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.DB_STORAGE_DRIVER_OPT}}
    {{- end}}
  ${volume_sonarqubedata}:
    driver: ${FRONT_STORAGE_DRIVER}
    {{- if eq .Values.VOLUMES_EXTERNAL "Yes"}}
    external: true
    {{- end}}
    {{- if .Values.FRONT_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.FRONT_STORAGE_DRIVER_OPT}}
    {{- end}}
  ${volume_sonarqubeextensions}:
    driver: ${FRONT_STORAGE_DRIVER}
    {{- if eq .Values.VOLUMES_EXTERNAL "Yes"}}
    external: true
    {{- end}}
    {{- if .Values.FRONT_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.FRONT_STORAGE_DRIVER_OPT}}
    {{- end}}
