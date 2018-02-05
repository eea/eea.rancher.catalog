version: "2"
services:
   matrix:
    image: eeacms/matrix-synapse
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.container.create_agent: 'true'
      io.rancher.container.agent.role: environment
    command: start
    ports:
      - "8448:8448"
      - "3478:3478"
    volumes:
      - synapse_data:/data
    environment:
      SERVER_NAME:  "${MATRIX_SERVER_NAME}"
      REPORT_STATS: 'yes'
      DATABASE: postgresql
      POSTGRES_HOST: db
      DB_NAME: "${POSTGRES_DBNAME}"
      DB_USER: "${POSTGRES_DBUSER}"
      DB_PASSWORD: "${POSTGRES_DBPASS}"
      EMAIL_FROM: "${MATRIX_EMAIL_FROM}"
      RIOT_BASE_URL: "${RIOT_URL}"
      PUBLIC_BASE_URL: "${MATRIX_SERVER_NAME}"
      REGISTRATION_ENABLED: "no"


  identity:
    image: eeacms/matrix-mxisd
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.container.create_agent: 'true'
      io.rancher.container.agent.role: environment
    volumes:
      - mxisd_configuration:/etc/mxisd
      - mxisd_data:/var/mxisd
    ports:
      - 8090:8090
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
    image: eeacms/postgres
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.container.create_agent: 'true'
      io.rancher.container.agent.role: environment
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      TZ: "${TZ}"
      POSTGRES_DBUSER: "${POSTGRES_DBUSER}"
      POSTGRES_DBPASS: "${POSTGRES_DBPASS}"
      POSTGRES_DBNAME: "${POSTGRES_DBNAME}"
      POSTGRES_DBPARAMS: "--lc-collate=C --template=template0 --lc-ctype=C"

  riot:
    image: eeacms/matrix-riotweb
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.container.create_agent: 'true'
      io.rancher.container.agent.role: environment
    ports:
      - "80:80"
    environment:
      TZ: "${TZ}"
      HOME_SERVER_URL:  "${MATRIX_URL}"
      IDENTITY_SERVER_URL: "${MATRIX_IDENTITY_URL}"


  postfix:
    image: eeacms/postfix:2.10-3.1
    labels:
      io.rancher.container.hostname_override: container_name
    environment:
      TZ: "${TZ}"
      MTP_HOST: "${MATRIX_SERVER_NAME}"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"


{{- if eq .Values.volume_driver "rancher-ebs"}}

volumes:
 synapse_data:
   driver: ${volume_driver}
   driver_opts:
     {{.Values.volume_driver_opts}}

 postgres_data:
   driver: ${volume_driver}
   driver_opts:
     {{.Values.volume_driver_opts}}

 mxsd_data:
   driver: ${volume_driver}
   driver_opts:
     {{.Values.volume_driver_opts}}


{{- end}}



