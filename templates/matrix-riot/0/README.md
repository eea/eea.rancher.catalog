# Rancher configuration

## Only for test environment - letsencrypt certificate generation

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
6. Matrix email FROM - Email used to send notifications from Matrix
7. Matrix https URL - Matrix https URL
8. Riot https URL - Riot https URL

#### Riot web site related parameters
9. Matrix identity service https URL - Matrix identity service https URL


#### Identity server/LDAP parameters
10. LDAP host - LDAP EIONET host/ip
11. LDAP binddn - The DN for the user to read from LDAP
12. LDAP binddn password - The password for the user to read from LDAP
13. LDAP base DN - LDAP BASE DN to give access to users
14. LDAP port - Access port for LDAP
15. LDAP TLS enabled ( true/false) - LDAP TLS enabled true/false
16. LDAP filter users - Used to filter the users from LDAP with access
17. Identity server JAVA options - Identity server JAVA extra options

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
| 9        | Public | HTTPS    | MATRIX_URL                                  | 443  | None                               | matrix-riot/matrix        | 8008 | None    |
| 10       | Public | TCP      | n/a                                        | 8448 | n/a                                | matrix-riot/synapse       | 8448 | None    |

#### Certificates
Add the corresponding certificate from Rancher to the Load Balancer, Default Certificate.

### Scheduling rules
Make sure the scheduller sets the Load Balancer and Matrix containers on the server that has the public IP added in DNS.

The ports that must be accessed are:

* Load Balancer : 80 and 443
* Matrix: 8448 (for federation) and 3478 - UDP and TCP (for VOIP between 2 Matrix homeservers).

