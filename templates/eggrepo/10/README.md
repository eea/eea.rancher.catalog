## EEA Eggrepo rancher template

EEA custom repository for python eggs

### Deployment

* Within `Rancher Catalog > EEA` deploy:
  * EEA - Eggs Server Repository

### Rancher environment variables

* "Server name" -  DNS name for this deployment, used in apache
* "Schedule services on hosts with following host labels" - used only if you need to fix all of the container on a subset of rancher hosts, there is no need to use it for nfs, ebs or netapp volumes.
* "Data volume driver" - Volume driver for eggs repo, use rancher-ebs for AMZ and netapp for CPH for better performance
* "Data volume driver options" - used to add size to EBS and NETAPP volumes - in GB. In Netapp, the default size is 1GB
* "Time zone" - default timezone in all containers 


### Rancher LB configuration

To be able to connect correctly to the website, you need to:

1. Add in DNS the "Server name" to point to the rancher frontend
2. Add a HTTP, Request host:"Server name", port 80  service in the rancher frontend LB to `STACKNAME`/apache:80 with backend `force_ssl`
3. In Custom haproxy.cfg, `force_ssl` backend should be declared:

```
backend force_ssl
    redirect scheme https code 301 if ! { ssl_fc }
```
4. Add a HTTPS, Request host:"Server name", port 443  service in the rancher frontend LB to `STACKNAME`/apache:80 


### Data migration

1. Start **rsync client** on host from where do you want to migrate eggrepo data (SOURCE HOST):

  ```
    $  docker run -it --rm --name=rclient -v eggrepo:/data \
              eeacms/rsync client
  ```

2. Start **rsync server** on host where do you want to migrate eggrepo data (DESTINATION HOST):

  ```
    $ docker run -it --rm --name=rserver -v eggrepo:/data \
                 -p 2222:22 \
                 -e SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>" \
             eeacms/rsync server
  ```

3. Within **rsync client** container from step 1 run:

  ```
    $ rsync -e 'ssh -p 2222' -avz /data/ root@<DESTINATION HOST IP>:/data/
  ```
