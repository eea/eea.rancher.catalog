# Celery worker

Consume vanilla RabbitMQ messages or Celery tasks.

Celery is an open source asynchronous task queue/job queue based on distributed message passing. It is focused on real-time operation, but supports scheduling as well.

This stack allows you to run Celery worker together with your custom **Python dependencies**
by passing **requirements** and **contraints** via environment variables `REQUIREMENTS` respectively `CONSTRAINTS`.
It also has the ability to consume **vanilla AMQP messages** (i.e. **not** Celery tasks) based on
[celery-message-consumer](https://pypi.org/project/celery-message-consumer/)

[See more](https://github.com/eea/eea.docker.celery)

## Configuration


- `RabbitMQ` - RabbitMQ hostname where from to consume messages
- `RabbitMQ user` - RabbitMQ client user name
- `RabbitMQ password` - RabbitMQ client password
- `requirements.txt` - Python packages to install at load time (see more about [requirements.txt](https://pip.pypa.io/en/stable/user_guide/#requirements-files))
- `constraints.txt` - Python packages versions pins (see more about [constraints.txt](https://pip.pypa.io/en/stable/user_guide/#constraints-files))
- `Tasks` - Python code to run your tasks (see [tasks](https://github.com/eea/eea.docker.celery#run-with-docker-compose) example)
- `Maximum retries` - How many times should Celery retry a job until mark it as failed.
- `Keep failed messages` - Time in milliseconds to keep the history of the failed jobs.
- `Time zone` - Time zone
