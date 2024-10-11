# Traefik


Documentation link: 

https://doc.traefik.io/traefik/providers/rancher/

## Stack installation specific documentation

If using external volumes, please create them from the Rancher Storage page. 
All the volumes that need to be pre-populated from the docker image ( for example for grafana configuration), need to be non-nfs.


## To add local plugins, add in catalog to the command of the traefik service lines like this:
          - --experimental.localPlugins.demo.moduleName=github.com/traefik/plugindemo
          - --experimental.localPlugins.geoblock.moduleName=github.com/kucjac/traefik-plugin-geoblock

## How to add a new traefik service ( minimum configuration )

Add labels to the service:

```
    labels:
      traefik.enable: 'true'
      traefik.http.routers.<ROUTER_NAME>.rule: Host(`<HOST>`)
      traefik.http.services.<SERVICE_NAME>.loadbalancer.server.port: '<PORT>'
```

Where:
* ROUTER_NAME, SERVICE_NAME - **unique** names, specific to the service
* PORT - internal port from the container ( NOT the exposed port )
* HOST - the host from the url you will be using to access the service

Please check multiple times that all the names are specific to your service.

#### Complex example, using local plugin and rate limit plugin

Plugin order matters.

The plugin from the example (named demo) is added to traefik service command like this:
```
command:
    - --experimental.localPlugins.demo.moduleName=github.com/traefik/plugindemo
```

Labels on the service
```
    labels:
      traefik.enable: 'true'
      traefik.http.routers.SERVICE_testproxy.rule: Host(`traefik-test.eea.europa.eu`)
      traefik.http.routers.SERVICE_testproxy.middlewares: SERVICE_test-plugin@rancher,SERVICE_test-ratelimit@rancher
      traefik.http.services.SERVICE_testproxy_hello_world.loadbalancer.server.port: '5050'

      traefik.http.middlewares.SERVICE_test-ratelimit.ratelimit.average: '70'
      traefik.http.middlewares.SERVICE_test-ratelimit.ratelimit.burst: '50'
      traefik.http.middlewares.SERVICE_test-ratelimit.ratelimit.period: 1m
      
      traefik.http.middlewares.SERVICE_test-plugin.plugin.demo.headers.Foo: Bar

```
#### Example to have multiple rules in router:

```
      traefik.http.routers.SERVICE_testproxy.rule: Host(`traefik-test.eea.europa.eu`)&& HeadersRegexp(`X-Real-Ip`, `(^10\.)`)
```



