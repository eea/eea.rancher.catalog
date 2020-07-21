# RabbitMQ Docker orchestration for EEA

Docker orchestration for EEA [**RabbitMQ**](http://www.rabbitmq.com/) service

#### Base docker image

 - [Official RabbitMQ Docker image](https://hub.docker.com/_/rabbitmq/)

#### Ports

 - 5672 - port for the daemon API, should be exposed to public
 - 15672 - port for the RabbitMQ Management interface

#### Installation

 - From the Rancher catalog select "EEA - RabbitMQ".

#### How to configure it

 - These are the steps to configure the service:

###### RabbitMQ
- `rabbitmq_default_user` - RabbitMQ user to access the management console
- `rabbitmq_default_pass` - RabbitMQ password to access the management console

###### Rancher labels
- `HOST_LABELS` - Schedule services on hosts with following host labels
- `TZ` - Time zone

#### Upgrade

 - Press the available upgrade buttons within Rancher UI.

#### Data migration

You can access production data inside `rabbitmq` container under:

    /var/lib/rabbitmq

#### Example usage

- [Tutorials](https://www.rabbitmq.com/getstarted.html) using the pika 0.10.0 Python client
- [Management plugin] (https://www.rabbitmq.com/management.html) that provides an HTTP-based API for management and monitoring of your RabbitMQ server
- [Management Command Line Tool] (http://www.rabbitmq.com/management-cli.html) that provides a command line tool rabbitmqadmin (python script) which can perform the same actions as the web-based UI

Using [rabbitmqadmin.py](https://github.com/johnbellone/rabbitmqadmin-cookbook/blob/master/files/default/rabbitmqadmin.py)

    $ python rabbitmqadmin.py -H HOST -P PORT -u USERNAME -p PASSWORD -f pretty_json list queues vhost name node durable messages
    $ # returns a JSON structure like this
    $ # [
    $ #   {
    $ #     "durable": true,
    $ #     "messages": 2,
    $ #     "name": "odp_queue",
    $ #     "node": "rabbit@2e7a21533b6b",
    $ #     "vhost": "/"
    $ #   }
    $ # ]

If the service is down

    $ # *** Could not connect: [Errno 111] Connection refused

If the credentials are invalid

    $ # *** Access refused: /api/queues?columns=vhost,name,node,durable,messages

#### Copyright and license

The Initial Owner of the Original Code is European Environment Agency (EEA).
All Rights Reserved.

The Original Code is free software;
you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later
version.

#### Funding

[European Environment Agency (EU)](http://eea.europa.eu)
