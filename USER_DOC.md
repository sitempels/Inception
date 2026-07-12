*This project has been created as part of the 42 curriculum by stempels*
# User Documentation

## Inception Project

This document explains how to use and administer the Inception project stack.

The goal of this document is to provide simple instructions for:
- understanding the services provided by the stack,
- starting and stopping the project,
- accessing the website and administration panel,
- managing credentials,
- checking that services are running correctly.

---

# Table of Contents

- [1. Overview](#1-overview)
- [2. Services Provided](#2-services-provided)
  - [NGINX](#nginx)
  - [WordPress](#wordpress)
  - [MariaDB](#mariadb)
- [3. Starting the Project](#3-starting-the-project)
  - [First installation](#first-installation)
- [4. Stopping the Project](#4-stopping-the-project)
- [5. Accessing the Website](#5-accessing-the-website)
- [6. Trusting the Certificate Authority](#6-trusting-the-certificate-authority)
  - [Why does the browser show a warning?](#why-does-the-browser-show-a-warning)
- [7. Accessing the WordPress Administration Panel](#7-accessing-the-wordpress-administration-panel)
- [8. Configuration and Credential Management](#8-configuration-and-credential-management)
  - [Environment configuration](#environment-configuration)
  - [Docker secrets](#docker-secrets)
  - [Changing credentials](#changing-credentials)
- [9. Checking Service Status](#9-checking-service-status)
- [10. Checking Logs](#10-checking-logs)
- [11. Additional Docker Checks](#11-additional-docker-checks)
- [12. Managing Persistent Data](#12-managing-persistent-data)
- [13. Common Problems](#13-common-problems)
- [14. Useful Administration Commands](#14-useful-administration-commands)
- [15. Complete Reset](#15-complete-reset)
- [16. Summary](#16-summary)



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

| Command |   | Containers | Images | Data/Volumes |
|---------|:-:|:----------:|:------:|:------------:|
| bash make stop | retain | ✅ | ✅ | ✅ |
| make down | retain | ❌ | ✅ | ✅ |
| make clean | retain | ❌ | ❌ | ✅ |
| make fclean | retain | ❌ | ❌ | ❌ |

*Note: ****make re**** call clean and ****make fre**** call fclean*



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
This enable the use of HTTPS by encrypting communications between the client and the server.

This project creates its own certificate authority locally because it is designed to run inside a private environment.

The browser does not automatically trust this certificate authority, so it displays a certificate warning.
Here the certificate is added to the trusted certificate of the VM.
After adding the CA certificate to the VM's trusted certificate store, browsers and system tools should trust certificates generated by this local authority.



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

*Note: ****Administrator email**** is required but does not need to be a valid or existing address, because no email server is configured.*



# 8. Configuration and Credential Management

The `.env` file is used during installation.

It contains configuration values and references used to generate secrets.

The `.env` file must **never** be committed to Git.

## Environment configuration

Such as NEW\_HOSTNAME, they are used to configure the VM and/or the containers.

## Docker secrets

Prefixed by **S_**, their value is set up in the `.env`

Credentials are never stored directly inside Docker Compose environment variables.

Instead, sensitive information is stored using Docker secrets.

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

    /home/<user>/data/mariadb


Contains:

- MariaDB database files.
- Website database information.



# 13. Common Problems

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



# 14. Useful Administration Commands

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



# 15. Complete Reset

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



# 16. Summary

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

## Authors

**Author:** Simon Tempels

**42 Login:** `stempels`


## License

This project is part of the 42 school curriculum.  
For educational purposes only.

---

**Last Updated:** July 2026  
**Project:** Inception  
**School:** 42
