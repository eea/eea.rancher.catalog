
# EEA Community rancher template

EEA Community site orchestration for deployment, including  **ZEO server**, **ZEO client**,  **Postfix**.

**ZEO server** and **ZEO client** have the same base image, you can find it on
[Docker Hub](https://registry.hub.docker.com/u/eeacms/cynin/) or you can
inspect the [Github repository](https://github.com/eea/eea.docker.cynin)
to see the Dockerfile.

## Usage

> **Note:** See **EEA SVN** for `answers.txt` file

* From **Rancher Catalog > EEA** deploy:
  * Community (EEA Forum)


### Rancher environment variables

* "Server name" -  DNS name for this deployment, used in postfix
* "Schedule services on hosts with following host labels" - used only if you need to fix all of the container on a subset of rancher hosts, there is no need to use it for nfs, ebs or netapp volumes.
* "Use mailtrap instead of potfix" - For development, choose yes to disable email sending
* "Postfix user" - user name used to connect in the postfix container to the SMTP relay
* "Postfix password" - password used to connect in the postfix container to SMTP relay
* "Filestorage volume driver", "Blobstorage volume driver" - Volume driver for ZEO filestorage/blobstorage, use rancher-ebs for AMZ and netapp for CPH for better performance
* "Filestorage volume environment scoped (external)","Blobstorage volume environment scoped (external)" - if you choose yes, you need to have the volume "filestorage"/"blobstorage" already created in rancher
* "Filestorage volume driver options", "Blobstorage volume driver options" - used to add size to EBS and NETAPP volumes - in GB. In Netapp, the default size is 1GB
* "Time zone" - default timezone in all containers

### Rancher LB configuration

To be able to connect correctly to the website, you need to:

1. Add in DNS the "Server name" to point to the rancher frontend
2. Add a HTTP, Request host:"Server name", port 80  service in the rancher frontend LB to `STACKNAME`/cynin:8080 with backend `force_ssl`
3. In Custom haproxy.cfg, `force_ssl` backend should be declared:

```
backend force_ssl
    redirect scheme https code 301 if ! { ssl_fc }
```
4. Add a HTTPS, Request host:"Server name", port 443  service in the rancher frontend LB to `STACKNAME`/cynin:8080 with backend `community`
5. In Custom haproxy.cfg, `community` backend should be declared ( replace "Server name" with the url you are using ) :
```
backend community
    http-request set-path /VirtualHostBase/https/"Server name":443/cynin/VirtualHostRoot/%[path]
```

## Upgrade

### Upgrade `community` stack

1. **Add new catalog version** within [eea.rancher.catalog](https://github.com/eea/eea.rancher.catalog/tree/master/templates/community)

   * Prepare next release, e.g.: `17.9`:

        ```
        $ git clone git@github.com:eea/eea.rancher.catalog.git
        $ cd eea.rancher.catalog/templates/community

        $ cp -r 59 60
        $ git add 60
        $ git commit -m "Prepare release 17.9"
        ```

   * Release new version, e.g:. `17.9`:

        ```
        $ vim config.yml
        ...
        version: "17.9"
        ...

        $ vim 60/rancher-compose.yml
        ...
        version: "17.9"
        ...

        $ vim 60/docker-compose.yml
        ...
        - image: eeacms/cynin:17.9
        ...

        $ git add .
        $ git commit -m "Release 17.9"
        $ git push
        ```

   * See [Rancher docs](https://docs.rancher.com/rancher/v1.2/en/catalog/private-catalog/#rancher-catalog-templates) for more details.

2. **Upgrade Rancher** deployment

   * Click the available upgrade button

   * Confirm the upgrade

   * Or roll-back if something goes wrong and abort the upgrade procedure


## Data migration

You can access production data inside `filestorage` and `blobstorage` volumes.

You can use eeacms/rsync containers to migrate the data. See [Rsync documentation](https://github.com/eea/eea.docker.rsync#rsync-data-between-containers-in-rancher)


## First time steps to get a clean Cyn.in portal

If you don't have already an existing Cyn.in site (zodb data.fs) than the following step will get you started to create a fresh Cyn.in site.

1. Point your public LB to cynin instance instead of apache
2. open in browser: http://my.cynin.com/manage
user: admin
password: secret
(default zope admin user)
3. Change `admin` password within **acl_users**
4. From ZMI add a "Plone Site" object, set the id: "cynin", press the "Add plone site" button
5. Select "cynin", look for "portal_quickinstaller", check the product called "Ubify Site Policy", press the "Install" button
6. Open in browser: http://my.cynin.com/cynin
7. Point back your public LB to apache

Documentation at http://cyn.in/


## How to setup manager access

If you don't have a manager account, you can create one by following these simple steps

1. Enter the cynin container
2. Go to the folder where the project is located
3. Use `bin/www1 adduser user password`, this will create a manager account with the credentials specified

If you already have a manager account you can simply login, then go to Administration -> User management and after searching for the right user you can make it a manager
