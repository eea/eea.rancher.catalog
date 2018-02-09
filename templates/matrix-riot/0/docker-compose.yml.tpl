version: "2"
services:
  matrix:
    image: eeacms/matrix-synapse:v0.26.0
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
      EMAIL_FROM: "${MATRIX_EMAIL_FROM}"
      RIOT_BASE_URL: "${RIOT_URL}"
      PUBLIC_BASE_URL: "${MATRIX_SERVER_NAME}"
      REGISTRATION_ENABLED: "no"
    command: start


  identity:
    image: eeacms/matrix-mxisd:0.6.1-1-g6a5a4b3
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

  db:
    image: eeacms/postgres:9.6-3.1
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

  riot:
    image: eeacms/matrix-riotweb:v0.13.4
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      TZ: "${TZ}"
      HOME_SERVER_URL:  "${MATRIX_URL}"
      IDENTITY_SERVER_URL: "${MATRIX_IDENTITY_URL}"


  postfix:
    image: eeacms/postfix:2.10-3.1
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


{{- if eq .Values.VOLUME_DRIVER "rancher-ebs"}}

volumes:
  matrix-synapse:
    driver: ${VOLUME_DRIVER}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}

  matrix-mxsd:
   driver: ${VOLUME_DRIVER}
   driver_opts:
     {{.Values.VOLUME_DRIVER_OPTS}}

  matrix-db:
    driver: ${VOLUME_DRIVER}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}

{{- end}}
