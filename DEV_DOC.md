# Developer Documentation

> Technical reference for developers working on the **Inception** project.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites and Environment Setup](#prerequisites-and-environment-setup)
  - [System Requirements](#system-requirements)
  - [Install Docker](#1-install-docker)
  - [Add Docker's GPG Key](#2-add-dockers-official-gpg-key)
  - [Add Docker's Repository](#3-add-dockers-official-repository)
  - [Install Docker Engine](#4-install-docker-engine--all-plugins)
  - [Verify the Installation](#5-verify-the-installation)
  - [Add User to Docker Group](#6-add-your-user-to-the-docker-group)
  - [Clone and Set Up Repository](#7-clone-and-set-up-repository)
  - [Set Up Environment Variables](#8-set-up-environment-variables)
  - [Start the Infrastructure](#9-start-the-infrastructure)
- [Configuration Files](#configuration-files)
  - [Docker Compose Configuration](#docker-compose-configuration)
  - [Makefile Structure and Automation](#makefile-structure-and-automation)
- [Building the Project](#building-the-project)
- [Docker Compose Management](#docker-compose-management)
- [Container Management](#container-management)
- [Volume Management](#volume-management)
- [Network Configuration](#network-configuration)
- [Service Details](#service-details)
  - [NGINX](#nginx-service)
  - [WordPress](#wordpress-service)
  - [MariaDB](#mariadb-service)
- [Debugging](#debugging)
- [Security Considerations](#security-considerations)
- [Data Storage and Persistence](#data-storage-and-persistence)
- [Useful Commands Reference](#useful-commands-reference)

---

## Overview

Inception is a multi-container Docker application that demonstrates infrastructure as code principles. The project consists of three services — **NGINX**, **WordPress**, and **MariaDB** — orchestrated via Docker Compose, with emphasis on security, modularity, and best practices.

### Technical Stack

| Component | Technology |
|---|---|
| Containerization | Docker |
| Orchestration | Docker Compose |
| Base Images | Debian (penultimate stable) |
| Web Server | NGINX with TLSv1.2/1.3 |
| Application | WordPress + PHP-FPM |
| Database | MariaDB |
| Automation | Makefile |

### Architecture Principles

1. **Service Isolation** — Each service runs in its own container
2. **No Hacky Patches** — Proper daemon processes, no infinite loops
3. **Custom Images** — All Dockerfiles built from scratch
4. **Named Volumes** — Persistent storage managed by Docker
5. **Bridge Network** — Isolated container communication
6. **Environment Variables** — Configuration via `.env` file
7. **Security First** — No hardcoded credentials, TLS only

---

## Prerequisites and Environment Setup

### System Requirements

**Virtual Machine:**
- Linux distribution (Ubuntu)
- Minimum 2 GB RAM
- 10 GB free disk space
- Root / sudo access

**Verify installed tools:**

```bash
# Check Docker version
docker --version
# Check Docker Compose version
docker-compose --version
# Check Make
make --version
```

---

### 1. Install Docker

#### Required Dependencies

| Package | Role |
|---|---|
| `ca-certificates` | Verifies SSL certificates and secures HTTPS connections |
| `curl` | Fetches files and communicates with APIs over HTTP/HTTPS |
| `gnupg` | Verifies that downloaded packages genuinely come from Docker |
| `lsb-release` | Provides distribution info to configure the correct repository |

```bash
# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install -y ca-certificates curl gnupg lsb-release
```

---

### 2. Add Docker's Official GPG Key

Every Docker package is signed with a private key. Your system needs the corresponding public key to verify this signature. We download it and install it into `/etc/apt/keyrings/`.

> **Result:** When you run `apt install docker-ce`, Debian will verify the package is genuine and untampered.

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

**Command breakdown:**

| Part | Role |
|---|---|
| `mkdir -p /etc/apt/keyrings` | Creates the GPG key storage folder if needed |
| `curl -fsSL ...` | Downloads Docker's official GPG key |
| `gpg --dearmor` | Converts the key into a format readable by apt |
| `-o /etc/apt/keyrings/docker.gpg` | Saves the converted key |

---

### 3. Add Docker's Official Repository

By default, Debian does not include the most recent Docker packages. Adding Docker's official repository tells `apt` where to look for `docker-ce`.

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**Command breakdown:**

| Part | Role |
|---|---|
| `echo "deb ... stable"` | Creates the repository entry line |
| `arch=$(dpkg --print-architecture)` | Auto-detects your machine's architecture (amd64, arm64, etc.) |
| `signed-by=/etc/apt/keyrings/docker.gpg` | Tells apt to use the GPG key from step 2 |
| `$(lsb_release -cs)` | Retrieves your Debian codename (e.g. `bookworm`) |
| `sudo tee /etc/apt/sources.list.d/docker.list` | Writes the entry into a dedicated Docker repo file |
| `> /dev/null` | Suppresses output to keep the terminal clean |

> **Result:** Your Debian system now knows about the official Docker repository.

---

### 4. Install Docker Engine + All Plugins

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**Package breakdown:**

| Package | Role |
|---|---|
| `docker-ce` | Main Docker engine — manages containers |
| `docker-ce-cli` | Command-line interface (`docker run`, `docker ps`, …) |
| `containerd.io` | Container runtime — executes containers |
| `docker-buildx-plugin` | Extension for building advanced Docker images |
| `docker-compose-plugin` | Native Docker Compose v2 support (`docker compose`) |

---

### 5. Verify the Installation

```bash
docker --version
docker compose version
```

> **Result:** Displays the version of each tool.

```bash
docker run hello-world
```

> **Result:** Launches an ephemeral container, prints a confirmation message, then shuts down.

---

### 6. Add Your User to the Docker Group

```bash
sudo usermod -aG docker $USER
```

> Log out and back in for this change to take effect.

---

### 7. Clone and Set Up Repository

```bash
# Clone the repository
git clone <repository-url>
cd inception

# Verify structure
ls -la
# Expected: Makefile, srcs/, README.md, etc.
```

---

### 8. Set Up Environment Variables

```bash
# Create .env file
touch srcs/.env

# Edit with your values
vim srcs/.env
```

Your `.env` file should contain:

```bash
DOMAIN_NAME=login.42.fr
SQL_DATABASE=example_db
SQL_USER=example_user
SQL_PASSWORD=example_password
SQL_ROOT_PASSWORD=example_root_password
WP_ADMIN_USER=example_superuser
WP_ADMIN_PASSWORD=example_superuser_password
WP_ADMIN_EMAIL=superuser@example.org
WP_USER=example_username
WP_USER_PASSWORD=example_user_password
WP_USER_EMAIL=user@example.xyz
SQL_DATA_PATH=/home/login/data/mariadb
WP_DATA_PATH=/home/login/data/wordpress
```

> **Important:** Never commit this file to Git.  
> The Makefile will automatically update `/home/*/data/` paths to match your current username.

---

### 9. Start the Infrastructure

```bash
# Single command handles everything
make
```

This single command handles the entire setup automatically:

1. ✅ Verifies and updates your `.env` file (`make check-env`)
2. ✅ Adds your domain to `/etc/hosts` (`make hosts`)
3. ✅ Creates required volume directories (`make init`)
4. ✅ Builds all Docker images
5. ✅ Starts all containers

> You no longer need to manually create data directories, add the domain to `/etc/hosts`, or update paths in `.env`.

---

## Configuration Files

> **Important:** Never commit `.env` to Git.

### Docker Compose Configuration

The `docker-compose.yml` file defines the full infrastructure:

```yaml
services:
  # 🔹 MariaDB service
  mariadb:
    image: mariadb
    build:                      # 🔨 Specifies how to build the image
      context: ./requirements/mariadb  # 📁 Path to the folder containing the Dockerfile
      dockerfile: Dockerfile          # 📄 Dockerfile name
    container_name: mariadb     # 🧱 Custom container name
    env_file: .env              # 📦 Environment variables to load
    volumes:                    # 💾 Persistent volume for MariaDB data
      - mariadb_data:/var/lib/mysql
    networks:                   # 🌐 Docker network (allows services to communicate)
      - inception
    restart: unless-stopped     # 🔁 Restart unless manually stopped

  # 🔹 WordPress service (with PHP-FPM)
  wordpress:
    image: wordpress
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    env_file: .env
    volumes:
      - wordpress_data:/var/www/html  # 📁 Shared folder containing WordPress files
    networks:
      - inception
    depends_on:
      - mariadb               # ⏳ Start WordPress only if MariaDB is ready
    restart: unless-stopped

  # 🔹 NGINX service
  nginx:
    image: nginx
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    env_file: .env
    ports:
      - "443:443"             # 🌍 HTTPS port exposed locally
    volumes:
      - wordpress_data:/var/www/html  # 📁 Share WordPress files with NGINX
    networks:
      - inception
    depends_on:
      - wordpress             # ⏳ NGINX waits until WordPress is ready
    restart: unless-stopped

  # 🔸 Persistent volumes definition
volumes:
  mariadb_data:
    driver: local
  wordpress_data:
    driver: local

# 🔸 Custom network allowing containers to communicate
networks:
  inception:
    driver: bridge            # 🧭 Bridge network: all containers share an isolated network


```

---

### Makefile Structure and Automation

The project includes an intelligent Makefile that automates setup, configuration, and management.

#### Color Definitions

```makefile
GREEN   = \033[0;32m    # Success messages
YELLOW  = \033[0;33m    # Information messages
CYAN    = \033[0;36m    # Info messages
RED     = \033[0;31m    # Error messages
NC      = \033[0m       # Reset color
```

#### Variables

```makefile
NAME          = inception
DOCKER_COMPOSE = docker compose -f srcs/docker-compose.yml
ENV_FILE      = srcs/.env

# Dynamically read paths from .env file
SQL_DATA_PATH = $(shell grep SQL_DATA_PATH $(ENV_FILE) | cut -d '=' -f2)
WP_DATA_PATH  = $(shell grep WP_DATA_PATH $(ENV_FILE) | cut -d '=' -f2)
DOMAIN_NAME   = $(shell grep DOMAIN_NAME $(ENV_FILE) | cut -d '=' -f2)
```

> `$(shell ...)` executes at Makefile parse time, making it dynamic and adaptable across environments.

---

#### Main Commands

**`make` / `make all` (default target):**

```makefile
all: check-env hosts logo up
```

Runs the full setup pipeline: environment check → host config → build → start.

---

**`make check-env`:**

```makefile
check-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)[ERROR] .env file not found. Please create it based on .env.example$(NC)"; \
		exit 1; \
	fi
	@sed -i "s|/home/[^/]\+/data/|/home/$(USER)/data/|g" $(ENV_FILE)
	@echo "$(GREEN)[OK] .env file verified and updated.$(NC)"
```

Checks if `.env` exists and updates the `/home/*/data/` path to match the current `$USER`.

---

**`make hosts`:**

```makefile
hosts:
	@if ! grep -q "$(DOMAIN_NAME)" /etc/hosts; then \
		echo "127.0.0.1 $(DOMAIN_NAME)" | sudo tee -a /etc/hosts > /dev/null; \
		echo "$(GREEN)[OK] Domain $(DOMAIN_NAME) added to /etc/hosts.$(NC)"; \
	else \
		echo "$(CYAN)[INFO] Domain $(DOMAIN_NAME) already in /etc/hosts.$(NC)"; \
	fi
```

Idempotent: only adds the domain if it is not already present.

---

**`make logo`:**

```makefile
logo:
	@echo " _____                     _   _             "
	@echo "|_   _|                   | | (_)            "
	@echo "  | | _ __   ___ ___ _ __ | |_ _  ___  _ __  "
	@echo "  | || '_ \\ / __/ _ \\ '_ \\| __| |/ _ \\| '_ \\ "
	@echo " _| || | | | (_|  __/ |_) | |_| | (_) | | | |"
	@echo " \\___/_| |_|\\___\\___| .__/ \\__|_|\\___/|_| |_|"
	@echo "                    | |                      "
	@echo "                    |_|                      "
```

---

**`make init`:**

```makefile
init:
	@echo "$(YELLOW)Creating required host directories...$(NC)"
	mkdir -p $(SQL_DATA_PATH) $(WP_DATA_PATH)
	@echo "$(GREEN)Directories ready:$(NC) $(SQL_DATA_PATH), $(WP_DATA_PATH)"
```

Creates volume directories on the host if they don't exist. Paths are read dynamically from `.env`.

---

**`make build`:**

```makefile
build: init
	@echo "$(YELLOW)Building Docker images...$(NC)"
	$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Build successful!$(NC)"
```

Depends on `init`. Builds all Docker images defined in `docker-compose.yml`.

---

**`make up`:**

```makefile
up: build
	@echo "$(YELLOW)Starting containers...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Containers are up and running!$(NC)"
```

Depends on `build`. Starts all containers in detached mode.

---

**`make down`:**

```makefile
down:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Containers stopped.$(NC)"
```

Stops and removes containers. Preserves volumes and data.

---

**`make clean`:**

```makefile
clean: down
	@echo "$(YELLOW)Removing containers...$(NC)"
	$(DOCKER_COMPOSE) rm -f
	@echo "$(GREEN)Containers removed.$(NC)"
```

Removes stopped containers. Still preserves volumes.

---

**`make fclean`:**

```makefile
fclean: clean
	@echo "$(YELLOW)Cleaning volumes, networks, and images...$(NC)"
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans
	sudo rm -rf $(SQL_DATA_PATH) $(WP_DATA_PATH)
	@echo "$(GREEN)Full clean done.$(NC)"
```

> ⚠️ **Destructive.** Removes containers, volumes, networks, images, and all host data directories. All data is permanently lost.

---

**`make re`:**

```makefile
re: fclean all
```

Full rebuild: wipes everything then rebuilds from scratch.

> ⚠️ **Destructive.** All data is lost.

---

**`.PHONY` Declaration:**

```makefile
.PHONY: all build up down clean fclean re logo init check-env hosts
```

Declares all targets as phony so they always execute, even if files with those names exist.

---

#### Usage Examples

**First-time setup:**

```bash
# Single command does everything
make

# Equivalent to:
# make check-env   # Verify .env
# make hosts       # Add domain to /etc/hosts
# make logo        # Display ASCII art
# make build       # Build images (calls init first)
# make up          # Start containers
```

**Daily workflow:**

```bash
# Start work
make
# Stop for the day
make down
# Next day (data preserved)
make
```

**Debugging:**
```bash
# Rebuild specific parts
make check-env     # Only verify environment
make build         # Only rebuild images
make up            # Only start containers

# View logs
docker compose -f srcs/docker-compose.yml logs -f
```

**Clean slate:**
```bash
# Complete reset
make fclean   # Delete everything
make          # Rebuild from scratch
# Or just: make re
```

---

## Building the Project

### Build Process Overview

1. Reads `docker-compose.yml`
2. Builds each Dockerfile in `requirements/`
3. Creates Docker images with appropriate tags
4. Sets up networks and volumes
5. Starts containers in dependency order

### Understanding Dockerfiles

Each service has its own Dockerfile following this pattern:

**Example — NGINX Dockerfile:**

```dockerfile
# Use Debian 11 (bullseye) as base image
FROM debian:bullseye

# Update packages, install NGINX and OpenSSL in a single layer and clean apt cache
RUN apt update \
    && apt install -y nginx openssl \
    && rm -rf /var/lib/apt/lists/*

# Remove default NGINX configuration files to avoid conflicts
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

# Create required directories
RUN mkdir -p /var/www/html /etc/nginx/ssl

# Copy custom NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy SSL setup script and make it executable
COPY tools/setup_ssl.sh /setup.sh
RUN chmod +x /setup.sh

# Set permissions on web root directory
RUN chmod -R 755 /var/www/html

# Change ownership to www-data (used by NGINX)
RUN chown -R www-data:www-data /var/www/html

# Generate SSL certificates
RUN /setup.sh

# Expose HTTPS port
EXPOSE 443

# Run NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]

```

**Key principles:**
- Base image: Debian (penultimate stable), no `:latest` tag
- Minimal package installation
- Configuration copied at build time
- `CMD` runs the process in the foreground — no `tail -f` or infinite loops

---

## Docker Compose Management

### Core Commands

```bash
# Start services in detached mode
docker-compose -f srcs/docker-compose.yml up -d

# Start with forced rebuild
docker-compose -f srcs/docker-compose.yml up -d --build

# Stop services (keeps containers)
docker-compose -f srcs/docker-compose.yml stop

# Stop and remove containers
docker-compose -f srcs/docker-compose.yml down

# Stop, remove containers and volumes
docker-compose -f srcs/docker-compose.yml down -v

# View running services
docker-compose -f srcs/docker-compose.yml ps

# View all logs
docker-compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f

# Logs for a specific service
docker-compose -f srcs/docker-compose.yml logs -f wordpress

# Restart a specific service
docker-compose -f srcs/docker-compose.yml restart nginx

# Execute a command in a container
docker-compose -f srcs/docker-compose.yml exec wordpress sh
```

### Service Start Order

Services start in this order due to `depends_on`:

1. **MariaDB** — no dependencies
2. **WordPress** — depends on MariaDB
3. **NGINX** — depends on WordPress

> **Note:** `depends_on` only waits for containers to *start*, not for services to be fully ready. Implement health checks or wait scripts for production environments.

---

## Container Management

### Inspecting Containers

```bash
# List all containers
docker ps -a
# Inspect container configuration
docker inspect nginx
# View container resource usage
docker stats
```

### Resource Management

```bash
# View Docker disk usage
docker system df
# Clean up all unused resources
docker system prune -a
# Remove stopped containers only
docker container prune
# Remove unused images
docker image prune -a
# Remove unused volumes
docker volume prune
```

---

## Volume Management

### Volume Commands

```bash
# List all volumes
docker volume ls

# Check volume contents on host
ls -la /home/$(whoami)/data/wordpress/
ls -la /home/$(whoami)/data/mariadb/

# Check volume sizes
du -sh /home/$(whoami)/data/*

# Check database tables
docker exec -it mariadb mysql -u dbajeux -pimagine -e "USE wordpress; SHOW TABLES;"

# Inspect a specific table (loads credentials from .env)
export $(grep -v '^#' .env | xargs) && docker exec -it mariadb mysql -u $SQL_USER -p$SQL_PASSWORD -e "SELECT * FROM <name_of_table>;" $SQL_DATABASE

# Remove all volumes (WARNING: deletes all data)
docker-compose -f srcs/docker-compose.yml down -v
```

---

## Network Configuration

### Port Mapping

Only NGINX exposes ports to the host. WordPress and MariaDB are only accessible internally through the Docker network.

```yaml
# nginx in docker-compose.yml
ports:
  - "443:443"  # HOST_PORT:CONTAINER_PORT
```

> The format is always `HOST:CONTAINER`.

---

### Port Summary

| Service | Default Port | Exposed to Host | Where to Change |
|---|---|---|---|
| NGINX | `443` | ✅ Yes | `docker-compose.yml` + `nginx.conf` + WordPress URLs |
| WordPress (PHP-FPM) | `9000` | ❌ No | `www.conf` + `nginx.conf` |
| MariaDB | `3306` | ❌ No | `50-server.cnf` + `setup_wordpress.sh` |

---

### Changing Ports

**NGINX — change the host-side port:**

```yaml
# docker-compose.yml
ports:
  - "8080:443"
```

Then update WordPress URLs:

```bash
docker exec -it wordpress bash
wp option update siteurl 'https://dbajeux.42.fr:8080' --allow-root
wp option update home 'https://dbajeux.42.fr:8080' --allow-root
```

Verify:

```bash
docker exec nginx ss -tlnp | grep 8080
docker exec wordpress wp option get siteurl --allow-root
docker exec wordpress wp option get home --allow-root
```

---

**WordPress (PHP-FPM) — change the internal port:**

```ini
# www.conf
listen = 0.0.0.0:9001
```

Then update NGINX:

```nginx
# nginx.conf
fastcgi_pass wordpress:9001;
```

Verify:

```bash
docker exec wordpress ss -tlnp | grep 9001
docker exec nginx curl -s telnet://wordpress:9001 || echo "port reachable"
```

---

**MariaDB — change the internal port:**

```ini
# 50-server.cnf
port = 3307
```

Then update the WordPress setup script:

```bash
# setup_wordpress.sh
wp config create --dbhost="mariadb:3307" ...
```

Verify:

```bash
docker exec mariadb ss -tlnp | grep 3307
docker exec mariadb mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" --port=3307 ping
```

---

## Service Details

### NGINX Service

**Purpose:** HTTPS web server and reverse proxy

**Key files:**
- `requirements/nginx/Dockerfile`
- `requirements/nginx/conf/nginx.conf`
- `requirements/nginx/tools/setup.sh`

**Configuration highlights:**

```nginx
server {
    listen 443 ssl;

    server_name login.42.fr;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    root /var/www/html;
    index index.php;

    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**Useful commands:**

```bash
# Test NGINX configuration
docker exec nginx nginx -t
# Reload NGINX
docker exec nginx nginx -s reload
# View access logs
docker exec nginx tail -f /var/log/nginx/access.log
# View error logs
docker exec nginx tail -f /var/log/nginx/error.log
```

---

### WordPress Service

**Purpose:** PHP-FPM application server running WordPress

**Key files:**
- `requirements/wordpress/Dockerfile`
- `requirements/wordpress/conf/www.conf`
- `requirements/wordpress/tools/setup.sh`

**Initialization tasks:**
1. Download WordPress core files
2. Configure `wp-config.php` with database credentials
3. Install WordPress via wp-cli
4. Create admin user
5. Set up permalinks

**Useful commands:**

```bash
# Check WordPress version
docker exec wordpress wp --info --allow-root
# List installed plugins
docker exec wordpress wp plugin list --allow-root
# Check database connection
docker exec wordpress wp db check --allow-root
# Update WordPress core
docker exec wordpress wp core update --allow-root
# Create a new post
docker exec wordpress wp post create --post_title="Hello" --post_content="World" --post_status=publish --allow-root
```

---

### MariaDB Service

**Purpose:** MySQL-compatible database server

**Key files:**
- `requirements/mariadb/Dockerfile`
- `requirements/mariadb/conf/my.cnf`
- `requirements/mariadb/tools/setup.sh`

**Initialization tasks:**
1. Initialize MySQL data directory
2. Set root password
3. Create WordPress database
4. Create WordPress user with privileges

**Useful commands:**

```bash
# Connect to MySQL CLI
docker exec -it mariadb mysql -u root -p
# Show all databases
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"
# Show WordPress tables
docker exec mariadb mysql -u root -p wordpress -e "SHOW TABLES;"
```

---

## Debugging

### SSL/TLS Issues

```bash
# Test TLS connectivity
openssl s_client -connect login.42.fr:443 -tls1_2
openssl s_client -connect login.42.fr:443 -tls1_3

# Inspect certificate details
docker exec nginx openssl x509 -in /etc/nginx/ssl/nginx.crt -text -noout

# Verify NGINX configuration
docker exec nginx nginx -t
```

---

## Security Considerations

### SSL/TLS Configuration

**Generate a self-signed certificate:**

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx.key -out nginx.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/CN=login.42.fr"
```

**Enforce TLS 1.2 / 1.3 in NGINX:**

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
```

### Network Security

```yaml
networks:
  inception:
    driver: bridge

ports:
  - "443:443"  # Only HTTPS exposed
```

---

## Data Storage and Persistence

### Storage Locations

**On the host machine:**

```
/home/login/data/
├── wordpress/          # WordPress installation files
│   ├── wp-content/
│   ├── wp-config.php
│   └── ...
└── mariadb/            # MariaDB database files
    ├── mariaDB/
    ├── wordpress/
    └── ...
```

**Inside containers:**

| Service | Path |
|---|---|
| WordPress | `/var/www/html/` |
| MariaDB | `/var/lib/mysql/` |
| NGINX | No persistent data (config baked into image) |

---

## Useful Commands Reference

### Project Management

```bash
make              # Build and start everything
make down         # Stop services
make fclean       # Clean everything (destructive)
make re           # Full rebuild from scratch (destructive)
```

### Docker Compose

```bash
docker-compose -f srcs/docker-compose.yml ps               # List services
docker-compose -f srcs/docker-compose.yml logs -f          # Follow all logs
docker-compose -f srcs/docker-compose.yml restart nginx    # Restart a service
docker-compose -f srcs/docker-compose.yml exec wordpress sh # Enter a container
```

### Container Management

```bash
docker ps               # List running containers
docker ps -a            # List all containers
docker logs <name>      # View container logs
docker exec -it <name> sh  # Enter a container
docker inspect <name>   # Detailed container info
```

### Volume Management

```bash
docker volume ls                       # List volumes
docker volume inspect <name>           # Volume details
du -sh /home/$(whoami)/data/*          # Check data size on host
```

### Network Management

```bash
docker network ls                              # List networks
docker network inspect inception_inception     # Network details
```

### System Cleanup

```bash
docker system df           # Show disk usage
docker system prune -a     # Remove all unused resources
```

---

**Document Version:** 1.0  
**Last Updated:** February 2026  
**Project:** 42 Inception — Developer Reference
