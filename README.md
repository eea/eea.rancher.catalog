# EEA Rancher Catalog

This repo contains EEA specific application stacks under the templates folder. 

## How it works

Devops add new appplication templates or new versions that are than exposed by Rancher under Applications > Catalog on our [EEA Rancher server](http://rancher.eionet.eea.europa.eu)

```
DIRECTORY STRUCTURE

-- templates
  |-- plone
  |   |-- 0
  |   |   |-- docker-compose.yml
  |   |   |-- rancher-compose.yml
  |   |-- 1
  |   |   |-- docker-compose.yml
  |   |   |-- rancher-compose.yml
  |   |-- catalogIcon-plone.svg
  |   |-- config.yml
```

As you can see from the example above the Plone Stack is available in two versions under "0" and "1". This helps Rancher catalog distinguish versions of the same Stack and provide means for upgrade/downgrade via the UI/CLI.

## Documentation

- [How to create private catalogs](http://docs.rancher.com/rancher/catalog/#creating-private-catalogs)
- [Screencast and presentation](http://rancher.com/building-an-application-catalog-with-rancher-recorded-online-meetup/)
