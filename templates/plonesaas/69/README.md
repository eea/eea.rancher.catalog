# Plone - SaaS

Plone 5 SaaS at EEA. An application server where we can create new Plone 5 sites via UI simplifying the IT management and costs of them.

## Changes in Rancher Load Balancer (e.g. revproxy-eionet)

1. Add the following in `Custom haproxy.cfg` section:
```
        backend plonesaas
          http-request set-path /VirtualHostBase/https/plonesaas.eea.europa.eu:443/%[path]
```

1. Add the following `selector` rules in the `Port rules` section:

```
        - backend_name: plonesaas
          hostname: plonesaas.eea.europa.eu
          protocol: https
          selector: eu.europa.saas.plone=true
          source_port: 443
          target_port: 8080
```

# Upgrade

* Backup `Data.fs` / `blobstorage`

## 5.1 (latest)

* Rancher - Upgrade to the latest `5.1.6`
* Run available Plone upgrades on all sites
* Uninstall **plone.app.ldap** on all sites
* Install **pas.plugins.ldap** on sites where LDAP was enabled and configure it (see `#110155#note-18`)
* Pack ZODB
* Within ZEO container run `bin/zodbverify -f /data/filestorage/Data.fs`
* Backup `Data.fs` / `blobstorage`

## 5.2 (Python 2)

## 5.2 (Python 3)
