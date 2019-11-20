version: '2'
services:

  exporter:
    image: eeacms/redmine-wikiman:1.3
    environment:
      - "RANCHER_CONFIG=${RANCHER_CONFIG}"
      - "WIKI_SERVER=${WIKI_SERVER}"
      - "WIKI_APIKEY=${WIKI_APIKEY}"
      - "WIKI_PROJECT=${WIKI_PROJECT}"
      - "WIKI_HOSTS_PAGE=${WIKI_HOSTS_PAGE}"
      - "WIKI_STACKS_PAGE=${WIKI_STACKS_PAGE}"
      - "WIKI_CONTAINERS_PAGE=${WIKI_CONTAINERS_PAGE}"
      - "WIKI_PAGE=Applications"
      - "SNV_USER=${SVN_USER}"
      - "SNV_PASSWORD=${SVN_PASSWORD}"
      - "DEBUG_ON=${DEBUG_ON}"
      - "TZ=${TZ}"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.start_once: 'true'
      cron.schedule: ${RUN_SCHEDULE}
    mem_reservation: 256m
    mem_limit: 256m

