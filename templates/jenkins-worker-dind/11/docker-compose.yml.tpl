version: "2"
services:
  docker:
    image: eeacms/jenkins-slave-dind:17.12-3.16
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    environment:
      JENKINS_MASTER: "http://${JENKINS_MASTER}:${JENKINS_PORT}"
      JAVA_OPTS: "${JAVA_OPTS}"
      JENKINS_OPTS: "${JENKINS_OPTS}"
      JENKINS_MODE: "exclusive"
      JENKINS_NAME: "${JENKINS_NAME}"
      JENKINS_RETRY: "${JENKINS_RETRY}"
      JENKINS_USER: "${JENKINS_USER}"
      JENKINS_PASS: "${JENKINS_PASS}"
      JENKINS_LABELS: "${JENKINS_LABELS}"
      JENKINS_EXECUTORS: "${JENKINS_EXECUTORS}"
      DOCKERHUB_USER: "${DOCKERHUB_USER}"
      DOCKERHUB_PASS: "${DOCKERHUB_PASS}"
      TZ: "${TZ}"
    network_mode: ${NETWORK_MODE}
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - jenkins-worker:/var/jenkins_home/worker
    mem_limit: ${mem_limit}
    mem_reservation: ${mem_reservation}


  clair:
    image: rancher/dns-service
    external_links:
    - ${CLAIR}:clair

volumes:
  jenkins-worker:
    driver: ${VOLUME_DRIVER}
    per_container: true
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}

