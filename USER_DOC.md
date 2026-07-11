# User Documentation

## Inception Project

This document explains how to use and administer the Inception project stack.

The goal of this document is to provide simple instructions for:
- understanding the services provided by the stack,
- starting and stopping the project,
- accessing the website and administration panel,
- managing credentials,
- checking that services are running correctly.

This documentation assumes that the user does not need advanced Docker knowledge.

---

# 1. Overview

The Inception project runs a complete web application stack inside Docker containers.

The stack provides:

- A secure HTTPS entry point.
- A WordPress website.
- A MariaDB database used by WordPress.
- Persistent storage so that data remains available after restarting containers.

The services are isolated in separate containers and communicate through a private Docker network.



# 2. Services Provided

## NGINX

NGINX is the public entry point of the infrastructure.

Its responsibilities are:

- Accept incoming web requests.
- Provide HTTPS encryption.
- Redirect HTTP traffic to HTTPS.
- Forward PHP requests to the WordPress container.

The user only interacts directly with NGINX.

The service is accessible through:
https://login.42.fr



## WordPress

WordPress provides the website interface.

It handles:

- Website pages.
- User accounts.
- Administration interface.
- Content management.

The WordPress administration panel is available at:
https://login.42.fr/wp-admin



## MariaDB

MariaDB stores the website data.

It contains:

- WordPress configuration data.
- User accounts.
- Posts and pages.
- Website settings.

MariaDB is not directly accessible from outside the Docker network.



# 3. Starting the Project

## First installation

To start the project:

```bash
make
```

Before starting the project, the administrator must configure the environment file.

If a `template_env` file is available:

The installation process will:

Create the .env file.
Ask for required configuration values.
Generate certificates.
Generate secrets.
Create persistent storage directories.
Build and start the containers.
Starting the stack

