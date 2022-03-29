SingleSignOn mechanism for EEA

```
Installation
```
1. Create 3 NetApp volumes:
* keycloak_postgres_pg_0_data
* keycloak_postgres_pg_1_data
* eea_keycloak_theme

2. From EEA Rancher Catalog choose "Keycloak". Please provide:
* Keycloak administrator: username and password
* Keycloak database connection: username and password
* Postgresql POSTGERS password
* Postgresql replication password
* Keycloak hostname

3. Execute shell on keycloak-theme container:
* Go to /keycloak-theme
* git clone https://github.com/eea/keycloak-theme


```
Update
```

1. Create a new version in github, eea.rancher.catalog
2. From Rancher UI, refresh the catalog in the environment where keycloak stack is installed.
3. Click on "Update available" button.
4. Modify or keep the existent secrets.
5. Click on Update


```
Rollback
```

Rollback is possible immediately after an upgrade, before "Finish upgrade" action.


```
Downgrade
```

Downgrade is done by installing another stack in the same Rancher environment, then changing the links in Rancher's LB.. If it's a different postgresql major version, the database should be recreated manually, then the data should be reimported from backup using pg_restore.


```
Update keycloak theme
```

In order to update the EEA's keycloak theme, the following steps are necessary:
1. Execute shell in keycloak-theme container
2. Go to /keycloak-theme
3. git pull
4. Execute shell on keycloak container
5. Delete the content of the following folder: /opt/keycloak/data/tmp/kc-gzip-cache

