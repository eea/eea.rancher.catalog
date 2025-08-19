version: '2'
services:

  exporter:
    image: eeacms/redmine-wikiman:2.1.5
    environment:
      - "RANCHER_CONFIG=${RANCHER_CONFIG}"
      - "WIKI_SERVER=${WIKI_SERVER}"
      - "WIKI_APIKEY=${WIKI_APIKEY}"
      - "WIKI_PROJECT=${WIKI_PROJECT}"
      - "WIKI_HOSTS_PAGE=${WIKI_HOSTS_PAGE}"
      - "WIKI_STACKS_PAGE=${WIKI_STACKS_PAGE}"
      - "WIKI_CONTAINERS_PAGE=${WIKI_CONTAINERS_PAGE}"
      - "WIKI_PAGE=Applications"
      - "SVN_USER=${SVN_USER}"
      - "SVN_PASSWORD=${SVN_PASSWORD}"
      - "DEBUG_ON=${DEBUG_ON}"
      - "TZ=${TZ}"
      - "GITHUB_TOKEN=${GITHUB_TOKEN}"
      - "DOCKERHUB_USER=${DOCKERHUB_USER}"
      - "DOCKERHUB_PASS=${DOCKERHUB_PASS}"
      - "GITLAB_CONFIG=${GITLAB_CONFIG}"
      - "ENV_PATH=${ENV_PATH}"
    volumes:
    - {{.Values.DATA_VOLUME}}:/data
    - {{.Values.LOGS_VOLUME}}:/logs
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.start_once: 'true'
      cron.schedule: ${RUN_SCHEDULE}
    mem_reservation: 256m
    mem_limit: 256m

volumes:
  {{.Values.DATA_VOLUME}}:
    driver: ${DATA_VOLUMEDRIVER}
    {{- if eq .Values.DATA_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.DATA_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.DATA_VOLUMEDRIVER_OPTS}}
    {{- end}}
  {{.Values.LOGS_VOLUME}}:
    driver: ${LOGS_VOLUMEDRIVER}
    {{- if eq .Values.LOGS_VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.LOGS_VOLUMEDRIVER_OPTS}}
    driver_opts:
      {{.Values.LOGS_VOLUMEDRIVER_OPTS}}
    {{- end}}
