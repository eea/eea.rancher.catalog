# Volto

A generic React-based frontend for Plone (or Guillotina)

* `BACKEND` - Backend service. It can be either a Plone instance, `HAProxy` in front of `Plone`, or for **best results** `Varnish` in front of `HAProxy/Plone`
* `API_PATH` - Publicly accesible link to your `Plone` instance with `plone.restapi` installed and enabled. (e.g.: `https://demo-freshwater.devel4cph.eea.europa.eu/freshwater` or `https://demo-freshwater.devel4cph.eea.europa.eu/api`)
* `INTERNAL_API_PATH` Should be `http://backend:8080/freshwater` if you're pointing backend to a `Plone` instance, else `http://backend:6081/freshwater` if you're pointing to `Varnish`. (`/energy` is the name of your `Plone` instance within `ZODB`).

## Changes in Rancher Load Balancer (e.g. revproxy-eionet)

* Add the following in `Custom haproxy.cfg` section:

```
    frontend 80
      http-request redirect scheme https code 301 if { hdr(host) -i demo-freshwater.devel4cph.eea.europa.eu } !url_acme

    backend demo-freshwater.devel4cph-api
      compression algo gzip
      compression type text/html text/plain text/xml text/css text/javascript application/x-javascript application/javascript application/json
      http-request set-path /VirtualHostBase/https/demo-freshwater.devel4cph.eea.europa.eu:443/freshwater/VirtualHostRoot/_vh_api/%[path,regsub(\/api,,g)]

    backend demo-freshwater.devel4cph-plone
      http-request set-path /VirtualHostBase/https/demo-freshwater.devel4cph.eea.europa.eu:443/VirtualHostRoot/%[path]

    backend demo-freshwater.devel4cph-front
      compression algo gzip
      compression type text/html text/plain text/xml text/css text/javascript application/x-javascript application/javascript application/json

```

* Add the following `selector` rules in the `Port rules` section:

```
    - backend_name: demo-freshwater.devel4cph-api
      hostname: demo-freshwater.devel4cph.eea.europa.eu
      path: /api
      priority: 16
      protocol: https
      service: forests-backend/varnish
      source_port: 443
      target_port: 6081
    - backend_name: demo-freshwater.devel4cph-plone
      hostname: demo-freshwater.devel4cph.eea.europa.eu
      path: /freshwater
      priority: 17
      protocol: https
      service: forests-backend/plone
      source_port: 443
      target_port: 8080
    - backend_name: demo-freshwater.devel4cph-front
      hostname: demo-freshwater.devel4cph.eea.europa.eu
      path: ''
      priority: 18
      protocol: https
      service: forests-frontend/frontend
      source_port: 443
      target_port: 3000

```
