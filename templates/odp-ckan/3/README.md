# ODP CKAN Docker orchestration for EEA

Docker orchestration for [**EEA ODP CKAN**](https://github.com/eea/eea.odpckan) service

#### Base docker image

 - [Official EEA ODP CKAN Docker image](https://hub.docker.com/r/eeacms/odpckan/)

#### Installation

 - From the Rancher catalog select "EEA - ODP CKAN".

#### How to configure it

 - These are the steps to configure the service:

###### RabbitMQ
- `rabbitmq_host` - Host name of the RabbitMQ daemon/service
- `rabbitmq_port` - Port of the RabbitMQ daemon/service
- `rabbitmq_username` - Username for the RabbitMQ daemon/service connection
- `rabbitmq_password` - Password for the RabbitMQ daemon/service connection

###### Services
- `services_eea` - EEA service URL
- `services_odp` - ODP service URL
- `services_sds` - SDS service URL
- `sds_timeout` - SDS timeout in seconds, used for opening URLs

###### CKAN
- `ckan_address` - ODP CKAN URL address
- `ckan_apikey` - ODP CKAN API key
- `ckan_client_interval` - CKAN client update interval
- `ckan_client_interval_bulk` - CKAN client bulk update interval

###### Rancher labels
- `HOST_LABELS` - Schedule services on hosts with following host labels
- `TZ` - Time zone

#### Upgrade

 - Press the available upgrade buttons within Rancher UI.
 
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
