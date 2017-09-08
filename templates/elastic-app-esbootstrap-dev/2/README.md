# EEA Elastic bootstrap with Cloud9

This stack containes a sample nodejs application which connects to an external EEA elasticsearch service with RDF river plugin included (to be specified) and creates a faceted search interface.

This stack requires one instance of the EEA Elasticsearch engine stack to be running in the same environment.

## How to use it

These are the steps to test a new elastic application:

- Use the included Cloud9 IDE to change the configuration of your app as described in as explained in [how to configure your elastic bootstrap app](https://github.com/eea/eea.docker.esbootstrap/blob/master/docs/Details.md#setup)
- Once the configuration is done you can use the reindex service to index the data in elasticsearch. 
- After the elasticsearch index is properly created, you need to restart the esapp application to view the changes.

If you want to create new esapp, just clone the esapp service and give it a new name. You can then repeat the steps above to configure it.

**Remember**: When you're done doing the commit / push of your project using the Cloud9 terminal

## Development environment

Set **DEV_ENV** to **true** will pull/clone configuration each time **esbootstrap-data-config** is launched.