# EIONET - WWW

The Eionet Portal serves the network by providing a platform for networking and information sharing and tools for collection management of environmental data and information.

## Changes in Rancher Load Balancer (e.g. revproxy-eionet)

1. Add the following in `Custom haproxy.cfg` section:
```
        backend plone5eionet
          http-request set-path /VirtualHostBase/https/plone5demo.eionet.europa.eu:443/Eionet/VirtualHostRoot/%[path]
```

1. Add the following `selector` rules in the `Port rules` section:

```
        - backend_name: plone5eionet
          hostname: plone5demo.eionet.europa.eu
          protocol: https
          selector: eu.europa.eionet.plone=true
          source_port: 443
          target_port: 8080
```