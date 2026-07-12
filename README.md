*This project has been created as part of the 42 curriculum by stempels*

# Inception

Inception is *42 School* project.
It aims to broaden our knowledge of system administration by using Docker in a Virtual Machine.

---

## Table of Contents

- [Description](#description)
- [Infrastructure](#infrastructure)
- [Instructions](#instructions)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Technical Comparisons](#technical-comparisons)
  - [Virtual Machines vs Docker](#virtual-machines-vs-docker)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
  - [Docker Network vs Host Network](#docker-network-vs-host-network)
  - [Docker Volumes vs Bind Mount](#docker-volumes-vs-bind-mount)
- [Project Structure](#project-structure)
- [Resources](#resources)

**Additional Documentation:**
- [User Documentation](USER_DOC.md) - Guide for end users and administrators
- [Developer Documentation](DEV_DOC.md) - Technical reference for developers

---

## Description

Running in a ***Debian Virtual Machine***, we will create and manage several Docker containers.

## Infrastructure

The infrastructure consists of:
- **NGINX** container serving as the only entrypoint via port 443 (HTTPS) or port 80 (redirect to 443)
- **WordPress + php83-fpm** container (without NGINX)
- **MariaDB** database container (without NGINX)
- **Two Docker named volumes** for persistent storage:
  - WordPress database data
  - WordPress website files
- **Docker network** connecting all containers
- **Domain name** configuration (login.42.fr pointing to local IP)

All these services run in dedicated containers and follow Docker best practices.
/add link to dev doc

## Instructions

### Prerequisites

**Virtual Machine**(VM) running a Linux distribution

The VM needs the following programs installed:
- Docker
- Docker Compose
- Make
- Sudo
- Git
- Bash
- Openssl

Any ports used in the VM to communicate with the world need to be open in your hypervisor.

**Virtual Machine User**

The user need:
- Account and password
- root/sudo access rights

### Installation

1. **Clone the repository:**
```bash
git clone <repository_url> inception
cd inception
```

2. **Environment variables setup:**

- **template_env exists:**

```bash
make
```

Vim will open. Set all variables in .env

- **template_env do not exist:**

	In inception repository:

```bash
cat << 'EOF' > .env
# Is a comment and will be ignored
# Secrets SHOULD be prefixed with S_

# VM Config
NEW_HOSTNAME=

# MYSQL SECRETS
S_MARIADB_DATABASE=
S_MYSQL_ROOT_PASSWORD=
S_MYSQL_USER=
S_MYSQL_USER_PASSWORD=

# WORDPRESS SECRETS
S_WP_ADMIN_USER=
S_WP_ADMIN_PASSWORD=
S_WP_ADMIN_EMAIL=
S_WP_USER=
S_WP_USER_PASSWORD=
S_WP_USER_EMAIL=
EOF
```

then 	

```bash
make
```

## Technical Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Complete OS-level isolation | Process-level isolation |
| **Size** | GBs (entire OS) | MBs (application + dependencies) |
| **Startup Time** | Minutes | Seconds |
| **Performance** | Overhead due to hypervisor | Near-native performance |
| **Resource Usage** | Heavy (separate OS per VM) | Lightweight (shared kernel) |
| **Portability** | Less portable | Highly portable (need kernel match) |

**For this project**: Docker is the better choice because we need lightweight, portable, and quickly deployable services. VMs would be overkill for running simple web services.
We deploy everything in a VM because we need sudo rigths.

### Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|----------------|----------------------|
| **Security** | Encrypted at rest and in transit | Visible in `docker inspect`, process list, logs |
| **Usage** | Production, highly sensitive data | Development, configuration, semi-sensitive data |
| **Storage** | Encrypted in Docker  | Plain text in `.env` files |
| **Access Control** | Fine-grained permissions | Anyone with container/file access |
| **Git Safety** | Not committed (mounted at runtime) | Must be in `.gitignore` |
| **Docker Compose** | Native support | Native support |
| **Best For** | Passwords, API keys, certificates | URLs, ports, usernames, domains |

**For this project**: 
- **Environment variables** are used via `.env` file (as per requirements)
- The `.env` file **must** be in `.gitignore` to prevent credential leaks
- **Docker secrets** are used for extra security 

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
- DNS included: Services can reference each other by container name
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
- **Volumes location**: Need to be in /home/login/data, as per the subject requirements

## Project Structure

```
inception/
├── Makefile                        # Build automation
├── README.md                       # Project overview
├── USER_DOC.md                     # User documentation
├── DEV_DOC.md                      # Developer documentation
├── template_env                    # Template for the .env file
├── .env                            # Environment variables (not committed)
├── tools/                          # Utility scripts
│   ├── cert_creation.sh
│   ├── cert_rootCA.sh
│   ├── check_env.sh
│   ├── create_secret.sh
│   └── create_env.sh
└── srcs/
    ├── docker-compose.yml          # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── entrypoint.sh       # MariaDB entrypoint script
        ├── nginx/
        │   ├── Dockerfile
        │   ├── nginx.conf          # NGINX configuration
        │   └── entrypoint.sh       # NGINX entrypoint script
        └── wordpress/
            ├── Dockerfile
            └── entrypoint.sh       # WordPress entrypoint script
```

## Resources

### Documentation
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
- [Stephane Robert](https://blog.stephane-robert.info/docs/conteneurs/moteurs-conteneurs/docker/) - Tutoriel Docker : le guide pour apprendre de A à Z

### 42 Resources
- [42 Inception Subject PDF](https://cdn.intra.42.fr/pdf/pdf/xxxxx/en.subject.pdf) - Project requirements

## AI Usage

AI tools (ChatGPT) were used to assist with:
- proofreading documentation.
- identifying typos.
- debugging shell scripts.
- Writing documentation.

All code and documentation were reviewed and validated before inclusion.

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
