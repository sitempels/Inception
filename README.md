*This project has been created as part of the 42 curriculum by [Your Name], [Collaborator 1], [Collaborator 2]*

# Inception

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)


A system administration project focused on containerization using Docker and Docker Compose.

---

## Table of Contents

- [Description](#description)
- [Instructions](#instructions)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Compilation and Execution](#compilation-and-execution)
  - [Accessing the Application](#accessing-the-application)
- [Project Architecture](#project-architecture)
- [Technical Comparisons](#technical-comparisons)
- [Project Structure](#project-structure)
- [Resources](#resources)
- [Troubleshooting](#troubleshooting)

**Additional Documentation:**
- 📖 [User Documentation](USER_DOC.md) - Guide for end users and administrators
- 🔧 [Developer Documentation](DEV_DOC.md) - Technical reference for developers

---

## Description

Inception is a system administration project that sets up a small infrastructure composed of different services using Docker containers. The entire infrastructure runs inside a virtual machine and uses Docker Compose for orchestration.

### Project Goals

The main objectives are to:
- Set up a multi-service infrastructure with **NGINX**, **WordPress + php-fpm**, and **MariaDB**
- Build custom Docker images from scratch (no pulling from DockerHub except base OS images)
- Implement secure HTTPS communication with **TLSv1.2/TLSv1.3 only**
- Use Docker named volumes for persistent data storage
- Configure proper container networking and service communication
- Apply security best practices (environment variables, no hardcoded credentials)

### Infrastructure Overview

The infrastructure consists of:
- **NGINX** container serving as the only entry point via port 443 (HTTPS)
- **WordPress + php-fpm** container (without NGINX)
- **MariaDB** database container (without NGINX)
- **Two Docker named volumes** for persistent storage:
  - WordPress database data
  - WordPress website files
- **Docker network** connecting all containers
- **Domain name** configuration (login.42.fr pointing to local IP)

All services run in dedicated containers, restart automatically on crash, and follow Docker best practices (no infinite loops, proper PID 1 handling, daemon processes).

## Instructions

### Prerequisites

- **Virtual Machine** running Linux (Ubuntu/Debian recommended)
- **Docker** 
- **Docker Compose** 
- **Make** (for using Makefile commands)
- Root/sudo access for volume creation in `/home/login/data`
- Basic understanding of Docker, networking, and web services

### Installation

1. **Clone the repository:**
```bash
git clone <repository-url>
cd inception
```

2. **Set up environment variables:**
```bash
# Copy the example environment file
touch srcs/.env

# Edit the .env file with your credentials
vim srcs/.env
```

**Important:** Never commit your `.env` file or any files containing credentials to Git!

Your `.env` file should contain:
```bash
DOMAIN_NAME=login.42.fr
SQL_DATABASE=example_db
SQL_USER=example_user
SQL_PASSWORD=example_password
SQL_ROOT_PASSWORD=example_root_password

# 👑 WordPress administrator account (full access to the admin interface)
WP_ADMIN_USER=example_admin
WP_ADMIN_PASSWORD=example_admin_password

# email address is required but not critical since the site runs locally
WP_ADMIN_EMAIL=[admin@example.org](mailto:admin@example.org)

# 👤 Secondary WordPress user (limited permissions, role = author)
WP_USER=example_username
WP_USER_PASSWORD=example_user_password

# this email must be different from the admin one
WP_USER_EMAIL=[user@example.xyz](mailto:user@example.xyz)

# 📂 Volumes - Local paths used to store MariaDB and WordPress data
SQL_DATA_PATH=/home/login/data/mysql
WP_DATA_PATH=/home/login/data/wordpress


```

3. **That's it!** The Makefile will automatically:
   - ✅ Verify and update your `.env` file with the correct user paths
   - ✅ Add your domain to `/etc/hosts` 
   - ✅ Create the required volume directories
   - ✅ Build and start all containers

Just run `make` and everything is handled for you!


### Compilation and Execution

### Makefile Automation

The project includes an intelligent Makefile that automates setup and management:

**Automatic Tasks:**
- ✅ **Environment validation** (`check-env`): Verifies `.env` exists and updates user paths automatically
- ✅ **Domain configuration** (`hosts`): Adds domain to `/etc/hosts` if not already present
- ✅ **Directory creation** (`init`): Creates required volume directories on host
- ✅ **Visual feedback**: Color-coded output and ASCII logo for better UX

**Start the entire infrastructure (recommended):**
```bash
make
# This runs: check-env → hosts → logo → build → up
# Automatically handles environment verification, domain setup, and container startup
```

**Individual commands:**

```bash
# Verify .env file and update paths
make check-env

# Add domain to /etc/hosts
make hosts

# Create volume directories
make init

# Build Docker images only
make build

# Start containers only (requires build first)
make up

# Stop containers (keeps data)
make down

# Stop and remove containers
make clean

# Full cleanup (removes containers, images, volumes, and data)
make fclean
# ⚠️  WARNING: This will delete ALL your WordPress data and database!

# Rebuild everything from scratch
make re
# ⚠️  WARNING: This performs fclean then rebuilds - all data is lost!
```
This automation means you can run `make` on any machine and the infrastructure will be configured correctly automatically!
**View logs:**
```bash
# Using docker compose directly
docker compose -f srcs/docker-compose.yml logs -f

# For specific service
docker compose -f srcs/docker-compose.yml logs -f nginx
```

**Quick reference:**
- `make` → Complete setup and start (use this for first time)
- `make down` → Stop (keeps data)
- `make up` → Start again (preserves data)
- `make re` → Fresh start (deletes all data)

### Accessing the Application

Once the containers are running:

**WordPress Website:**
- URL: `https://login.42.fr` (replace 'login' with your actual login)
- Accept the self-signed certificate warning in your browser

**WordPress Admin Panel:**
- URL: `https://login.42.fr/wp-admin`
- Use the credentials from your `.env` file

**Note:** The infrastructure uses HTTPS only with TLSv1.2/TLSv1.3. HTTP connections on port 80 are not available.

**Verify services are running:**
```bash
docker ps
# All three containers (nginx, wordpress, mariadb) should be "Up"
```

For detailed usage instructions, see [USER_DOC.md](USER_DOC.md).  
For development and technical details, see [DEV_DOC.md](DEV_DOC.md).

## Project Architecture

### Docker Usage

This project uses **Docker** as the containerization platform and **Docker Compose** for service orchestration. Each service runs in a dedicated container built from custom Dockerfiles.

**Three mandatory containers:**

1. **NGINX Container**
   - Web server with TLSv1.2 or TLSv1.3 only
   - Only entry point to the infrastructure (port 443)
   - Acts as reverse proxy to WordPress

2. **WordPress + php-fpm Container**
   - WordPress installation with PHP-FPM
   - No NGINX inside this container
   - Connects to MariaDB for database operations

3. **MariaDB Container**
   - Database server
   - No NGINX inside this container
   - Stores WordPress data persistently

#### Why Docker?

Docker provides several advantages for this infrastructure:
1. **Isolation**: Each service runs independently with its own environment
2. **Reproducibility**: The exact same setup works across different machines
3. **Resource Efficiency**: Lighter than VMs, containers share the host kernel
4. **Service Separation**: Clear boundaries between web server, application, and database
5. **Easy Management**: Simple commands to control the entire stack

### Design Choices

#### Base Images

All containers use either:
- **Debian** (penultimate stable version): More packages available, slightly larger

**Rationale:** 
- Small image size reduces attack surface
- Faster builds and deployments
- Both are stable and well-maintained
- Complies with project requirements (no :latest tag)

#### Custom Dockerfiles

All Docker images are built from scratch using custom Dockerfiles:
- **Full control** over what's installed and how
- **Security**: Only necessary packages are included
- **Learning**: Deep understanding of each service's requirements
- **Compliance**: Project forbids pulling ready-made images from DockerHub

#### No Hacky Patches

The project follows Docker best practices:
- ❌ No `tail -f`, `sleep infinity`, `while true` loops
- ❌ No commands that don't properly handle PID 1
- ✅ Services run as foreground processes
- ✅ Proper daemon configuration
- ✅ Containers restart automatically on crash

#### Volume Strategy

**Two Docker named volumes** (mandatory):
- `wordpress`: Stores WordPress website files
- `mariadb`: Stores MariaDB database

Both volumes map to `/home/login/data/` on the host machine:
- `/home/login/data/wordpress` ↔ WordPress files
- `/home/login/data/mariadb` ↔ Database files

**Why named volumes over bind mounts?**
- Better managed by Docker
- Platform-independent paths
- Better performance on non-Linux systems
- Easier backup and migration
- Required by project specifications

#### Network Configuration

A custom **Docker bridge network** connects all containers:
- NGINX ↔ WordPress communication
- WordPress ↔ MariaDB communication
- Internal DNS resolution (containers reach each other by name)
- No `network: host`, `--link`, or `links:` (forbidden by project)

#### Security Measures

1. **No passwords in Dockerfiles**: All credentials via environment variables
2. **Environment variables**: Stored in `.env` file (not committed to Git)
3. **Docker secrets**: Optional but recommended for sensitive data
4. **TLS encryption**: HTTPS only (TLSv1.2/TLSv1.3)
5. **Port exposure**: Only port 443 exposed externally
6. **User restrictions**: WordPress admin usernames cannot contain "admin" or "administrator"



## Technical Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Complete OS-level isolation | Process-level isolation |
| **Size** | GBs (entire OS) | MBs (application + dependencies) |
| **Startup Time** | Minutes | Seconds |
| **Performance** | Overhead due to hypervisor | Near-native performance |
| **Resource Usage** | Heavy (separate OS per VM) | Lightweight (shared kernel) |
| **Portability** | Less portable | Highly portable |

**For this project**: Docker is the better choice because we need lightweight, portable, and quickly deployable services. VMs would be overkill for running simple web services.

### Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|----------------|----------------------|
| **Security** | Encrypted at rest and in transit | Visible in `docker inspect`, process list, logs |
| **Usage** | Production, highly sensitive data | Development, configuration, semi-sensitive data |
| **Storage** | Encrypted in Docker  | Plain text in `.env` files |
| **Access Control** | Fine-grained permissions | Anyone with container/file access |
| **Git Safety** | Not committed (mounted at runtime) | Must be in `.gitignore` |
| **Docker Compose** | Requires Swarm mode | Native support |
| **Best For** | Passwords, API keys, certificates | URLs, ports, usernames, domains |

**For this project**: 
- **Environment variables** are used via `.env` file (as per requirements)
- The `.env` file **must** be in `.gitignore` to prevent credential leaks
- **Docker secrets** can optionally be used for extra security 
- **Critical**: Any credentials in Git = automatic project failure

**Best practice approach:**
```bash
# In .env (non-sensitive config)
DOMAIN_NAME=login.42.fr
MYSQL_USER=wpuser

# In secrets/ (sensitive data)
secrets/db_root_password.txt
secrets/db_password.txt
secrets/credentials.txt
```

### Docker Network vs Host Network

| Aspect | Docker Network (Bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Containers have own network stack | Shares host's network stack |
| **Port Conflicts** | No conflicts between containers | Direct conflict with host ports |
| **Security** | Better isolation | Direct exposure to host |
| **Performance** | Slight overhead (NAT) | No overhead |
| **Portability** | Works anywhere | Depends on host config |

**For this project**: Docker bridge network is used because:
- Better security through isolation
- No port conflicts
- Services can reference each other by container name
- Follows best practices for microservices

### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Managed by Docker | Direct filesystem path |
| **Location** | Docker area (/var/lib/docker/volumes) | Anywhere on host |
| **Portability** | More portable | Path-dependent |
| **Performance** | Optimized by Docker | Direct filesystem access |
| **Backup** | Docker commands | Standard filesystem tools |
| **Use Case** | Persistent data, production | Development, config files |

**For this project**: Docker Volumes is used:
- **Docker Volumes**: For database data (WordPress files, MariaDB data) - ensures data persistence and portability

## Project Structure

```
inception/
├── Makefile                          # Build automation
├── README.md                         # Project overview (this file)
├── USER_DOC.md                       # User documentation
├── DEV_DOC.md                        # Developer documentation   
└── srcs/
    ├── docker-compose.yml            # Service orchestration
    ├── .env                          # Environment variables (NOT in Git)
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/                 # MariaDB configuration files
        │   └── tools/                # Initialization scripts
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/                 # NGINX config (SSL, server blocks)
        │   └── tools/                # Setup scripts
        ├── wordpress/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/                 # PHP-FPM and WP configuration
            └── tools/                # WP installation scripts

```

### Important Notes

**Files to NEVER commit:**
- `srcs/.env` - Contains environment variables and credentials
- Any file with credentials, API keys, or passwords

**Add to `.gitignore`:**
```gitignore
srcs/.env
*.log
.DS_Store
```

**Volume mount points on host:**
```
/home/login/data/
├── wordpress/    # WordPress website files
└── mariadb/      # MariaDB database files
```

Replace `login` with your actual 42 login username.

## Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/) - Complete Docker reference
- [Docker Compose Documentation](https://docs.docker.com/compose/) - Multi-container applications
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/) - Guidelines for production
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/) - Dockerfile instructions
- [NGINX Documentation](https://nginx.org/en/docs/) - Web server configuration
- [NGINX SSL/TLS Setup](https://nginx.org/en/docs/http/configuring_https_servers.html) - HTTPS configuration
- [WordPress Documentation](https://wordpress.org/documentation/) - WordPress setup and usage
- [WordPress CLI](https://wp-cli.org/) - Command-line interface for WordPress
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/) - Database server
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php) - FastCGI Process Manager

### Tutorials and Articles
- [Docker Getting Started Guide](https://docs.docker.com/get-started/) - Introduction to Docker
- [Docker Networking Deep Dive](https://docs.docker.com/network/) - Network configuration
- [Docker Volumes Tutorial](https://docs.docker.com/storage/volumes/) - Persistent storage
- [Understanding PID 1 in Docker](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/) - Process management
- [TLS 1.2 vs TLS 1.3](https://www.cloudflare.com/learning/ssl/why-use-tls-1.3/) - Security protocols
- [Setting up LEMP Stack with Docker](https://www.digitalocean.com/community/tutorials) - Linux, NGINX, MySQL, PHP

### 42 Resources
- [42 Inception Subject PDF](https://cdn.intra.42.fr/pdf/pdf/xxxxx/en.subject.pdf) - Official project requirements


### AI Usage

AI assistance (Claude/ChatGPT) was used for the following tasks during this project:

**Learning and Research:**
- Understanding Docker networking concepts (bridge networks, container communication)
- Researching TLS 1.2/1.3 configuration best practices for NGINX
- Learning about Docker volume management vs bind mounts
- Understanding PID 1 and daemon processes in containers
- Comparing Alpine Linux vs Debian for base images

**Configuration Assistance:**
- Syntax validation for `docker-compose.yml` structure
- NGINX configuration examples for reverse proxy with SSL
- MariaDB initialization script patterns
- WordPress configuration for Docker environments
- Environment variable best practices

**Documentation:**
- Writing clear installation and usage instructions
- Creating USER_DOC.md and DEV_DOC.md templates

**Code Review:**
- Dockerfile optimization suggestions (layer caching, multi-stage builds)
- Security best practices validation (no hardcoded passwords, proper secrets)
- Docker Compose syntax verification
- Shell script improvements for idempotency

**What AI did NOT do:**
- Write the core Dockerfiles (manually written based on requirements)
- Create the actual service configuration files (nginx.conf, my.cnf, wp-config.php)
- Design the Docker Compose orchestration architecture
- Make technical decisions about service separation and networking
- Set up the actual infrastructure or test the deployment
- Write initialization and setup scripts for services

**Approach:** AI was used as a learning assistant and documentation tool. All critical implementation decisions, code, and configurations were created, understood, and tested by me. AI helped clarify concepts and provide examples, but the actual implementation is original work.

### Learning Path Recommendation

For those new to this project:
1. **Start with Docker basics** - Understand containers, images, and Dockerfiles
2. **Learn Docker Compose** - Multi-container orchestration
3. **Study each service** - NGINX, WordPress, MariaDB independently
4. **Understand networking** - How containers communicate
5. **Practice security** - Environment variables, secrets, TLS
6. **Read the subject carefully** - Follow all requirements exactly

## Troubleshooting

### Common Issues

**Ports already in use**:
```bash
# Check what's using port 443
sudo lsof -i :443
# Stop conflicting services
sudo systemctl stop nginx
```

**Permission denied on volumes**:
```bash
# Fix volume permissions
sudo chown -R $USER:$USER srcs/
```

**Containers won't start**:
```bash
# Check logs
docker-compose -f srcs/docker-compose.yml logs
# Rebuild without cache
docker-compose -f srcs/docker-compose.yml build --no-cache
```

---

## Getting Help

If you encounter issues:

1. **Check this README** for setup and architecture information
2. **Read [USER_DOC.md](USER_DOC.md)** for usage and troubleshooting
3. **Consult [DEV_DOC.md](DEV_DOC.md)** for technical details and debugging
4. **Review container logs:** `docker-compose -f srcs/docker-compose.yml logs`
5. **Search official documentation** listed in the Resources section



## Authors

**Project created by:** Dylan Bajeux
**42 Login:** dbajeux  


## License

This project is part of the 42 school curriculum.  
For educational purposes only.

---

**Last Updated:** February 2026  
**Project:** Inception  
**School:** 42