version: "2"
services:
  worker:
    image: eeacms/jenkins-slave:3.48
    labels:
      io.rancher.container.hostname_override: container_name
      io.rancher.scheduler.affinity:host_label: ${HOST_LABELS}
      io.rancher.scheduler.global: 'true'
    environment:
      JAVA_OPTS: "${JAVA_OPTS}"
      JENKINS_MASTER: "http://jenkins-master:8080"
      JENKINS_NAME: "${JENKINS_NAME}"
      JENKINS_RETRY: "${JENKINS_RETRY}"
      JENKINS_USER: "${JENKINS_USER}"
      JENKINS_PASS: "${JENKINS_PASS}"
      JENKINS_EXECUTORS: "${JENKINS_EXECUTORS}"
      JENKINS_LABELS: "${JENKINS_LABELS}"
      JENKINS_OPTS: "${JENKINS_OPTS}"
      TZ: "${TZ}"
    external_links:
    - "${JENKINS_MASTER}:jenkins-master"
    volumes:
    - jenkins-worker:/var/jenkins_home/worker
    mem_limit: ${mem_limit}
    mem_reservation: ${mem_reservation}
    init: true

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
    image: eeacms/alpine-sysctl:0.3
    privileged: true
    mem_limit: 32m
    mem_reservation: 32m
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
