version: "2"
services:
  sentry:
    image: eeacms/sentry:9.0-1.0
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.sentry_host_labels}}
      io.rancher.scheduler.affinity:host_label: ${sentry_host_labels}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      sentry: "true"
      master: "true"
    environment:
      SENTRY_EMAIL_HOST: "postfix"
      SENTRY_EMAIL_PORT: "25"
      SENTRY_SECRET_KEY: "${sentry_secret_key}"
      SENTRY_SERVER_EMAIL: "${sentry_server_email}"
      SENTRY_POSTGRES_HOST: "postgres"
      SENTRY_DB_NAME: "${sentry_db_name}"
      SENTRY_DB_USER: "${sentry_db_user}"
      SENTRY_DB_PASSWORD: "${sentry_db_pass}"
      SENTRY_SINGLE_ORGANIZATION: "${sentry_single_organization}"
      GITHUB_APP_ID: "${sentry_github_app_id}"
      GITHUB_API_SECRET: "${sentry_github_api_secret}"
      TZ: "${TZ}"
    mem_limit: ${sentry_mem_limit}
    mem_reservation: ${sentry_mem_reservation} 
    volumes:
    {{- if (.Values.sentryconf_volume) }}
    - ${sentryconf_volume}:/etc/sentry
    {{- else}}
    - sentryconf:/etc/sentry
    {{- end}}
    {{- if (.Values.sentryfiles_volume) }}
    - ${sentryfiles_volume}:/var/lib/sentry/files
    {{- else}}
    - sentryfiles:/var/lib/sentry/files
    {{- end}}
    command:
    - "/bin/bash"
    - "-c"
    - "sentry upgrade --noinput && sentry createuser --email ${sentry_initial_user_email} --password ${sentry_initial_user_password} --superuser && /entrypoint.sh run web || /entrypoint.sh run web"
    depends_on:
    - postgres
    - redis
    - postfix
    - memcached
    links:
    - postgres:postgres
    - redis:redis
    - postfix:postfix
    - memcached:memcached


  worker:
    image: eeacms/sentry:9.0-1.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      sentry: "true"
      worker: "true"
    environment:
      SENTRY_EMAIL_HOST: "postfix"
      SENTRY_EMAIL_PORT: "25"
      SENTRY_SECRET_KEY: "${sentry_secret_key}"
      SENTRY_SERVER_EMAIL: "${sentry_server_email}"
      SENTRY_POSTGRES_HOST: "postgres"
      SENTRY_DB_NAME: "${sentry_db_name}"
      SENTRY_DB_USER: "${sentry_db_user}"
      SENTRY_DB_PASSWORD: "${sentry_db_pass}"
      SENTRY_SINGLE_ORGANIZATION: "${sentry_single_organization}"
      GITHUB_APP_ID: "${sentry_github_app_id}"
      GITHUB_API_SECRET: "${sentry_github_api_secret}"
      TZ: "${TZ}"
    volumes:
    {{- if (.Values.sentryconf_volume) }}
    - ${sentryconf_volume}:/etc/sentry
    {{- else}}
    - sentryconf:/etc/sentry
    {{- end}}
    {{- if (.Values.sentryfiles_volume) }}
    - ${sentryfiles_volume}:/var/lib/sentry/files
    {{- else}}
    - sentryfiles:/var/lib/sentry/files
    {{- end}}
    mem_limit: ${worker_mem_limit}
    mem_reservation: ${worker_mem_reservation}
    command:
    - "run"
    - "worker"
    depends_on:
    - postgres
    - redis
    - postfix
    - memcached
    links:
    - postgres:postgres
    - redis:redis
    - postfix:postfix
    - memcached:memcached

  cron:
    image: eeacms/sentry:9.0-1.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      sentry: "true"
      cron: "true"
    environment:
      SENTRY_EMAIL_HOST: "postfix"
      SENTRY_EMAIL_PORT: "25"
      SENTRY_SECRET_KEY: "${sentry_secret_key}"
      SENTRY_SERVER_EMAIL: "${sentry_server_email}"
      SENTRY_POSTGRES_HOST: "postgres"
      SENTRY_DB_NAME: "${sentry_db_name}"
      SENTRY_DB_USER: "${sentry_db_user}"
      SENTRY_DB_PASSWORD: "${sentry_db_pass}"
      SENTRY_SINGLE_ORGANIZATION: "${sentry_single_organization}"
      GITHUB_APP_ID: "${sentry_github_app_id}"
      GITHUB_API_SECRET: "${sentry_github_api_secret}"
      TZ: "${TZ}"
    mem_limit: ${cron_mem_limit}
    mem_reservation: ${cron_mem_reservation}
    command:
    - "run"
    - "cron"
    volumes:
    {{- if (.Values.sentryconf_volume) }}
    - ${sentryconf_volume}:/etc/sentry
    {{- else}}
    - sentryconf:/etc/sentry
    {{- end}}
    {{- if (.Values.sentryfiles_volume) }}
    - ${sentryfiles_volume}:/var/lib/sentry/files
    {{- else}}
    - sentryfiles:/var/lib/sentry/files
    {{- end}}
    depends_on:
    - postgres
    - redis
    - postfix
    - memcached
    links:
    - postgres:postgres
    - redis:redis
    - postfix:postfix
    - memcached:memcached

  postgres:
    image: eeacms/postgres:9.6-3.5
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.sentry_host_labels}}
      io.rancher.scheduler.affinity:host_label: ${sentry_host_labels}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      sentry: "true"
      postgres: "true"
    environment:
      POSTGRES_DB: "${sentry_db_name}"
      POSTGRES_USER: "${sentry_db_user}"
      POSTGRES_PASSWORD: "${sentry_db_pass}"
      POSTGRES_CRONS: "${sentry_db_crons}"
      TZ: "${TZ}"
    mem_limit: ${db_mem_limit}
    mem_reservation: ${db_mem_reservation}
    volumes:
    {{- if (.Values.sentrypostgres_volume) }}
    - ${sentrypostgres_volume}:/var/lib/postgresql/data
    {{- else}}
    - sentrypostgres:/var/lib/postgresql/data
    {{- end}}
    {{- if (.Values.sentrybackup_volume) }}
    - ${sentrybackup_volume}:/postgresql.backup
    {{- else}}
    - sentrybackup:/postgresql.backup
    {{- end}}

  redis:
    image: redis:3.2.12
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.sentry_host_labels}}
      io.rancher.scheduler.affinity:host_label: ${sentry_host_labels}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      sentry: "true"
      redis: "true"
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
    {{- if (.Values.redisdata_volume) }}
    - ${redisdata_volume}:/data
    {{- else}}
    - redisdata:/data
    {{- end}}
    environment:
      TZ: "${TZ}"
    mem_limit: ${redis_mem_limit}
    mem_reservation: ${redis_mem_reservation}

  postfix:
    image: eeacms/postfix:2.10-3.4
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      sentry: "true"
      postfix: "true"
    environment:
      MTP_HOST: "${sentry_server_name}"
      MTP_RELAY: "ironports.eea.europa.eu"
      MTP_PORT: "8587"
      MTP_USER: "${sentry_email_user}"
      MTP_PASS: "${sentry_email_password}"
      TZ: "${TZ}"
    mem_limit: ${postfix_mem_limit}
    mem_reservation: ${postfix_mem_reservation}

  memcached:
    image: memcached:1.5.16
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      sentry: "true"
      memcached: "true"
    environment:
      TZ: "${TZ}"
    mem_limit: ${memcached_mem_limit}
    mem_reservation: ${memcached_mem_reservation}
    command:
    - "-m"
    - "2048"

