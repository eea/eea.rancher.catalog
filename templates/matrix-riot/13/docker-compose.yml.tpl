version: "2"
services:
  matrix:
    image: eeacms/matrix-synapse:1.98.0-1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
    volumes:
      - {{.Values.SYNAPSE_VOLUME}}:/data
    environment:
      SERVER_NAME:  "${MATRIX_SERVER_NAME}"
      REPORT_STATS: "no"
      DATABASE: postgresql
      POSTGRES_HOST: db
      DB_NAME: "${POSTGRES_DBNAME}"
      DB_USER: "${POSTGRES_DBUSER}"
      DB_PASSWORD: "${POSTGRES_DBPASS}"
      EMAIL_FROM: "${MATRIX_EMAIL_FROM_NAME} <${MATRIX_EMAIL_FROM_ADDRESS}>"
      RIOT_BASE_URL: "${RIOT_URL}"
      PUBLIC_BASE_URL: "${MATRIX_URL}"
      REGISTRATION_ENABLED: "no"
      SMTP_HOST: postfix
      SMTP_PORT: 25
      turnkey: "${TURNKEY}"
      TURN_SERVER_NAME: "${TURN_REALM}"
      MXISD_TOKEN: "${SYNAPSE_MXISD_HSTOKEN}"
      MXISD_AS_TOKEN: "${SYNAPSE_MXISD_ASTOKEN}"
    command: start
    mem_limit: 2048m
    mem_reservation: 1024m
    links:
      - postfix:postfix
      - db:db


  identity:
    image: eeacms/matrix-identity:2.5.0-1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
      - {{.Values.MXISD_VOLUME}}:/var/ma1sd
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

  coturn:
    image: coturn/coturn:4.6.2
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${TURN_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    ports:
    - 3478:3478/tcp
    - 5349:5349/tcp
    - 3478:3478/udp
    - 5349:5349/udp
    command:
    - -n
    - --use-auth-secret
    - --allowed-peer-ip=10.0.0.1
    - --no-tcp-relay
    - --user-quota=12
    - --total-quota=1200
    - --log-file=stdout
    - --static-auth-secret="${TURNKEY}"
    - --realm="${TURN_REALM}"

  db:
    image: eeacms/postgres:14.7-1.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
      - {{.Values.DB_VOLUME}}:/var/lib/postgresql/data
    environment:
      TZ: "${TZ}"
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DBUSER: "${POSTGRES_DBUSER}"
      POSTGRES_DBPASS: "${POSTGRES_DBPASS}"
      POSTGRES_DBNAME: "${POSTGRES_DBNAME}"
      POSTGRES_DBPARAMS: "--lc-collate=C --template=template0 --lc-ctype=C"
      POSTGRES_CONFIG_SHARED_BUFFERS: 1GB
    mem_limit: 3g
    mem_reservation: 2g


  element:
    image: eeacms/matrix-element:1.11.55-1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      TZ: "${TZ}"
      HOME_SERVER_URL:  "${MATRIX_URL}"
      IDENTITY_SERVER_URL: "${MATRIX_IDENTITY_URL}"
      DOMAIN: "${MATRIX_SERVER_NAME}"
    links:
      - matrix:matrix
      - identity:identity
    mem_limit: 1g
    mem_reservation: 512m


  postfix:
    image: eeacms/postfix:3.5-1.0
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
    mem_limit: 128m
    mem_reservation: 128m

  federation:
    image: nginx:1-alpine
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${BACKEND_HOST_LABELS}
    mem_limit: 64m
    mem_reservation: 64m    
    environment:
      TZ: "${TZ}"
      MATRIX_SERVER_NAME: "${MATRIX_SERVER_NAME}"
    command:
    - /bin/sh
    - -c
    - 'mkdir -p /usr/share/nginx/html/.well-known/matrix/; echo "{ \"m.server\": \"${MATRIX_SERVER_NAME}:443\"}" > /usr/share/nginx/html/.well-known/matrix/server ; nginx -g "daemon off;"'


volumes:
  {{.Values.SYNAPSE_VOLUME}}:
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
