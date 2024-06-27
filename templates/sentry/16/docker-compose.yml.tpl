version: "2"
services:
  postfix:
    image: eeacms/postfix:2.10-3.6
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
    image: memcached:1.6.9-alpine
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

  redis:
    image: redis:6.2.4-alpine
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      sentry: "true"
      redis: "true"
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      {{- if (.Values.redisdata_volume) }}
      - ${redisdata_volume}:/data
      {{- else}}
      - redisdata:/data
      {{- end}}
    ulimits:
      nofile:
        soft: 10032
        hard: 10032
    mem_limit: ${redis_mem_limit}
    mem_reservation: ${redis_mem_reservation}

  postgres:
    image: eeacms/sentry-postgres:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      sentry: "true"
      postgres: "true"
    environment:
      POSTGRES_DB: "${sentry_db_name}"
      POSTGRES_USER: "${sentry_db_user}"
      POSTGRES_PASSWORD: "${sentry_db_pass}"
      POSTGRES_CRONS: "${sentry_db_crons}"
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

  zookeeper:
    image: confluentinc/cp-zookeeper:5.5.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    environment:
      ZOOKEEPER_CLIENT_PORT: '2181'
      CONFLUENT_SUPPORT_METRICS_ENABLE: 'false'
      ZOOKEEPER_LOG4J_ROOT_LOGLEVEL: 'WARN'
      ZOOKEEPER_TOOLS_LOG4J_LOGLEVEL: 'WARN'
      KAFKA_OPTS: "-Dzookeeper.4lw.commands.whitelist=ruok"
    volumes:
      - sentry-zookeeper:/var/lib/zookeeper/data
      - sentry-zookeeper-log:/var/lib/zookeeper/log
      - sentry-secrets:/etc/zookeeper/secrets

  kafka:
    image: confluentinc/cp-kafka:5.5.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - zookeeper
    links:
      - zookeeper:zookeeper
    environment:
      KAFKA_ZOOKEEPER_CONNECT: "zookeeper:2181"
      KAFKA_ADVERTISED_LISTENERS: "PLAINTEXT://kafka:9092"
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: "1"
      KAFKA_OFFSETS_TOPIC_NUM_PARTITIONS: "1"
      KAFKA_LOG_RETENTION_HOURS: "24"
      KAFKA_MESSAGE_MAX_BYTES: "50000000" #50MB or bust
      KAFKA_MAX_REQUEST_SIZE: "50000000" #50MB on requests apparently too
      CONFLUENT_SUPPORT_METRICS_ENABLE: "false"
      KAFKA_LOG4J_LOGGERS: "kafka.cluster=WARN,kafka.controller=WARN,kafka.coordinator=WARN,kafka.log=WARN,kafka.server=WARN,kafka.zookeeper=WARN,state.change.logger=WARN"
      KAFKA_LOG4J_ROOT_LOGLEVEL: "WARN"
      KAFKA_TOOLS_LOG4J_LOGLEVEL: "WARN"
    volumes:
      - sentry-kafka:/var/lib/kafka/data
      - sentry-kafka-log:/var/lib/kafka/log
      - sentry-secrets:/etc/kafka/secrets
   
  clickhouse:
    image: yandex/clickhouse-server:20.3.9.70
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    entrypoint:
      - /bin/sh
      - -c
      - echo "<yandex><max_server_memory_usage_to_ram_ratio> <include from_env="MAX_MEMORY_USAGE_RATIO"/> </max_server_memory_usage_to_ram_ratio><logger><level>information</level><console>1</console></logger><merge_tree><enable_mixed_granularity_parts>1</enable_mixed_granularity_parts></merge_tree></yandex>" > /etc/clickhouse-server/config.d/sentry.xml;/entrypoint.sh
    volumes:
      {{- if (.Values.clickhouse_volume) }}
      - {{.Values.clickhouse_volume}}:/var/lib/clickhouse
      {{- else}}
      - sentry-clickhouse:/var/lib/clickhouse
      {{- end}}
      - sentry-clickhouse-log:/var/log/clickhouse-server
    environment:
      MAX_MEMORY_USAGE_RATIO: 0.3    
      
  geoipupdate:
    image: "maxmindinc/geoipupdate:v4.9.0"
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.start_once: 'true'
      cron.schedule: "0 0 4 1 * *"
    environment:
      GEOIPUPDATE_ACCOUNT_ID: $GEOIPUPDATE_ACCOUNT_ID
      GEOIPUPDATE_LICENSE_KEY: $GEOIPUPDATE_LICENSE_KEY
      GEOIPUPDATE_EDITION_IDS: GeoLite2-City
      GEOIPUPDATE_VERBOSE: 1
    volumes:
      - sentry-geoip:/usr/share/GeoIP


  snuba-api:
    image: getsentry/snuba:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
    # Leaving the value empty to just pass whatever is set
    # on the host system (or in the .env file)
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"

  snuba-consumer:
    image: getsentry/snuba:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
    # Leaving the value empty to just pass whatever is set
    # on the host system (or in the .env file)
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: consumer --storage errors --auto-offset-reset=latest --max-batch-time-ms 750


  snuba-outcomes-consumer:
    image: getsentry/snuba:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
    # Leaving the value empty to just pass whatever is set
    # on the host system (or in the .env file)
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: consumer --storage outcomes_raw --auto-offset-reset=earliest --max-batch-time-ms 750

  snuba-sessions-consumer:
    image: getsentry/snuba:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
    # Leaving the value empty to just pass whatever is set
    # on the host system (or in the .env file)
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: consumer --storage sessions_raw --auto-offset-reset=latest --max-batch-time-ms 750

  snuba-transactions-consumer:
    image: getsentry/snuba:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
    # Leaving the value empty to just pass whatever is set
    # on the host system (or in the .env file)
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: consumer --storage transactions --consumer-group transactions_group --auto-offset-reset=latest --max-batch-time-ms 750 --commit-log-topic=snuba-commit-log
    
  snuba-replacer:
    image: getsentry/snuba:22.7.0
    labels:      
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
    # Leaving the value empty to just pass whatever is set
    # on the host system (or in the .env file)
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: replacer --storage errors --auto-offset-reset=latest --max-batch-size 3
    
  snuba-subscription-consumer-events:
    image: getsentry/snuba:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
    # Leaving the value empty to just pass whatever is set
    # on the host system (or in the .env file)
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: subscriptions-scheduler-executor --dataset events --entity events --auto-offset-reset=latest --no-strict-offset-reset --consumer-group=snuba-events-subscriptions-consumers --followed-consumer-group=snuba-consumers --delay-seconds=60 --schedule-ttl=60 --stale-threshold-seconds=900
  
  snuba-subscription-consumer-transactions:
    image: getsentry/snuba:22.7.0
    labels:      
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: subscriptions-scheduler-executor --dataset transactions --entity transactions --auto-offset-reset=latest --no-strict-offset-reset --consumer-group=snuba-transactions-subscriptions-consumers --followed-consumer-group=transactions_group --delay-seconds=60 --schedule-ttl=60 --stale-threshold-seconds=900
    
 
  snuba-cleanup:
    image: getsentry/snuba:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.start_once: 'true'
      cron.schedule: "0 */5 * * * *"
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: 'snuba cleanup --storage errors --dry-run False'
    
  snuba-transactions-cleanup:
    image: getsentry/snuba:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.start_once: 'true'
      cron.schedule: "0 */5 * * * *"
    depends_on:
      - redis
      - clickhouse
      - kafka
    environment:
      SNUBA_SETTINGS: docker
      CLICKHOUSE_HOST: clickhouse
      DEFAULT_BROKERS: "kafka:9092"
      REDIS_HOST: redis
      UWSGI_MAX_REQUESTS: "10000"
      UWSGI_DISABLE_LOGGING: "true"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS"
    command: 'snuba cleanup --storage transactions --dry-run False'



  symbolicator:
    image: getsentry/symbolicator:0.5.1
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
    environment: 
      SYMBOLICATORCONFIG:  |
        # See: https://getsentry.github.io/symbolicator/#configuration
        cache_dir: "/data"
        bind: "0.0.0.0:3021"
        logging:
          level: "warn"
        metrics:
          statsd: null
        sentry_dsn: null # TODO: Automatically fill this with the internal project DSN
    entrypoint: 
      - /bin/bash 
      - -c
      - echo "$$SYMBOLICATORCONFIG" > /etc/symbolicator/config.yml; /bin/bash /docker-entrypoint.sh run -c /etc/symbolicator/config.yml
    volumes:
      - sentry-symbolicator:/data

  symbolicator-cleanup:
    image: getsentry/symbolicator:0.3.4
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.start_once: 'true'
      cron.schedule: "0 55 23 * * *"
    command: 'gosu symbolicator symbolicator cleanup'
    volumes:
      - sentry-symbolicator:/data


  web:
    image: eeacms/sentry:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.pull_image: always
    depends_on:
      - redis
      - postgres
      - memcached
      - postfix
      - snuba-api
      - snuba-consumer
      - snuba-outcomes-consumer
      - snuba-sessions-consumer
      - snuba-transactions-consumer
      - snuba-subscription-consumer-events
      - snuba-subscription-consumer-transactions
      - snuba-replacer
      - symbolicator
      - kafka
    links:
      - redis:redis
      - postgres:postgres
      - postfix:postfix
      - snuba-api:snuba-api
      - symbolicator:symbolicator
      - kafka:kafka
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
      LDAP_SERVER: "${LDAP_SERVER}"
      LDAP_BIND_DN: "${LDAP_BIND_DN}"
      LDAP_BIND_PASSWORD: "${LDAP_BIND_PASSWORD}"
      LDAP_USER_DN: "${LDAP_USER_DN}"
      LDAP_DEFAULT_SENTRY_ORGANIZATION: "${LDAP_DEFAULT_SENTRY_ORGANIZATION}"
      LDAP_LOGLEVEL: "${LDAP_LOGLEVEL}"
      TZ: "${TZ}"
      PYTHONUSERBASE: "/data/custom-packages"
      SENTRY_CONF: "/etc/sentry"
      SNUBA: "http://snuba-api:1218"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS" 
      SENTRY_REDIS_HOST: redis
    volumes:
      - "sentry-geoip:/geoip:ro"
      {{- if (.Values.sentryconf_volume) }}
      - ${sentryconf_volume}:/etc/sentry
      {{- else}}
      - sentryconf:/etc/sentry
      {{- end}}
      {{- if (.Values.sentryfiles_volume) }}
      - ${sentryfiles_volume}:/data
      {{- else}}
      - sentryfiles:/data
      {{- end}}
    command: ["run", "web"]
    
    
  cron:
    image: eeacms/sentry:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.pull_image: always
    depends_on:
      - redis
      - postgres
      - memcached
      - postfix
      - snuba-api
      - snuba-consumer
      - snuba-outcomes-consumer
      - snuba-sessions-consumer
      - snuba-transactions-consumer
      - snuba-subscription-consumer-events
      - snuba-subscription-consumer-transactions
      - snuba-replacer
      - symbolicator
      - kafka
    links:
      - redis:redis
      - postgres:postgres
      - postfix:postfix
      - snuba-api:snuba-api
      - symbolicator:symbolicator
      - kafka:kafka
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
      LDAP_SERVER: "${LDAP_SERVER}"
      LDAP_BIND_DN: "${LDAP_BIND_DN}"
      LDAP_BIND_PASSWORD: "${LDAP_BIND_PASSWORD}"
      LDAP_USER_DN: "${LDAP_USER_DN}"
      LDAP_DEFAULT_SENTRY_ORGANIZATION: "${LDAP_DEFAULT_SENTRY_ORGANIZATION}"
      LDAP_LOGLEVEL: "${LDAP_LOGLEVEL}"
      TZ: "${TZ}"
      PYTHONUSERBASE: "/data/custom-packages"
      SENTRY_CONF: "/etc/sentry"
      SNUBA: "http://snuba-api:1218"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS" 
      SENTRY_REDIS_HOST: redis
    volumes:
      - "sentry-geoip:/geoip:ro"
      {{- if (.Values.sentryconf_volume) }}
      - ${sentryconf_volume}:/etc/sentry
      {{- else}}
      - sentryconf:/etc/sentry
      {{- end}}
      {{- if (.Values.sentryfiles_volume) }}
      - ${sentryfiles_volume}:/data
      {{- else}}
      - sentryfiles:/data
      {{- end}}
    command: run cron
    
  worker:
    image: eeacms/sentry:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.pull_image: always
    depends_on:
      - redis
      - postgres
      - memcached
      - postfix
      - snuba-api
      - snuba-consumer
      - snuba-outcomes-consumer
      - snuba-sessions-consumer
      - snuba-transactions-consumer
      - snuba-subscription-consumer-events
      - snuba-subscription-consumer-transactions
      - snuba-replacer
      - symbolicator
      - kafka
    links:
      - redis:redis
      - postgres:postgres
      - postfix:postfix
      - snuba-api:snuba-api
      - symbolicator:symbolicator
      - kafka:kafka
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
      LDAP_SERVER: "${LDAP_SERVER}"
      LDAP_BIND_DN: "${LDAP_BIND_DN}"
      LDAP_BIND_PASSWORD: "${LDAP_BIND_PASSWORD}"
      LDAP_USER_DN: "${LDAP_USER_DN}"
      LDAP_DEFAULT_SENTRY_ORGANIZATION: "${LDAP_DEFAULT_SENTRY_ORGANIZATION}"
      LDAP_LOGLEVEL: "${LDAP_LOGLEVEL}"
      PYTHONUSERBASE: "/data/custom-packages"
      SENTRY_CONF: "/etc/sentry"
      SNUBA: "http://snuba-api:1218"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS" 
      SENTRY_REDIS_HOST: redis
    volumes:
      - "sentry-geoip:/geoip:ro"
      {{- if (.Values.sentryconf_volume) }}
      - ${sentryconf_volume}:/etc/sentry
      {{- else}}
      - sentryconf:/etc/sentry
      {{- end}}
      {{- if (.Values.sentryfiles_volume) }}
      - ${sentryfiles_volume}:/data
      {{- else}}
      - sentryfiles:/data
      {{- end}}
    command: run worker
    
  ingest-consumer:
    image: eeacms/sentry:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.pull_image: always
    depends_on:
      - redis
      - postgres
      - memcached
      - postfix
      - snuba-api
      - snuba-consumer
      - snuba-outcomes-consumer
      - snuba-sessions-consumer
      - snuba-transactions-consumer
      - snuba-subscription-consumer-events
      - snuba-subscription-consumer-transactions
      - snuba-replacer
      - symbolicator
      - kafka
    links:
      - redis:redis
      - postgres:postgres
      - postfix:postfix
      - snuba-api:snuba-api
      - symbolicator:symbolicator
      - kafka:kafka
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
      LDAP_SERVER: "${LDAP_SERVER}"
      LDAP_BIND_DN: "${LDAP_BIND_DN}"
      LDAP_BIND_PASSWORD: "${LDAP_BIND_PASSWORD}"
      LDAP_USER_DN: "${LDAP_USER_DN}"
      LDAP_DEFAULT_SENTRY_ORGANIZATION: "${LDAP_DEFAULT_SENTRY_ORGANIZATION}"
      LDAP_LOGLEVEL: "${LDAP_LOGLEVEL}"
      PYTHONUSERBASE: "/data/custom-packages"
      SENTRY_CONF: "/etc/sentry"
      SNUBA: "http://snuba-api:1218"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS" 
      SENTRY_REDIS_HOST: redis
    volumes:
      - "sentry-geoip:/geoip:ro"
      {{- if (.Values.sentryconf_volume) }}
      - ${sentryconf_volume}:/etc/sentry
      {{- else}}
      - sentryconf:/etc/sentry
      {{- end}}
      {{- if (.Values.sentryfiles_volume) }}
      - ${sentryfiles_volume}:/data
      {{- else}}
      - sentryfiles:/data
      {{- end}}
    command: run ingest-consumer --all-consumer-types
  
  post-process-forwarder:
    image: eeacms/sentry:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.pull_image: always
    depends_on:
      - redis
      - postgres
      - memcached
      - postfix
      - snuba-api
      - snuba-consumer
      - snuba-outcomes-consumer
      - snuba-sessions-consumer
      - snuba-transactions-consumer
      - snuba-subscription-consumer-events
      - snuba-subscription-consumer-transactions
      - snuba-replacer
      - symbolicator
      - kafka
    links:
      - redis:redis
      - postgres:postgres
      - postfix:postfix
      - snuba-api:snuba-api
      - symbolicator:symbolicator
      - kafka:kafka
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
      LDAP_SERVER: "${LDAP_SERVER}"
      LDAP_BIND_DN: "${LDAP_BIND_DN}"
      LDAP_BIND_PASSWORD: "${LDAP_BIND_PASSWORD}"
      LDAP_USER_DN: "${LDAP_USER_DN}"
      LDAP_DEFAULT_SENTRY_ORGANIZATION: "${LDAP_DEFAULT_SENTRY_ORGANIZATION}"
      LDAP_LOGLEVEL: "${LDAP_LOGLEVEL}"
      PYTHONUSERBASE: "/data/custom-packages"
      SENTRY_CONF: "/etc/sentry"
      SNUBA: "http://snuba-api:1218"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS" 
      SENTRY_REDIS_HOST: redis
    volumes:
      - "sentry-geoip:/geoip:ro"
      {{- if (.Values.sentryconf_volume) }}
      - ${sentryconf_volume}:/etc/sentry
      {{- else}}
      - sentryconf:/etc/sentry
      {{- end}}
      {{- if (.Values.sentryfiles_volume) }}
      - ${sentryfiles_volume}:/data
      {{- else}}
      - sentryfiles:/data
      {{- end}}
    # Increase `--commit-batch-size 1` below to deal with high-load environments.
    command: run post-process-forwarder --commit-batch-size 1
    
  subscription-consumer-events:
    image: eeacms/sentry:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.pull_image: always
    depends_on:
      - redis
      - postgres
      - memcached
      - postfix
      - snuba-api
      - snuba-consumer
      - snuba-outcomes-consumer
      - snuba-sessions-consumer
      - snuba-transactions-consumer
      - snuba-subscription-consumer-events
      - snuba-subscription-consumer-transactions
      - snuba-replacer
      - symbolicator
      - kafka
    links:
      - redis:redis
      - postgres:postgres
      - postfix:postfix
      - snuba-api:snuba-api
      - symbolicator:symbolicator
      - kafka:kafka
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
      LDAP_SERVER: "${LDAP_SERVER}"
      LDAP_BIND_DN: "${LDAP_BIND_DN}"
      LDAP_BIND_PASSWORD: "${LDAP_BIND_PASSWORD}"
      LDAP_USER_DN: "${LDAP_USER_DN}"
      LDAP_DEFAULT_SENTRY_ORGANIZATION: "${LDAP_DEFAULT_SENTRY_ORGANIZATION}"
      LDAP_LOGLEVEL: "${LDAP_LOGLEVEL}"
      PYTHONUSERBASE: "/data/custom-packages"
      SENTRY_CONF: "/etc/sentry"
      SNUBA: "http://snuba-api:1218"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS" 
      SENTRY_REDIS_HOST: redis
    volumes:
      - "sentry-geoip:/geoip:ro"
      {{- if (.Values.sentryconf_volume) }}
      - ${sentryconf_volume}:/etc/sentry
      {{- else}}
      - sentryconf:/etc/sentry
      {{- end}}
      {{- if (.Values.sentryfiles_volume) }}
      - ${sentryfiles_volume}:/data
      {{- else}}
      - sentryfiles:/data
      {{- end}}
    command: run query-subscription-consumer --commit-batch-size 1 --topic events-subscription-results
 
  subscription-consumer-transactions:
    image: eeacms/sentry:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
      io.rancher.container.pull_image: always
    depends_on:
      - redis
      - postgres
      - memcached
      - postfix
      - snuba-api
      - snuba-consumer
      - snuba-outcomes-consumer
      - snuba-sessions-consumer
      - snuba-transactions-consumer
      - snuba-subscription-consumer-events
      - snuba-subscription-consumer-transactions
      - snuba-replacer
      - symbolicator
      - kafka
    links:
      - redis:redis
      - postgres:postgres
      - postfix:postfix
      - snuba-api:snuba-api
      - symbolicator:symbolicator
      - kafka:kafka
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
      LDAP_SERVER: "${LDAP_SERVER}"
      LDAP_BIND_DN: "${LDAP_BIND_DN}"
      LDAP_BIND_PASSWORD: "${LDAP_BIND_PASSWORD}"
      LDAP_USER_DN: "${LDAP_USER_DN}"
      LDAP_DEFAULT_SENTRY_ORGANIZATION: "${LDAP_DEFAULT_SENTRY_ORGANIZATION}"
      LDAP_LOGLEVEL: "${LDAP_LOGLEVEL}"
      PYTHONUSERBASE: "/data/custom-packages"
      SENTRY_CONF: "/etc/sentry"
      SNUBA: "http://snuba-api:1218"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS" 
      SENTRY_REDIS_HOST: redis
    volumes:
      - "sentry-geoip:/geoip:ro"
      {{- if (.Values.sentryconf_volume) }}
      - ${sentryconf_volume}:/etc/sentry
      {{- else}}
      - sentryconf:/etc/sentry
      {{- end}}
      {{- if (.Values.sentryfiles_volume) }}
      - ${sentryfiles_volume}:/data
      {{- else}}
      - sentryfiles:/data
      {{- end}}
    command: run query-subscription-consumer --commit-batch-size 1 --topic transactions-subscription-results
    
    
  sentry-cleanup:
    image: eeacms/sentry:22.7.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      io.rancher.container.start_once: 'true'
      cron.schedule: "0 0 0 * * *"
      io.rancher.container.pull_image: always
    depends_on:
      - redis
      - postgres
      - memcached
      - postfix
      - snuba-api
      - snuba-consumer
      - snuba-outcomes-consumer
      - snuba-sessions-consumer
      - snuba-transactions-consumer
      - snuba-subscription-consumer-events
      - snuba-subscription-consumer-transactions
      - snuba-replacer
      - symbolicator
      - kafka
    links:
      - redis:redis
      - postgres:postgres
      - postfix:postfix
      - snuba-api:snuba-api
      - symbolicator:symbolicator
      - kafka:kafka
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
      LDAP_SERVER: "${LDAP_SERVER}"
      LDAP_BIND_DN: "${LDAP_BIND_DN}"
      LDAP_BIND_PASSWORD: "${LDAP_BIND_PASSWORD}"
      LDAP_USER_DN: "${LDAP_USER_DN}"
      LDAP_DEFAULT_SENTRY_ORGANIZATION: "${LDAP_DEFAULT_SENTRY_ORGANIZATION}"
      LDAP_LOGLEVEL: "${LDAP_LOGLEVEL}"
      PYTHONUSERBASE: "/data/custom-packages"
      SENTRY_CONF: "/etc/sentry"
      SNUBA: "http://snuba-api:1218"
      SENTRY_EVENT_RETENTION_DAYS: "$SENTRY_EVENT_RETENTION_DAYS" 
      SENTRY_REDIS_HOST: redis
    volumes:
      - "sentry-geoip:/geoip:ro"
      {{- if (.Values.sentryconf_volume) }}
      - ${sentryconf_volume}:/etc/sentry
      {{- else}}
      - sentryconf:/etc/sentry
      {{- end}}
      {{- if (.Values.sentryfiles_volume) }}
      - ${sentryfiles_volume}:/data
      {{- else}}
      - sentryfiles:/data
      {{- end}}
    command: 'gosu sentry sentry cleanup --days $SENTRY_EVENT_RETENTION_DAYS'

  nginx:
    ports:
      - "80"
    image: "nginx:1.22.0-alpine"
    command:
      - /bin/sh
      - -c
      - echo "$${NGINX_CONF}" > /etc/nginx/nginx.conf; nginx -g "daemon off;"
    environment:
      NGINX_CONF: "${NGINX_CONF}"
    depends_on:
      - web
      - relay
    volumes:
      - sentry-nginx-cache:/var/cache/nginx
    links:
      - web:web
      - relay:relay
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes

  relay:
    image: eeacms/sentry-relay:22.7.0
    volumes:
      - sentry-relay:/work
      - sentry-geoip:/geoip
    depends_on:
      - kafka
      - redis
      - web
    links:
      - kafka:kafka
      - redis:redis
      - web:web
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
  
  kowl:
    image: quay.io/cloudhut/kowl:v1.4.0
    environment:
      KAFKA_BROKERS: kafka:9092
      TZ: "${TZ}"
    links:
    - kafka:kafka
    depends_on:
    - kafka
    ports:
    - 8080
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      

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



  sentry-nginx-cache:
    driver: rancher-nfs
  sentry-zookeeper:
    driver: rancher-nfs
  sentry-zookeeper-log:
    driver: rancher-nfs
  sentry-secrets:
    driver: rancher-nfs
  sentry-kafka:
    driver: rancher-nfs
  sentry-kafka-log:
    driver: rancher-nfs
  sentry-secrets:
    driver: rancher-nfs
  sentry-symbolicator:
    driver: rancher-nfs

  {{- if (.Values.clickhouse_volume) }}
  {{.Values.clickhouse_volume}}:
    external: yes
  {{- else}}
  sentry-clickhouse:
  {{- end}}
    driver: ${clickhouse_driver}
    driver_opts:
      {{.Values.clickhouse_driver_opt}}

  sentry-clickhouse-log:
    driver: rancher-nfs
  sentry-geoip:
    driver: rancher-nfs
