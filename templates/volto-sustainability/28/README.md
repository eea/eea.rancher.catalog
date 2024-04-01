# Volto - THIS TEMPLATE IS DEPRECATED

A generic React-based frontend for Plone (or Guillotina)

* `BACKEND` - Backend service. It can be either a Plone instance, `HAProxy` in front of `Plone`, or for **best results** `Varnish` in front of `HAProxy/Plone`
* `API_PATH` - Publicly accesible link to your `Plone` instance with `plone.restapi` installed and enabled. (e.g.: `https://sustainability.eea.europa.eu/sustainability` or `https://sustainability.eea.europa.eu/api`)
* `INTERNAL_API_PATH` Should be `http://backend:8080/sustainability` if you're pointing backend to a `Plone` instance, else `http://backend:6081/sustainability` if you're pointing to `Varnish`. (`/sustainability` is the name of your `Plone` instance within `ZODB`).

## Changes in Rancher Load Balancer (e.g. revproxy-eionet)

* Add the following in `Custom haproxy.cfg` section:

```
    frontend 80
      redirect scheme https code 301 if { hdr(host) -i sustainability.eea.europa.eu }

    backend sustainability-api
      http-request set-path /VirtualHostBase/https/dsustainability.eea.europa.eu:443/sustainability/VirtualHostRoot/_vh_api/%[path,regsub(\/api,,g)]

    backend sustainability-plone
      http-request set-path /VirtualHostBase/https/sustainability.eea.europa.eu:443/VirtualHostRoot/%[path]

    backend sustainability-front
      compression algo gzip
      compression type text/html text/plain text/xml text/css text/javascript application/x-javascript application/javascript application/json

```

* Add the following `selector` rules in the `Port rules` section:

```
    - backend_name: sustainability-api
      hostname: sustainability.eea.europa.eu
      path: /api
      priority: 53
      protocol: https
      service: sustainability-backend/varnish
      source_port: 443
      target_port: 6081
    - backend_name: sustainability-plone
      hostname: dsustainability.eea.europa.eu
      path: /sustainability
      priority: 54
      protocol: https
      service: sustainability-backend/plone
      source_port: 443
      target_port: 8080
    - backend_name: sustainability-front
      hostname: sustainability.eea.europa.eu
      path: ''
      priority: 55
      protocol: https
      service: sustainability-frontend/frontend
      source_port: 443
      target_port: 3000

```
