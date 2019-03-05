version: "2"
services:
  matrix:
    image: eeacms/matrix-synapse:v0.34-1.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    {{- if (.Values.VOIP_PORT)}}
      io.rancher.scheduler.affinity:host_label: ${FRONTEND_HOST_LABELS}
    ports:
      - "${VOIP_PORT}:3478"
    {{- else}}
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
    {{- end}}
    volumes:
      - matrix-synapse:/data
    environment:
      SERVER_NAME:  "${MATRIX_SERVER_NAME}"
      REPORT_STATS: "${MATRIX_REPORT_STATS}"
      DATABASE: postgresql
      POSTGRES_HOST: db
      DB_NAME: "${POSTGRES_DBNAME}"
      DB_USER: "${POSTGRES_DBUSER}"
      DB_PASSWORD: "${POSTGRES_DBPASS}"
      EMAIL_FROM: "${MATRIX_EMAIL_FROM_NAME} <${MATRIX_EMAIL_FROM_ADDRESS}>"
      RIOT_BASE_URL: "${RIOT_URL}"
      PUBLIC_BASE_URL: "${MATRIX_SERVER_NAME}"
      REGISTRATION_ENABLED: "no"
      SMTP_HOST: postfix
      SMTP_PORT: 25
      MXISD_TOKEN: "${SYNAPSE_MXISD_HSTOKEN}"
      MXISD_AS_TOKEN: "${SYNAPSE_MXISD_ASTOKEN}"
    command: start
    mem_limit: 2048m
    mem_reservation: 1024m
    links:
      - postfix:postfix
      - db:db


  identity:
    image: eeacms/matrix-mxisd:1.3-1.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
      - matrix-mxisd:/var/mxisd
    environment:
      MATRIX_DOMAIN: "${MATRIX_SERVER_NAME}"
      LDAP_HOST: "${LDAP_HOST}"
      LDAP_BINDDN: "${LDAP_BINDDN}"
      LDAP_BINDDN_PASS: "${LDAP_BINDDN_PASS}"
      LDAP_FILTER: "${LDAP_FILTER}"
      LDAP_BASEDN:  "${LDAP_BASEDN}"
      LDAP_PORT:  "${LDAP_PORT}"
      LDAP_TLS: "${LDAP_TLS}"
      JAVA_OPTS: "${JAVA_OPTS}"
      SMTP_HOST: postfix
      SMTP_PORT: 25
      IDENTITY_EMAIL_FROM: "${MATRIX_EMAIL_FROM_ADDRESS}"
      IDENTITY_EMAIL_NAME: "${MATRIX_EMAIL_FROM_NAME}"
      POSTGRES_DBUSER: "${POSTGRES_DBUSER}"
      POSTGRES_DBPASS: "${POSTGRES_DBPASS}"
      POSTGRES_DBNAME: "${POSTGRES_DBNAME}"
      MXISD_RIOT_URL: "${RIOT_URL}"
      HOMESERVER_MXISD_TOKEN: "${SYNAPSE_MXISD_HSTOKEN}"
      HOMESERVER_MXISD_AS_TOKEN: "${SYNAPSE_MXISD_ASTOKEN}"
    mem_limit: 1024m
    mem_reservation: 512m
    links:
      - postfix:postfix

  db:
    image: eeacms/postgres:9.6-3.5
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
      - matrix-db:/var/lib/postgresql/data
    environment:
      TZ: "${TZ}"
      POSTGRES_DBUSER: "${POSTGRES_DBUSER}"
      POSTGRES_DBPASS: "${POSTGRES_DBPASS}"
      POSTGRES_DBNAME: "${POSTGRES_DBNAME}"
      POSTGRES_DBPARAMS: "--lc-collate=C --template=template0 --lc-ctype=C"
      POSTGRES_CONFIG_SHARED_BUFFERS: 1GB
    mem_limit: 1024m
    mem_reservation: 512m


  riot:
    image: eeacms/matrix-riotweb:1.0-1.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      TZ: "${TZ}"
      HOME_SERVER_URL:  "${MATRIX_URL}"
      IDENTITY_SERVER_URL: "${MATRIX_IDENTITY_URL}"
    links:
      - matrix:matrix
      - identity:identity
    mem_limit: 512m
    mem_reservation: 62m


  postfix:
    image: eeacms/postfix:2.10-3.3
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      TZ: "${TZ}"
      MTP_HOST: "${MATRIX_SERVER_NAME}"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"
    mem_limit: 124m
    mem_reservation: 62m


volumes:
  matrix-synapse:
    driver: ${SYNAPSE_VOLUME_DRIVER}
    {{- if eq .Values.SYNAPSE_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.SYNAPSE_VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.SYNAPSE_VOLUME_DRIVER_OPTS}}
    {{- end}}
  matrix-mxisd:
    driver: ${MXISD_VOLUME_DRIVER}
    {{- if eq .Values.MXISD_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.MXISD_VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.MXISD_VOLUME_DRIVER_OPTS}}
    {{- end}}
  matrix-db:
    driver: ${DB_VOLUME_DRIVER}
    {{- if eq .Values.DB_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.DB_VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.DB_VOLUME_DRIVER_OPTS}}
    {{- end}}
