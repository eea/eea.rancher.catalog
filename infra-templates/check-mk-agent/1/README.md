# eea.docker.check-mk-agent
Docker container running check_mk_agent-1.6.0p12-1 and xinetd.
Easily install check-mk-agent on docker hosts.
Base image - latest centos image.
Configuration for logwatch plugin added.
# Usage example
docker run -it -d --name=check_mk-agent -p 6556:6556 eea/eea.docker.check-mk-agent
