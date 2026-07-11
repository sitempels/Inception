# Developer Documentation

## Inception Project

This document explains how to set up, build, launch, and maintain the Inception project as a developer.

It describes:

- Required development environment.
- Configuration files.
- Secret generation.
- Build and launch workflow.
- Docker and Makefile commands.
- Container and volume management.
- Persistent data locations.

The project runs inside a Debian Virtual Machine and uses Docker containers.

# Table of Contents

- [1. Development Environment](#1-development-environment)
- [2. Repository Structure](#2-repository-structure)
- [3. Configuration Files](#3-configuration-files)
- [4. Secret Management](#4-secret-management)
- [5. Certificate Generation](#5-certificate-generation)
- [6. Makefile Workflow](#6-makefile-workflow)
- [7. Main Makefile Commands](#7-main-makefile-commands)
- [8. Docker Compose Configuration](#8-docker-compose-configuration)
- [9. Service Overview](#9-service-overview)
- [10. Docker Network](#10-docker-network)
- [11. Startup Sequence](#11-startup-sequence)
- [12. Dockerfile Overview](#12-dockerfile-overview)
- [13. Managing Containers](#13-managing-containers)
- [14. Volume Management and Data Persistence](#14-volume-management-and-data-persistence)
- [15. Development Workflow](#15-development-workflow)
- [16. Cleaning the Project](#16-cleaning-the-project)
- [17. Troubleshooting](#17-troubleshooting)
- [18. Development Notes](#18-development-notes)
- [19. Development Reference](#19-development-reference)
- [20. Project Data Lifecycle](#20-project-data-lifecycle)
- [21. Resetting the Development Environment](#21-resetting-the-development-environment)
- [22. Adding Changes to the Project](#22-adding-changes-to-the-project)
- [23. Important Files Reference](#23-important-files-reference)
- [24. Final Developer Checklist](#24-final-developer-checklist)
- [25. Summary](#25-summary)

---

# 1. Development Environment

## Requirements

The development environment requires:

- Linux Virtual Machine.
- Docker.
- Docker Compose.
- Make.
- Git.
- Bash.
- OpenSSL.
- Sudo privileges.

A VM is required because the project requires:

- Docker administration rights.
- Hostname configuration.
- Local certificate generation.
- Host filesystem access.



# 2. Repository Structure

Main project layout:

    inception/
    |
    |-- Makefile
    |-- README.md
    |-- USER_DOC.md
    |-- DEV_DOC.md
    |-- template_env
    |-- .env
    |
    |-- tools/
    |   |-- cert_creation.sh
    |   |-- cert_rootCA.sh
    |   |-- check_env.sh
    |   |-- create_secrets.sh
    |   |-- create_env.sh
    |   |
    |   |-- certs/
    |   |-- secrets/
    |
    |-- srcs/
        |
        |-- docker-compose.yml
        |
        |-- nginx/
	|   |-- Dockerfile
	|   |-- nginx.conf
	|   |-- entrypoint.sh
	|
	|-- wordpress/
	|   |-- Dockerfile
	|   |-- entrypoint.sh
	|
	|-- mariadb/
	    |-- Dockerfile
	    |-- entrypoint.sh



# 3. Configuration Files

## Environment File

The project uses a `.env` file for configuration.

The file is created from:

    template_env

The `.env` file should **NEVER** be committed to Git.

It contains:

VM configuration:

    NEW_HOSTNAME=login.42.fr

Database values:

    S_MARIADB_DATABASE=
    S_MYSQL_ROOT_PASSWORD=
    S_MYSQL_USER=
    S_MYSQL_USER_PASSWORD=

WordPress values:

    S_WP_ADMIN_USER=
    S_WP_ADMIN_PASSWORD=
    S_WP_ADMIN_EMAIL=

    S_WP_USER=
    S_WP_USER_PASSWORD=
    S_WP_USER_EMAIL=

Sensitive values must never be committed.



# 4. Secret Management

The project uses Docker secrets to handle sensitive information.

Secrets are generated from values stored in `.env`.

The generation process is handled by:

    tools/create_secrets.sh

Generated secrets are stored in:

    tools/secrets/

During container startup, Docker mounts secrets into:

    /run/secrets/

Containers read credentials from these files.



# 5. Certificate Generation

The project generates its own Certificate Authority and HTTPS certificate.

The process is handled by:

    tools/cert_rootCA.sh

and:

    tools/cert_creation.sh

Generated files:

    tools/certs/

Contains:

- Root CA certificate.
- NGINX certificate.
- NGINX private key.



# 6. Makefile Workflow

The Makefile automates the complete deployment process.

The default target is:

    make

Equivalent workflow:

1. `make host` - Configure hostname.
2. `make env` - Generate environment.
3. `make certs` - Generate certificates.
4. `make secrets` - Generate secrets.
5. `make up` - Build containers and start services.



# 7. Main Makefile Commands

## Full installation

    make

Runs the complete setup process.



## Build images

    make build

Equivalent Docker command:

    docker compose -f srcs/docker-compose.yml build

Builds:

- nginx image.
- wordpress image.
- mariadb image.



## Start services

    make up

Equivalent Docker command:

    docker compose -f srcs/docker-compose.yml up -d

Creates and starts containers in detached mode.



## Stop services

    make stop

Equivalent Docker command:

    docker compose -f srcs/docker-compose.yml stop

Stops containers without removing them.



## Remove containers

    make down

Equivalent Docker command:

    docker compose -f srcs/docker-compose.yml down

Stops and removes containers.

# 8. Docker Compose Configuration

The main orchestration file is:

    srcs/docker-compose.yml

It defines:

- Services.
- Networks.
- Volumes.
- Secrets.
- Service dependencies.

The project contains three Docker Compose services:

- nginx
- wordpress
- mariadb



# 9. Service Overview

## NGINX Service

Location:

    srcs/nginx/

Responsibilities:

- HTTPS termination.
- HTTP to HTTPS redirection.
- Static file serving.
- Forwarding PHP requests to WordPress.

Container:

    nginx

Exposed ports:

    80:80
    443:443

The container receives:

- TLS certificate.
- Private key.
- Domain name.

The certificate files are provided through Docker secrets.



## WordPress Service

Location:

    srcs/wordpress/

Responsibilities:

- Run PHP-FPM.
- Install WordPress.
- Configure WordPress.
- Connect to MariaDB.

Container:

    wordpress

Exposed internally:

    9000

The container is not directly accessible from outside.

NGINX forwards PHP requests to:

    wordpress:9000



## MariaDB Service

Location:

    srcs/mariadb/

Responsibilities:

- Initialize database.
- Create database user.
- Store WordPress data.

Container:

    mariadb

Internal port:

    3306

The service is accessible only through the Docker network.



# 10. Docker Network

The project uses a dedicated bridge network:

    inception

All containers are connected to this network.

Communication uses Docker DNS names:

Example:

WordPress connects to MariaDB using:

    mariadb

NGINX connects to WordPress using:

    wordpress

Containers communicate using Docker DNS service name instead of fixed IP addresses.



# 11. Startup Sequence

The startup process follows this order:

## Step 1: Host configuration

The Makefile checks the hostname.

If needed:

- The VM hostname is updated.
- The hosts configuration is modified.



## Step 2: Environment validation

The Makefile checks that:

- `.env` exists.
- Required variables are available.

Handled by:

    tools/check_env.sh



## Step 3: Certificate generation

If certificates do not exist:

1. Generate local Certificate Authority.
2. Generate NGINX certificate.
3. Store certificates in:

       tools/certs/



## Step 4: Secret generation

The Makefile creates Docker secret files.

Handled by:

    tools/create_secrets.sh

Secrets are stored in:

    tools/secrets/



## Step 5: Build images

Docker Compose builds:

- Alpine-based NGINX image.
- Alpine-based MariaDB image.
- Alpine-based WordPress/PHP-FPM image.

Command:

    docker compose -f srcs/docker-compose.yml build



## Step 6: Start containers

Docker Compose creates:

- Network.
- Volumes.
- Containers.

Command:

    docker compose -f srcs/docker-compose.yml up -d



## Step 7: MariaDB initialization

MariaDB entrypoint:

    srcs/mariadb/entrypoint.sh

performs:

- Database directory initialization.
- Database creation.
- User creation.
- Permission setup.

After initialization, MariaDB starts listening on port:

    3306



## Step 8: WordPress initialization

WordPress waits for MariaDB availability.

The entrypoint:

    srcs/wordpress/entrypoint.sh

performs:

- MariaDB connection test
- WordPress download
- WordPress configuration creation
- WordPress installation
- User creation

WP-CLI is used for installation.



## Step 9: NGINX startup

NGINX starts after configuration generation.

The entrypoint:

    srcs/nginx/entrypoint.sh

uses:

    envsubst

to replace:

    $DOMAIN_NAME

inside the NGINX template.

The generated configuration enables:

- HTTPS
- TLS 1.2
- TLS 1.3
- PHP forwarding



# 12. Dockerfile Overview

Each service has its own Dockerfile.

The images are based on:

    alpine:3.23

This reduces image size and provides a lightweight runtime environment.



## NGINX Dockerfile

Installs:

- nginx
- envsubst

Copies:

- nginx configuration template.
- startup script.

The container starts:

    nginx -g "daemon off;"



## MariaDB Dockerfile

Installs:

- mariadb
- mariadb-client

Creates required database directories.

The entrypoint initializes the database before starting MariaDB.



## WordPress Dockerfile

Installs:

- PHP 8.3
- PHP-FPM
- MariaDB client
- WordPress CLI

PHP-FPM listens internally on:

    port 9000

WordPress files are stored in:

    /var/www/<domain>

# 13. Managing Containers

Developers can use Docker Compose directly or use the Makefile shortcuts.

The Makefile is recommended for normal project operations.



# 13.1 Viewing Running Containers

Display active containers:

    docker ps

Example expected output:

    nginx
    wordpress
    mariadb

To display stopped containers:

    docker ps -a



# 13.2 Viewing Container Logs

Logs are essential for debugging startup problems.

NGINX:

    docker logs nginx

WordPress:

    docker logs wordpress

MariaDB:

    docker logs mariadb

Follow logs in real time:

    docker logs -f <container_name>

Example:

    docker logs -f wordpress



# 13.3 Restarting Services

Restart one container:

    docker restart <container_name>

Example:

    docker restart nginx

Restart the whole stack:

    make stop
    make start



# 13.4 Rebuilding Containers

After modifying a Dockerfile or service configuration:

Build images:

    make build

or:

    docker compose -f srcs/docker-compose.yml build

Restart the stack:

    make up



# 13.5 Removing Containers

Remove running containers:

    make down

Equivalent:

    docker compose -f srcs/docker-compose.yml down

This removes:

- Containers.
- Docker network created by Compose.

Persistent data remains available.



# 14. Volume Management and Data Persistence

The project uses persistent storage to keep data outside containers.

The data remains available when:

- Containers are restarted.
- Images are rebuilt.
- Containers are recreated.



# 14.1 MariaDB Storage

MariaDB data is stored in:

    /home/<user>/data/mariadb

Docker mounts this directory to:

    /var/lib/mysql

inside the MariaDB container.

This contains:

- Database files.
- User information.
- WordPress database content.



# 14.2 WordPress Storage

WordPress data is stored in:

    /home/<user>/data/wordpress

Docker mounts this directory to:

    /var/www/<domain>

inside the WordPress and NGINX containers.

This contains:

- WordPress core files.
- Themes.
- Plugins.
- Uploaded media.
- Configuration files.



# 14.3 Checking Volumes

List Docker volumes:

    docker volume ls

Inspect a volume:

    docker volume inspect <volume_name>

Inspect container mounts:

    docker inspect wordpress

    docker inspect mariadb



# 15. Development Workflow

A typical development workflow:

## 1. Modify source files

Examples:

    srcs/nginx/nginx.conf

    srcs/wordpress/entrypoint.sh



## 2. Rebuild affected images

Example:

    make build



## 3. Restart services

Example:

    make up



## 4. Verify operation

Check containers:

    docker ps

Check logs:

    docker logs <container_name>



# 16. Cleaning the Project

The Makefile provides several cleanup levels.



## Clean containers and images

Command:

    make clean

Removes:

- Containers
- Images

Persistent data remains.



## Full cleanup

Command:

    make fclean

Removes:

- Containers
- Images
- Volumes
- Project data

Specifically:

    /home/<user>/data

is deleted.

This returns the project to a fresh installation state.



## Rebuild from scratch

Command:

    make re

Equivalent workflow:

    make clean
    make 

This rebuilds containers and images while preserving persistent data.


## Full reset and reinstall

Command:

    make fre

Equivalent workflow:

    make fclean
    make

This removes all generated data and recreates the project from zero.



# 17. Troubleshooting

## Build fails

Check:

- Docker daemon is running.
- Internet access is available.
- Required packages can be downloaded.

Useful commands:

    docker info

    docker images

    docker system df



## Container exits immediately

Check logs:

    docker logs <container_name>

Common causes:

- Missing secret files.
- Invalid environment configuration.
- Incorrect permissions.
- Configuration syntax errors.



## WordPress cannot reach MariaDB

Verify:

MariaDB container:

    docker ps

MariaDB logs:

    docker logs mariadb

WordPress logs:

    docker logs wordpress

The WordPress container depends on MariaDB health status before starting.



## NGINX returns errors

Check:

NGINX logs:

    docker logs nginx

Verify:

- Certificate files exist.
- Domain name is correctly configured.
- WordPress container is running.



# 18. Development Notes

The project follows these principles:

- Each service runs in its own container.
- Containers are built independently.
- Sensitive values are stored as Docker secrets.
- Persistent data is stored outside containers.
- Services communicate only through the dedicated Docker network.

The Makefile provides a simplified interface while Docker Compose remains the underlying container management system.

# 19. Development Reference

This section provides a quick reference for common development operations.



# 19.1 Starting a Development Session

From the project root:

    cd inception

Start the stack:

    make

Verify containers:

    docker ps

Expected services:

    nginx
    wordpress
    mariadb



# 19.2 Accessing Containers

Open a shell inside a running container:

    docker exec -it <container_name> sh

Examples:

NGINX:

    docker exec -it nginx sh



# 19.3 Inspecting Container Configuration

View container details:

    docker inspect <container_name>

Useful information:

- Mounted volumes.
- Environment.
- Network configuration.
- Container state.



# 19.4 Inspecting the Docker Network

The project uses the network:

    inception

View networks:

    docker network ls

Inspect the project network:

    docker network inspect inception

This allows checking:

- Connected containers.
- Network configuration.
- Container IP addresses.



# 20. Project Data Lifecycle

The project separates application code and persistent data.

## Application code

Stored in the repository:

    srcs/

Modified through:

- Dockerfiles.
- Configuration files.
- Entrypoint scripts.

Changes require rebuilding containers.



## Persistent data

Stored outside containers:

    /home/<user>/data/

Contains:

    wordpress/

and:

    mariadb/

This data survives:

- Container deletion.
- Image rebuild.
- Docker Compose recreation.



# 21. Resetting the Development Environment

When testing a fresh installation, remove all generated data:

    make fclean

Then recreate:

    make

Or directly use:

    make fre

The project will:

1. Generate new certificates.
2. Generate new secrets.
3. Initialize a new database.
4. Install WordPress again.



# 22. Adding Changes to the Project

When modifying an existing service:

Example:

    srcs/nginx/

or:

    srcs/wordpress/

The usual workflow is:

1. Edit files.
2. Rebuild images.

        make build

3. Restart containers.

        make up

4. Verify logs.

        docker logs <container_name>



# 23. Important Files Reference

| File | Purpose |
|------|---------|
| Makefile | Main project automation |
| docker-compose.yml | Container orchestration |
| .env | Local configuration |
| template\_env | Environment template |
| nginx.conf | NGINX configuration template |
| nginx Dockerfile | Builds NGINX image |
| wordpress Dockerfile | Builds WordPress/PHP-FPM image |
| mariadb Dockerfile | Builds MariaDB image |
| entrypoint.sh files | Container initialization scripts |
| tools/create\_secrets.sh | Secret generation |
| tools/create\_env.sh | Environment generation |



# 24. Final Developer Checklist

Before considering the project correctly deployed:

## Environment

Check:

    .env

exists and contains required values.



## Secrets

Check:

    tools/secrets/

contains generated secret files.



## Certificates

Check:

    tools/certs/

contains:

- Root CA certificate.
- NGINX certificate.
- Private key.



## Containers

Check:

    docker ps

shows:

- nginx
- wordpress
- mariadb



## Storage

Check:

    /home/<user>/data/

contains:

- wordpress data.
- mariadb data.



# 25. Summary

The development workflow is:

1. Configure environment.

       .env

2. Generate secrets and certificates.

       make

3. Build containers.

       make build

4. Start services.

       make up

5. Manage containers using Docker commands.

       docker ps
       docker logs
       docker exec

6. Persistent data is maintained outside containers.

       /home/<user>/data/

The project uses Docker Compose for orchestration and the Makefile as a simplified developer interface.
