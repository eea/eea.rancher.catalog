version: "2"
services:
  rabbitmq:
    image: rabbitmq:3.7.2-management
    restart: unless-stopped
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      RABBITMQ_DEFAULT_USER: "${RABBITMQ_DEFAULT_USER}"
      RABBITMQ_DEFAULT_PASS: "${RABBITMQ_DEFAULT_PASS}"
      TZ: "${TZ}"
    volumes:
    - rabbitmq:/var/lib/rabbitmq

volumes:
  rabbitmq:
    driver: ${VOLUME_DRIVER}
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