volumes:
  {{- if (.Values.sentryconf_volume) }}
  {{.Values.sentryconf_volume}}:
    external: yes
  {{- else}}
  sentryconf:
  {{- end}} 
    driver: ${sentry_config_driver}
    driver_opts:
      {{.Values.sentry_config_driver_opt}}
  {{- if (.Values.sentryfiles_volume) }}
  {{.Values.sentryfiles_volume}}:
    external: yes
  {{- else}}
  sentryfiles:
  {{- end}}
    driver: ${sentry_upload_driver}
    driver_opts:
      {{.Values.sentry_upload_driver_opt}}
  {{- if (.Values.sentrypostgres_volume) }}
  {{.Values.sentrypostgres_volume}}:
    external: yes
  {{- else}}
  sentrypostgres:
  {{- end}}
    driver: ${sentry_storage_driver}
    driver_opts:
      {{.Values.sentry_storage_driver_opt}}
  {{- if (.Values.sentrybackup_volume) }}
  {{.Values.sentrybackup_volume}}:
    external: yes
  {{- else}}
  sentrybackup:
  {{- end}}
    driver: ${sentry_backup_driver}
    driver_opts:
      {{.Values.sentry_backup_driver_opt}}
  {{- if (.Values.redisdata_volume) }}
  {{.Values.redisdata_volume}}:
    external: yes
  {{- else}}
  redisdata:
  {{- end}}
    driver: ${sentry_redis_driver}
    driver_opts:
      {{.Values.sentry_redis_driver_opt}}




