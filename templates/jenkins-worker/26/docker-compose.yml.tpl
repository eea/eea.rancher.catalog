version: "2"
services:
  worker:
    image: eeacms/jenkins-slave:3.46
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
    external_links:
    - "${JENKINS_MASTER}:jenkins-master"
    environment:
      JAVA_OPTS: "${JAVA_OPTS}"
      JENKINS_MASTER: "http://jenkins-master:8080"
      JENKINS_NAME: "${JENKINS_NAME}"
      JENKINS_RETRY: "${JENKINS_RETRY}"
      JENKINS_USER: "${JENKINS_USER}"
      JENKINS_PASS: "${JENKINS_PASS}"
      JENKINS_LABELS: "${JENKINS_LABELS}"
      JENKINS_OPTS: "${JENKINS_OPTS}"
      JENKINS_EXECUTORS: "${JENKINS_EXECUTORS}"
      TZ: "${TZ}"
    mem_reservation: 2684354560 # = 2.5 GB
    mem_limit: 2684354560 # = 2.5 GB
    init: true
    volumes:
    - jenkins-worker:/var/jenkins_home/worker


volumes:
  jenkins-worker:
    driver: ${VOLUME_DRIVER}
    per_container: true
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}
