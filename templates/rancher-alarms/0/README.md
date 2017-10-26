# Rancher Alarms

## Source Code 
[Rancher Alarms project] (https://github.com/eea/rancher-alarms)

## Variables


### Polling settings
 - `ALARM_POLL_INTERVAL` 
 - `ALARM_MONITOR_INTERVAL`
 - `ALARM_MONITOR_HEALTHY_THRESHOLD`
 - `ALARM_MONITOR_UNHEALTHY_THRESHOLD`
 - `ALARM_FILTER`
 
### Email target settings
 - `ALARM_EMAIL_ADDRESSES`
 - `ALARM_EMAIL_FROM`
 - `ALARM_EMAIL_SUBJECT`
 - `ALARM_EMAIL_TEMPLATE`
 
### Slack target settings
 - `ALARM_SLACK_WEBHOOK_URL`
 - `ALARM_SLACK_CHANNEL`
 - `ALARM_SLACK_BOTNAME`
 - `ALARM_SLACK_TEMPLATE`

## Templates
### List of template variables:
 - `healthyState` HEALTHY or UNHEALTHY
 - `state` service state like it named in Rancher API
 - `prevMonitorState` rancher-alarms previous service state name
 - `monitorState` rancher-alarms service state name - e.g. always degraded for unhealthy
 - `serviceName` Name of a service in a Rancher
 - `serviceUrl` Url to a running service in a Rancher UI
 - `stackUrl` Url to stack in a Rancher UI
 - `stackName` Name of a stack in a Rancher
 - `environmentName`  Name of a environment in a Rancher
 - `environmentUrl` URL to environment in a rancher UI

### Using variables in template string:
```
Hey buddy! Your service #{serviceName} become #{healthyState}, direct link to the service #{serviceUrl}
```
 
