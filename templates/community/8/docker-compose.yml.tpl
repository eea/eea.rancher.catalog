version: "2"
services:
  apache:
    image: eeacms/apache:2.4-2.2
    mem_reservation: 128m
    mem_limit: 256m
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    depends_on:
    - haproxy
    links:
    - haproxy
    environment:
       APACHE_CONFIG: |-
         Listen 8443
         <VirtualHost *:80>
            ServerName community.apps.eea.europa.eu
            RewriteEngine On
            RewriteRule ^(.*)$$ https://${SERVER_NAME}$$1 [R=permanent,L]
         </VirtualHost>
         <VirtualHost *:80>
            ServerName ${SERVER_NAME}
            RewriteEngine On
            RewriteRule ^(.*)$$ https://${SERVER_NAME}$$1 [R=permanent,L]
         </VirtualHost>
         <VirtualHost *:8443>
            ServerName ${SERVER_NAME}

            RewriteEngine On

            LimitRequestBody 104857600
            RequestHeader set Host "%{HTTP_HOST}s"
            RequestHeader set X-Real-IP "%{REMOTE_ADDR}s"
            RequestHeader set X-Forwarded-For "%{X-Forwarded-For}s"
            RequestHeader set X-Forwarded-Proto https
            RequestHeader set X-Frame-Options SAMEORIGIN

            RewriteRule ^/(.*) http://haproxy:8080/VirtualHostBase/https/${SERVER_NAME}:443/cynin/VirtualHostRoot/$$1 [P,L]
         </VirtualHost>
       TZ: "${TZ}"

  haproxy:
    image: eeacms/haproxy:1.7-4.0
    mem_reservation: 64m
    mem_limit: 128m
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    depends_on:
    - cynin
    links:
    - cynin
    environment:
     BACKENDS: "cynin"
     FRONTEND_PORT: "8080"
     BACKENDS_PORT: "8080"
     DNS_ENABLED: "True"
     TIMEOUT_SERVER: "120s"
     TIMEOUT_CLIENT: "120s"
     TZ: "${TZ}"

  cynin:
    image: eeacms/cynin:3.3
    mem_reservation: 1g
    mem_limit: 2g
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    depends_on:
    - zeo
    - postfix
    links:
    - zeo
    - postfix
    environment:
      SERVICES: "zope"
      TZ: "${TZ}"

  zeo:
    image: eeacms/cynin:3.3
    mem_reservation: 512m
    mem_limit: 1g
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    environment:
      SERVICES: "zeo"
      TZ: "${TZ}"
    volumes:
    - filestorage:/var/local/community.eea.europa.eu/var/filestorage
    - blobstorage:/var/local/community.eea.europa.eu/var/blobstorage

  postfix:
{{- if eq .Values.MAILTRAP "yes"}}
    image: eaudeweb/mailtrap
{{- else}}
    image: eeacms/postfix:2.10-3.3
{{- end}}
    mem_reservation: 64m
    mem_limit: 128m
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
    environment:
      MTP_RELAY: "ironports.eea.europa.eu"
      MTP_PORT: "8587"
      MTP_HOST: "${SERVER_NAME}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"
      TZ: "${TZ}"

volumes:
  filestorage:
    driver: ${DATAF_VOLUME_DRIVER}
    driver_opts:
      {{.Values.DATAF_VOLUME_DRIVER_OPTS}}
    {{- if eq .Values.DATAF_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
  blobstorage:
    driver: ${DATAB_VOLUME_DRIVER}
    driver_opts:
      {{.Values.DATAB_VOLUME_DRIVER_OPTS}}
    {{- if eq .Values.DATAB_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}

