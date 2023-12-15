# Rancher configuration


## Prerequisites

This stack needs 3 public url, open on specified port and a valid certificate, so before installing, you need to make sure:

1. There are 3 new entries in the DNS - riot, matrix and matrix-identity that point to the LoadBalancer(riot and matrix-identity) and server ( matrix )  you will be using to install the stack
2. For each of the 3 urls, because they will be accessed on https you will need a valid and TRUSTED certificate ( letsencrypt can be used).
3. The matrix server must be installed on the same host as the load balancer
3. If you are using letsencrypt for a certificate, you need to ask for a DNS exception for the IPs you are using
3. This firewall accesses must be opened:
   1. riot url - TCP 443 and TCP 80 ( if you are using letsencrypt)
   2. matrix-identity  url - TCP 443 and TCP 80 ( if you are using letsencrypt)
   3. matrix -  TCP 443 and TCP 80 ( if you are using letsencrypt) and 3478 ( UDP ) for VOIP and 8448 (HTTPS) for federation with synapse servers older than v1.0
   
   

## Letsencrypt certificate generation

1. Add Let's Encrypt Stack - community catalog.
2. Important mandatory parameters :
   1. Domain Names - set all 3 urls used in matrix stack, separated by comma
   2. Let's Encrypt API Version - to test the stack - use Sandbox. For a valid, trusted certificate - use Production.
   3. Domain Validation Method - HTTP

Add a load balancer in stack, and for each url, redirect HTTP 80 with Path = /.well-known/acme-challenge to letsencrypt service, port 80

## Matrix Stack

### Matrix Stack Parameters

#### Matrix server related parameters
1. Matrix homeserver public FQDN - The public url of matrix, used in federation and under which every user is saved; Is used in Riot and Identity containers
2. Matrix.org report stats (yes/no) - Send data to matrix.org: hostname, synapse version & uptime, total_users, total_nonbridged users, total_room_count, daily_active_users, daily_active_rooms, daily_messages and daily_sent_messages.
3. Matrix database user - Matrix postgres database user
4. Matrix database password - Matrix postgres database password
5. Matrix database name - Matrix postgres database name
6. Matrix-Riot email sender address - Used to send notifications from stack
7. Matrix-Riot email sender name - Used to send notifications from stack
8. Matrix https URL - Matrix https URL
9. Riot https URL - Riot https URL

#### Riot web site related parameters
10. Matrix identity service https URL - Matrix identity service https URL


#### Identity server/LDAP parameters
11. LDAP host - LDAP EIONET host/ip
12. LDAP binddn - The DN for the user to read from LDAP
13. LDAP binddn password - The password for the user to read from LDAP
14. LDAP base DN - LDAP BASE DN to give access to users
15. LDAP port - Access port for LDAP
16. LDAP TLS enabled ( true/false) - LDAP TLS enabled true/false
17. LDAP filter users - Used to filter the users from LDAP with access
18. Identity server JAVA options - Identity server JAVA extra options
19. Synapse appservice-mxisd app HS token - Used to integrate the identity service with matrix server
20. Synapse appservice-mxisd app AS token - Used to integrate the identity service with matrix server

#### Volumes parameters

It is recommended for non-dev installations to use NFS on the Matrix Volume, because it will increase in size with use. All the conversations, including files will be saved on it. 

### Load balancer configuration

#### Balancer rules
| Priority | Access | Protocol | Request Host                               | Port | Path                               | Target                    | Port | Backend |
|----------|--------|----------|--------------------------------------------|------|------------------------------------|---------------------------|------|---------|
| 1        | Public | HTTP     | MATRIX_URL                                 | 80   | /.well-known/acme-challenge        | letsencrypt/letsencrypt   | 80   | None    |
| 2        | Public | HTTP     | RIOT_URL                                   | 80   | /.well-known/acme-challenge        | letsencrypt/letsencrypt   | 80   | None    |
| 3        | Public | HTTP     | IDENTITY_URL                               | 80   | /.well-known/acme-challenge        | letsencrypt/letsencrypt   | 80   | None    |
| 4        | Public | HTTPS    | RIOT_URL                                   | 443  | None                               | matrix-riot/riot          | 80   | None    |
| 5        | Public | HTTPS    | IDENTITY_URL                               | 443  | None                               | matrix-riot/identity      | 8090 | None    |
| 7        | Public | HTTPS    | MATRIX_URL                                 | 443  | /_matrix/client/r0/user_directory/   | matrix-riot/identity      | 8090 | None    |
| 8        | Public | HTTPS    | MATRIX_URL                                 | 443  | /_matrix/identity/                  | matrix-riot/identity      | 8090 | None    |
| 9        | Public | HTTPS    | MATRIX_URL                                  | 443  | /.well-known/matrix/server         | matrix-riot/federation    | 80   | None    |
| 10       | Public | HTTPS    | MATRIX_URL                                  | 443  | None                               | matrix-riot/matrix        | 8008 | None    |
| 11       | Public | HTTPS    | MATRIX_URL                                  | 8448  | None                               | matrix-riot/matrix        | 8008 | None    |

#### Certificates
Add the corresponding certificate from Rancher to the Load Balancer, Default Certificate.

### Scheduling rules
Make sure the scheduller sets the Load Balancer and Matrix containers on the server that has the public IP added in DNS.

The ports that must be accessed are:

* Load Balancer : 80 and 443
* Matrix: 3478 - UDP and TCP (for VOIP between 2 Matrix homeservers).

### Notes
* Starting with version 1.7, we are not using port 8448 for federation, but creating a redirect to the https of the matrix server. Documentation is available: https://github.com/matrix-org/synapse/blob/master/docs/federate.md


