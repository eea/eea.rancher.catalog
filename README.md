# EEA Rancher Catalog

This repo contains EEA specific application stacks under the templates folder. 

## How it works

Devops add new appplication templates or new versions that are than exposed by Rancher under Applications > Catalog on our [EEA Rancher server](https://rancher.eea.europa.eu)

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

## How to add a new catalog entry

There is an [open-source project](https://github.com/slashgear/generator-rancher-catalog) based on Yeoman, that can be used to create the templates of an empty catalog entry. You just run the command _yo rancher-catalog_ see below:

```bash
$ git clone https://github.com/eea/eea.rancher.catalog
$ cd eea.rancher.catalog
$ yo rancher-catalog

     _-----_     ╭──────────────────────────╮
    |       |    │    Welcome to the good   │
    |--(o)--|    │ generator-rancher-catalo │
   `---------´   │       g generator!       │
    ( _´U`_ )    ╰──────────────────────────╯
    /___A___\   /
     |  ~  |     
   __'.___.'__   
 ´   `  |° ´ Y ` 

? What is the name of the catalog entry? money-digger
? What are the cluster management types? (Press <space> to select, <a> to toggle all, <i> to inverse selection)
❯◉ Cattle
 ◯ Swarm
 ◯ Kubernetes
 ◯ Mesos
```
After you have answered a couple of questions you will get a skeleton catalog entry inside the templates folder which you can then continue to edit.

## Documentation

- [How to create private catalogs](http://docs.rancher.com/rancher/catalog/#creating-private-catalogs)
- [Screencast and presentation](http://rancher.com/building-an-application-catalog-with-rancher-recorded-online-meetup/)
