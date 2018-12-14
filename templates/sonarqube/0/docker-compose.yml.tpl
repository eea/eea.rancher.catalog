version: '2'
services:
  sonarqube:
    labels:
      io.rancher.container.hostname_override: container_name
    image: sonarqube:7.4-community
    environment:
      SONARQUBE_WEB_JVM_OPTS: ${JVM_OPTS}
      sonar.jdbc.username: ${POSTGRES_USER}
      sonar.jdbc.password: ${POSTGRES_PASSWORD}
      sonar.jdbc.url: jdbc:postgresql://db/${POSTGRES_DB}
      TZ: ${TZ}
    volumes:
      - sonarqube-data:/opt/sonarqube/data
      - sonarqube-extensions:/opt/sonarqube/extensions
    depends_on:
      - db

  db:
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.DB_HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${DB_HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
    image: eeacms/postgres:9.6
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DBUSER:  ${POSTGRES_USER}
      POSTGRES_DBPASS:  ${POSTGRES_PASSWORD}
      POSTGRES_DBNAME:  ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_ADMIN_USER}
      POSTGRES_PASSWORD: ${POSTGRES_ADMIN_PASSWORD}
      TZ: ${TZ}
    mem_limit: 512m
    mem_reservation: 256m

volumes:
  postgres-data:
    driver: ${DB_STORAGE_DRIVER}
    {{- if .Values.DB_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.DB_STORAGE_DRIVER_OPT}}
    {{- end}}
  sonarqube-data:
    driver: ${FRONT_STORAGE_DRIVER}
    {{- if .Values.FRONT_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.FRONT_STORAGE_DRIVER_OPT}}
    {{- end}}
  sonarqube-extensions:
    driver: ${FRONT_STORAGE_DRIVER}
    {{- if .Values.FRONT_STORAGE_DRIVER_OPT}}
    driver_opts:
      {{.Values.FRONT_STORAGE_DRIVER_OPT}}
    {{- end}}
