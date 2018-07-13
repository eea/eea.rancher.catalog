version: "2"
services:
  apache:
    image: eeacms/apache:2.4-2.3
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      APACHE_CONFIG: |-
        <VirtualHost *:80>
          ServerName eggrepo.apps.eea.europa.eu
          RewriteEngine On
          RewriteRule ^(.*)$$ https://${SERVER_NAME}$$1 [R=permanent,L]
        </VirtualHost>
        <VirtualHost *:80>
          ServerAdmin helpdesk@eea.europa.eu
          ServerName ${SERVER_NAME}
          <LocationMatch "^/(?!(simple|pypi|(.+)\.gif|(.+)\.jpg|(.+)\.css|(.+)\.gz|(.+)\.zip))">

            AuthBasicProvider ldap
            AuthName        pypi
            AuthType        Basic
            AuthLDAPUrl ldaps://ldap.eionet.europa.eu/ou=Users,o=Eionet,l=Europe?uid
            <Limit POST>
              Require valid-user
            </Limit>

          </LocationMatch>

          RewriteEngine On
          RewriteRule ^/pypi(.*) http://pypi.python.org/simple$$1 [R=permanent,L]

          ProxyPass / http://eggrepo:9090/
          ProxyPassReverse / http://eggrepo:9090/

        </VirtualHost>
      TZ: "${TZ}"
    depends_on:
    - eggrepo

  eggrepo:
    image: eeacms/cluereleasemanager:2.1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    volumes:
    - eggrepo:/var/local/eggrepo
    environment:
      TZ: "${TZ}"

{{- if eq .Values.VOLUME_DRIVER "rancher-ebs"}}

volumes:
  eggrepo:
    driver: ${VOLUME_DRIVER}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}

{{- end}}
