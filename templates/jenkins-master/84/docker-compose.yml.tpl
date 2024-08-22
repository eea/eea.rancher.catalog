version: "2"
services:
  master:
    image: eeacms/jenkins-master:2.471
    {{- if .Values.JENKINS_MASTER_PORT}}
    ports:
    - "${JENKINS_MASTER_PORT}:8080"
    {{- if .Values.JENKINS_SLAVE_PORT}}
    - "${JENKINS_SLAVE_PORT}:50000"
    {{- end}}
    {{- end}}
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    depends_on:
    - postfix
    user: root
    environment:
      JAVA_OPTS: ${JAVA_OPTS}
      TZ: ${TZ}
      JENKINS_OPTS: --sessionTimeout=${JENKINS_SESSION_TIMEOUT}
    volumes:
    - ${VOLUME_NAME}:/var/jenkins_home

  postfix:
    image: eeacms/postfix:3.5-1.0
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      TZ: "${TZ}"
      MTP_HOST: "${SERVER_NAME}"
      MTP_RELAY: "${POSTFIX_RELAY}"
      MTP_PORT: "${POSTFIX_PORT}"
      MTP_USER: "${POSTFIX_USER}"
      MTP_PASS: "${POSTFIX_PASS}"


volumes:
  ${VOLUME_NAME}:
    driver: ${VOLUME_DRIVER}
    {{- if eq .Values.VOLUME_EXTERNAL "Yes"}}
    external: true
    {{- end}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}

