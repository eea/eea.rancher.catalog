version: '2'
services:
  nfs-volumes:
    image: busybox
    tty: true
    stdin_open: true
    labels:
      io.rancher.scheduler.affinity:host_label: ${VOLUME_HOST_LABELS}
      io.rancher.container.start_once: 'true'
    volumes:
    - ${NFS_VOLUMES_ROOT}www-blobstorage:/data/blobstorage
    - ${NFS_VOLUMES_ROOT}www-filestorage:/data/filestorage
    - ${NFS_VOLUMES_ROOT}www-downloads:/data/downloads
    - ${NFS_VOLUMES_ROOT}www-suggestions:/data/suggestions
    - ${NFS_VOLUMES_ROOT}www-static-resources:/data/www-static-resources
    - ${NFS_VOLUMES_ROOT}www-eea-controlpanel:/data/eea.controlpanel
    - ${NFS_VOLUMES_ROOT}www-postgres-dump:/data/postgresql.backup
    - ${NFS_VOLUMES_ROOT}www-postgres-archive:/var/lib/postgresql/archive
    volume_driver: ${NFS_VOLUME_DRIVER}
    command: ["ls", "-l", "/var/lib/postgresql/archive"]

{{- if ne .Values.DB_VOLUME_DRIVER "disabled"}}

  db-volumes:
    image: busybox
    tty: true
    stdin_open: true
    labels:
      io.rancher.scheduler.affinity:host_label: ${VOLUME_HOST_LABELS}
      io.rancher.scheduler.global: 'true'
      io.rancher.container.start_once: 'true'
    volumes:
    - ${DB_VOLUMES_ROOT}www-postgres-data:/var/lib/postgresql/data
    volume_driver: ${DB_VOLUME_DRIVER}
    command: ["ls", "-l", "/var/lib/postgresql/data"]

{{- end}}