If there is no `template_env` see: [Installation](README.md#installation)

The first launch may take some time because:

Docker images are built.
The database is initialized.
WordPress is downloaded and configured automatically.



# 4. Stopping the Project

To stop the project, you have several options at your disposal:

| Command | | Containers | Images | Data/Volumes |
| make stop | retain | ✅ | ✅ | ✅ |
| make down | retain | ❌ | ✅ | ✅ |
| make clean | retain | ❌ | ❌ | ✅ |
| make fclean | retain | ❌ | ❌ | ❌ |

*Note: ****make re**** call fclean*



# 5. Accessing the Website

After the containers are running, the website is available through HTTPS:

    https://login.42.fr

The connection uses a custom certificate generated during installation.

If the browser displays a certificate warning, this is expected.

The certificate is not signed by a public certificate authority. It is signed by a local Certificate Authority created for this project.

To remove the warning, the local root CA certificate must be trusted by the operating system.



# 6. Trusting the Certificate Authority

## Why does the browser show a warning?

Public websites usually use certificates signed by trusted certificate authorities.

This project creates its own certificate authority locally because it is designed to run inside a private environment.

The browser does not automatically trust this certificate authority, so it displays a warning.

## Trusting the generated root CA

The generated root certificate is located in:

    tools/certs/ca.crt

The exact installation procedure depends on the operating system.

### Debian / Linux

Copy the certificate:

    sudo cp tools/certs/ca.crt /usr/local/share/ca-certificates/inception-ca.crt

Update the certificate store:

    sudo update-ca-certificates

Restart the browser.

After this operation, the browser should trust:

    https://login.42.fr



# 7. Accessing the WordPress Administration Panel

The WordPress administration interface is available at:

    https://login.42.fr/wp-admin

The administrator account is created automatically during the first installation.

The credentials are defined during setup through the environment configuration.

Required information:

- Administrator username.
- Administrator password.
- Administrator email.

Example:

    Username: <WP_ADMIN_USER>
    Password: <WP_ADMIN_PASSWORD>

Replace these placeholders with the values configured during installation.



# 8. Credential Management

The project uses several types of credentials.

Credentials are never stored directly inside Docker Compose environment variables.

Instead, sensitive information is stored using Docker secrets.

## Environment configuration

The `.env` file is used during installation.

It contains configuration values and references used to generate secrets.

The `.env` file must not be committed to Git.

Example location:

    .env

## Docker secrets

Docker secrets contain sensitive values such as:

- MariaDB database name.
- MariaDB root password.
- MariaDB user password.
- WordPress administrator credentials.
- WordPress user credentials.

Secrets are generated during installation.

They are stored locally in:

    tools/secrets/

Inside containers, secrets are available through:

    /run/secrets/

## WordPress credentials

The project creates:

### Administrator account

Used to manage WordPress.

Defined by:

    WP_ADMIN_USER
    WP_ADMIN_PASSWORD
    WP_ADMIN_EMAIL

### Regular WordPress user

Created automatically during installation.

Defined by:

    WP_USER
    WP_USER_PASSWORD
    WP_USER_EMAIL

## Changing credentials

To change credentials after installation:

1. Log into the WordPress administration panel.
2. Update users from the WordPress interface.

For database credentials or Docker secrets:

1. Stop the project.
2. Update the configuration.
3. Recreate the containers if required.

Changing database credentials on an already initialized installation requires updating the WordPress database configuration as well.



# 9. Checking Service Status

The simplest way to verify that containers are running:

    docker ps

A successful installation should show:

- nginx
- wordpress
- mariadb

with the status:

    Up



# 10. Checking Logs

Logs are useful when a service does not start correctly.

## NGINX logs

    docker logs nginx

## WordPress logs

    docker logs wordpress

## MariaDB logs

    docker logs mariadb



# 11. Additional Docker Checks

Display all containers:

    docker ps -a

Inspect a container:

    docker inspect <container_name>

Check Docker networks:

    docker network ls

Check Docker volumes:

    docker volume ls

These commands help administrators identify configuration or startup problems.

# 12. Managing Persistent Data

The project stores important data outside the containers.

This ensures that restarting or rebuilding containers does not delete the website or database.

The persistent data locations are:

    /home/<user>/data/wordpress

Contains:

- WordPress files.
- Website content.
- WordPress configuration.

---

    /home/<user>/data/mariadb

Contains:

- MariaDB database files.
- Website database information.



# 13. Backup Recommendations

The project data should be backed up regularly.

Important directories:

    /home/<user>/data/wordpress
    /home/<user>/data/mariadb

A backup can be created by copying these directories to another storage location.

Example:

    cp -r /home/<user>/data /backup/inception/

The backup should only be performed when the services are stopped or when database consistency is guaranteed.



# 14. Common Problems

## Website is unreachable

Check that the containers are running:

    docker ps

Expected services:

- nginx
- wordpress
- mariadb

If a service is missing, check its logs:

    docker logs <container_name>

## Browser certificate warning

Cause:

The browser does not trust the local Certificate Authority.

Solution:

Install the generated root CA certificate:

    tools/certs/ca.crt

into the operating system certificate store.

## WordPress cannot connect to the database

Check MariaDB status:

    docker logs mariadb

Check WordPress logs:

    docker logs wordpress

The database container must be running before WordPress can start correctly.

## Website changes disappear after restart

The project uses persistent storage.

If data disappears, check that the volumes are correctly mounted:

    docker inspect wordpress

    docker inspect mariadb



# 15. Useful Administration Commands

## View running containers

    docker ps

## Restart a service

Example:

    docker restart nginx

## Stop all services

    make stop

## Start all services

    make start

## Rebuild the project

    make re

This recreates the containers and images.

Persistent data is preserved.



# 16. Complete Reset

To remove all Docker resources created by the project:

    make fclean

This removes:

- Containers.
- Images.
- Volumes.
- Website files.
- Database files.

After this operation, the installation must be performed again.

Use this command only when a complete reset is intended.



# 17. Summary

The Inception stack provides:

| Service | Purpose |
|---------|---------|
| NGINX | HTTPS web entry point |
| WordPress | Website and administration interface |
| MariaDB | Database storage |

Main user actions:

Start:

    make

Stop:

    make stop

Check status:

    docker ps

View logs:

    docker logs <container_name>

Website:

    https://login.42.fr

Administration panel:

    https://login.42.fr/wp-admin

The project keeps website and database data persistent through storage mounted outside the containers.
