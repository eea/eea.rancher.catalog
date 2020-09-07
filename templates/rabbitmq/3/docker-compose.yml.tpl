version: "2"
services:
  rabbitmq:
    image: eeacms/rabbitmq:3.7.28-1
    mem_reservation: ${MEMORY_RESERVATION}
    mem_limit: ${MEMORY_LIMIT}
    labels:
      io.rancher.container.hostname_override: container_name
      {{- if .Values.HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      RABBITMQ_DEFAULT_USER: "${RABBITMQ_DEFAULT_USER}"
      RABBITMQ_DEFAULT_PASS: "${RABBITMQ_DEFAULT_PASS}"
      TZ: "${TZ}"
    volumes:
    - {{.Values.VOLUME}}:/var/lib/rabbitmq

volumes:
  {{.Values.VOLUME}}:
    driver: ${VOLUME_DRIVER}
    {{- if eq .Values.VOLUME_EXTERNAL "yes"}}
    external: true
    {{- end}}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
