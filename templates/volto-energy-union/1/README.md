# Volto

A generic React-based frontend for Plone (or Guillotina)

* `BACKEND` - Backend service. It can be either a Plone instance, `HAProxy` in front of `Plone`, or for **best results** `Varnish` in front of `HAProxy/Plone`
* `API_PATH` - Publicly accesible link to your `Plone` instance with `plone.restapi` installed and enabled. (e.g.: `https://demo-energy-union.eea.europa.eu/energy` or `https://demo-energy-union.eea.europa.eu/api`)
* `INTERNAL_API_PATH` Should be `http://backend:8080/energy` if you're pointing backend to a `Plone` instance, else `http://backend:6081/energy` if you're pointing to `Varnish`. (`/energy` is the name of your `Plone` instance within `ZODB`).

## Changes in Rancher Load Balancer (e.g. revproxy-eionet)

* Add the following in `Custom haproxy.cfg` section:

```
    frontend 80
      redirect scheme https code 301 if { hdr(host) -i demo-energy-union.eea.europa.eu }

    backend demo-energy-union-api
      http-request set-path /VirtualHostBase/https/demo-energy-union.eea.europa.eu:443/energy/VirtualHostRoot/_vh_api/%[path,regsub(\/api,,g)]

    backend demo-energy-union-plone
      http-request set-path /VirtualHostBase/https/demo-energy-union.eea.europa.eu:443/VirtualHostRoot/%[path]

    backend demo-energy-union-front
      compression algo gzip
      compression type text/html text/plain text/xml text/css text/javascript application/x-javascript application/javascript application/json

```

* Add the following `selector` rules in the `Port rules` section:

```
    - backend_name: demo-energy-union-api
      hostname: demo-energy-union.eea.europa.eu
      path: /api
      priority: 53
      protocol: https
      service: energy-backend/varnish
      source_port: 443
      target_port: 6081
    - backend_name: demo-energy-union-plone
      hostname: demo-energy-union.eea.europa.eu
      path: /energy
      priority: 54
      protocol: https
      service: energy-backend/plone
      source_port: 443
      target_port: 8080
    - backend_name: demo-energy-union-front
      hostname: demo-energy-union.eea.europa.eu
      path: ''
      priority: 55
      protocol: https
      service: energy-frontend/frontend
      source_port: 443
      target_port: 3000

```
