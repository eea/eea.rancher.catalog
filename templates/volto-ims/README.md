# Volto

A generic React-based frontend for Plone (or Guillotina)

* `BACKEND` - Backend service. It can be either a Plone instance, `HAProxy` in front of `Plone`, or for **best results** `Varnish` in front of `HAProxy/Plone`
* `API_PATH` - Publicly accesible link to your `Plone` instance with `plone.restapi` installed and enabled. (e.g.: `https://foo.bar/Plone` or `https://foo.bar/api`)
* `INTERNAL_API_PATH` Should be `http://backend:8080/Plone` if you're pointing backend to a `Plone` instance, else `http://backend:6081/Plone` if you're pointing to `Varnish`. (`/Plone` is the name of your `Plone` instance within `ZODB`).

## Changes in Rancher Load Balancer (e.g. revproxy-eionet)

* Add the following in `Custom haproxy.cfg` section:

```
    backend volto-frontend
        compression algo gzip
        compression type text/html text/plain text/xml text/css text/javascript application/x-javascript application/javascript application/json

    backend volto-api
        http-request set-path /VirtualHostBase/https/foo.bar:443/Plone/VirtualHostRoot/_vh_api/%[path,regsub(\/api,,g)]

    backend volto-plone
        http-request set-path /VirtualHostBase/https/foo.bar:443/VirtualHostRoot/%[path]

```

* Add the following `selector` rules in the `Port rules` section:

```
      - backend_name: volto-api
        hostname: foo-bar.com
        path: /api
        priority: 53
        protocol: https
        service: foo-bar/varnish
        source_port: 443
        target_port: 6081
      - backend_name: volto-plone
        hostname: foo-bar.com
        path: /Plone
        priority: 54
        protocol: https
        service: foo-bar/plone
        source_port: 443
        target_port: 8080
      - backend_name: volto-frontend
        hostname: foo-bar.com
        path: ''
        priority: 55
        protocol: https
        service: foo-volto/frontend
        source_port: 443
        target_port: 3000
```
