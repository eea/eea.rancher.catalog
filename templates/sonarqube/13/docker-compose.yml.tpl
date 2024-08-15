version: '2'
services:
  sonarqube:
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.sidekicks: es-sysctl
    image: sonarqube:10.6.0-community 
    environment:
      TZ: ${TZ}
    volumes:
      - ${volume_sonarqubedata}:/opt/sonarqube/data
      - ${volume_sonarqubeextensions}:/opt/sonarqube/extensions
    depends_on:
      - db
      - postfix
      - es-sysctl
    command:
      - -Dsonar.jdbc.username={{.Values.POSTGRES_USER}}
      - -Dsonar.jdbc.password={{.Values.POSTGRES_PASSWORD}}
      - -Dsonar.jdbc.url=jdbc:postgresql://db/{{.Values.POSTGRES_DB}}
      {{- if .Values.SONARQUBE_WEB_JVM_OPTS }}
      - -Dsonar.ce.javaOpts={{.Values.SONARQUBE_WEB_JVM_OPTS}}
      {{- end}}
    mem_limit: 3g
    mem_reservation: 3g
    
  es-sysctl:
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    network_mode: none
    image: eeacms/alpine-sysctl:0.3
    privileged: true
    mem_limit: 32m
    mem_reservation: 32m
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
    image: eeacms/postgres:14.13-2.1 
    volumes:
      - ${volume_postgresdata}:/var/lib/postgresql/data
    environment:
      POSTGRES_DBUSER:  ${POSTGRES_USER}
      POSTGRES_DBPASS:  ${POSTGRES_PASSWORD}
      POSTGRES_DBNAME:  ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_ADMIN_USER}
      POSTGRES_PASSWORD: ${POSTGRES_ADMIN_PASSWORD}
      TZ: ${TZ}
    mem_limit: 2g
    mem_reservation: 2g



  postfix:
    image: eeacms/postfix:3.5-1.0
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
    mem_limit: 256m
    mem_reservation: 256m


volumes:
  {{.Values.volume_postgresdata}}:
    {{- if eq .Values.VOLUMES_EXTERNAL "Yes"}} 
    external: true
    {{- end}}
    driver: ${DB_STORAGE_DRIVER}
    {{- if .Values.DB_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.DB_STORAGE_DRIVER_OPT}}
    {{- end}}
  {{.Values.volume_sonarqubedata}}:
    driver: ${FRONT_STORAGE_DRIVER}
    {{- if eq .Values.VOLUMES_EXTERNAL "Yes"}}
    external: true
    {{- end}}
    {{- if .Values.FRONT_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.FRONT_STORAGE_DRIVER_OPT}}
    {{- end}}
  {{.Values.volume_sonarqubeextensions}}:
    driver: ${FRONT_STORAGE_DRIVER}
    {{- if eq .Values.VOLUMES_EXTERNAL "Yes"}}
    external: true
    {{- end}}
    {{- if .Values.FRONT_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.FRONT_STORAGE_DRIVER_OPT}}
    {{- end}}
