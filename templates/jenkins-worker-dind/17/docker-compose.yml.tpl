version: "2"
services:
  docker:
    image: eeacms/jenkins-slave-dind:17.12-3.22
    labels:
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
    init: true


  clair:
    image: rancher/dns-service
    external_links:
    - ${CLAIR}:clair
    

  {{- if eq .Values.UPDATE_SYSCTL "true" }}
  es-sysctl:
    labels:
      io.rancher.scheduler.global: 'true'
      {{- if .Values.HOST_LABELS}}
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      {{- else}}
      io.rancher.scheduler.affinity:host_label_ne: reserved=yes
      {{- end}}
      io.rancher.container.start_once: false
    network_mode: none
    image: rawmind/alpine-sysctl:0.1
    privileged: true
    mem_limit: 32m
    mem_reservation: 8m
    environment:
      - "SYSCTL_KEY=fs.inotify.max_user_watches"
      - "SYSCTL_VALUE=524288"
      - "KEEP_ALIVE=1"
  {{- end}}

volumes:
  jenkins-worker:
    driver: ${VOLUME_DRIVER}
    per_container: true
    {{- if .Values.VOLUME_DRIVER_OPTS}}
    driver_opts:
      {{.Values.VOLUME_DRIVER_OPTS}}
    {{- end}}

