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
