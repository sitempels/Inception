# User Documentation

*This document explains how to use and manage the Inception infrastructure as an end user or administrator.*

---

## Table of Contents

- [What is Inception?](#what-is-inception)
- [Services Provided](#services-provided)
- [Getting Started](#getting-started)
- [Starting and Stopping the Project](#starting-and-stopping-the-project)
- [Accessing the Services](#accessing-the-services)
- [Managing Credentials](#managing-credentials)
- [Checking Service Health](#checking-service-health)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## What is Inception?

Inception is a web infrastructure that provides a WordPress website with a secure database, served through an HTTPS web server. Everything runs in isolated Docker containers for security and easy management.

**In simple terms:** It's a complete website hosting setup that you can start, stop, and manage with simple commands.

---

## Services Provided

The infrastructure provides three main services:

### 1. **WordPress Website**
- A fully functional WordPress site where you can create posts, pages, and manage content
- Accessible via a web browser at `https://login.42.fr`
- Includes an admin panel for site management

### 2. **NGINX Web Server**
- Handles all incoming web requests securely (HTTPS only)
- Acts as the entry point to your website
- Provides SSL/TLS encryption for secure connections

### 3. **MariaDB Database**
- Stores all WordPress data (posts, pages, users, settings)
- Runs in the background (not directly accessible from outside)
- Data is stored persistently and survives restarts

All services work together automatically and restart if they crash.

---

## Getting Started

### Prerequisites

Before using the infrastructure, ensure:
- You are on the virtual machine where Inception is installed
- Docker is running
- Your domain name is configured (see README.md installation section)

### First Time Setup

If this is your first time using Inception:

1. Verify Docker is running:
```bash
docker ps
```

2. Confirm the domain is configured:
```bash
cat /etc/hosts | grep 42.fr
# Should show: 127.0.0.1 login.42.fr
```

3. Check that data directories exist:
```bash
ls -la /home/$(whoami)/data/
# Should show: wordpress/ and mariadb/ directories
```

---

## Starting and Stopping the Project

### Starting the Infrastructure

To start all services:

```bash
make
```

This single command will automatically:
1. ✅ Verify your `.env` file exists and update user paths
2. ✅ Add your domain to `/etc/hosts` (if not already there)
3. ✅ Display the Inception logo
4. ✅ Create required volume directories
5. ✅ Build all Docker images
6. ✅ Start all containers

**Wait time:** The first start may take 2-5 minutes to download packages and build everything.

**What you'll see:**
- Green messages for successful steps
- Yellow messages for informational output
- ASCII art logo for Inception
- "Containers are up and running!" when complete

**Verification:** Check that all three containers are running:
```bash
docker ps
# Look for: nginx, wordpress, mariadb containers with status "Up"
```

### Stopping the Infrastructure

To stop all services (but keep your data):

```bash
make down
```

This command will:
- Stop all running containers
- Remove containers
- **Keep all your data safe** in volumes

**Note:** Your WordPress site and database are preserved and will be available when you start again.

### Restarting After Stopping

If you stopped with `make down`, simply restart with:

```bash
make up
```

Your data is still there - WordPress will continue where you left off.

### Complete Reset (Dangerous!)

To delete everything and start fresh:

```bash
make fclean
```

**⚠️  WARNING:** This will:
- Stop and remove all containers
- Delete all Docker images
- Delete all Docker volumes
- **Delete ALL your WordPress content and database permanently!**

Only use this if you want to completely start over.

### Rebuild Without Data Loss

If you need to rebuild containers but keep your data:

```bash
make down          # Stop containers
make build         # Rebuild images
make up            # Start containers again
```

This preserves your data while rebuilding the infrastructure.

---

## Accessing the Services

### Accessing the WordPress Website

1. **Open your web browser**
2. **Navigate to:** `https://login.42.fr` (replace `login` with your actual login)
3. **Accept the certificate warning:**
   - Click "Advanced" or "Show details"
   - Click "Accept risk and continue" or "Proceed to site"
   - This is normal because we use a self-signed certificate

4. **You should see your WordPress site!**

### Accessing the WordPress Admin Panel

To manage your WordPress site (create posts, change themes, install plugins):

1. **Go to:** `https://login.42.fr/wp-admin`
2. **Log in with your credentials** (see [Managing Credentials](#managing-credentials))
3. **You're now in the WordPress dashboard** where you can:
   - Write posts and pages
   - Change site appearance
   - Manage users
   - Configure settings

### What You Can Do in WordPress

As an administrator, you can:
- Create and edit blog posts
- Create pages (About, Contact, etc.)
- Change themes and customize appearance
- Install and configure plugins
- Manage users and permissions
- Configure site settings (title, tagline, etc.)
- View site statistics

---

## Managing Credentials

### Where Credentials are Stored

All passwords and sensitive information are stored in two places:

1. **`.env` file:** Located at `srcs/.env`
   - Contains database/user credentials, WordPress admin info, domain name 
   - **Never share this file or commit it to Git!**



### Viewing Your Credentials

To view your login credentials:

```bash
cat srcs/.env
```

You'll see something like:
```
DOMAIN_NAME=login.42.fr
SQL_DATABASE=example_db
SQL_USER=example_user
SQL_PASSWORD=example_password
SQL_ROOT_PASSWORD=example_root_password
WP_ADMIN_USER=example_admin
WP_ADMIN_PASSWORD=example_admin_password
WP_ADMIN_EMAIL=[admin@example.org](mailto:admin@example.org)
WP_USER=example_username
WP_USER_PASSWORD=example_user_password
WP_USER_EMAIL=[user@example.xyz](mailto:user@example.xyz)
SQL_DATA_PATH=/home/login/data/mysql
WP_DATA_PATH=/home/login/data/wordpress
```

### Important Credential Rules

1. **Never use these usernames for WordPress admin:**
   - admin
   - administrator
   - Admin
   - Administrator
   - admin-123
   - (Any variation containing "admin" or "administrator")

2. **Keep credentials secure:**
   - Don't share your `.env` file
   - Don't commit credentials to Git
   - Use strong passwords
   - Change default passwords

### Changing Credentials

To change your credentials:

1. **Stop the infrastructure:**
```bash
make down
```

2. **Edit the `.env` file:**
```bash
vim srcs/.env
# Modify the passwords/usernames as needed
```

3. **Rebuild and restart:**
```bash
make re
```

**Warning:** Changing database credentials requires rebuilding everything, which will erase existing data!

---

## Checking Service Health

### Quick Health Check

To see if all services are running:

```bash
docker ps
```

**What you should see:**
- Three containers: `nginx`, `wordpress`, `mariadb`
- Status column should show "Up" with uptime
- No containers should show "Restarting" or "Exited"

**Example of healthy output:**
```
CONTAINER ID   IMAGE              STATUS          PORTS                  NAMES
abc123def456   inception_nginx    Up 5 minutes    0.0.0.0:443->443/tcp   nginx
def456ghi789   inception_wordpress Up 5 minutes                          wordpress
ghi789jkl012   inception_mariadb  Up 5 minutes    3306/tcp               mariadb
```

### Detailed Service Check

To check if a specific service has errors:

```bash
# Check NGINX logs
docker logs nginx

# Check WordPress logs
docker logs wordpress

# Check MariaDB logs
docker logs mariadb
```

Look for:
- ✅ **Good signs:** "ready for connections", "started successfully", "listening on port"
- ❌ **Bad signs:** "error", "failed", "connection refused", "timeout"

### Testing Website Connectivity

To verify the website is accessible:

```bash
# Test HTTPS connection
curl -k https://login.42.fr

# Should return HTML content, not an error
```

Or simply open `https://login.42.fr` in your browser.

### Checking Data Persistence

To verify your data is being saved:

```bash
# Check volume sizes
du -sh /home/$(whoami)/data/*

# Check that WordPress files exist
ls -la /home/$(whoami)/data/wordpress/

# Check that database files exist
ls -la /home/$(whoami)/data/mariadb/
```

---

## Common Tasks

### Viewing Logs in Real-Time

To watch logs as they happen:

```bash
# All services
docker-compose -f srcs/docker-compose.yml logs -f

# Specific service
docker-compose -f srcs/docker-compose.yml logs -f wordpress
```

Press `Ctrl+C` to stop viewing logs.

### Checking Disk Space

To see how much space the infrastructure is using:

```bash
# Check volume sizes
du -sh /home/$(whoami)/data/*

# Check Docker disk usage
docker system df
```

---

## Troubleshooting

### Problem: Cannot access the website

**Symptoms:** Browser shows "This site can't be reached" or "Connection refused"

**Solutions:**
1. Check if containers are running: `docker ps`
2. Check if the domain is configured: `cat /etc/hosts | grep 42.fr`
3. Check NGINX logs: `docker logs nginx`
4. Verify port 443 is not used by another service: `sudo lsof -i :443`

### Problem: SSL Certificate Warning

**Symptoms:** Browser shows "Your connection is not private" or similar

**This is normal!** The project uses a self-signed certificate.

**Solution:** Click "Advanced" → "Proceed to site" or "Accept risk"

### Problem: WordPress shows "Error establishing database connection"

**Symptoms:** WordPress site displays a database connection error

**Solutions:**
1. Check if MariaDB is running: `docker ps | grep mariadb`
2. Check MariaDB logs: `docker logs mariadb`
3. Verify credentials in `.env` file match what WordPress expects
4. Restart everything: `make down && make`

### Problem: Containers keep restarting

**Symptoms:** `docker ps` shows containers constantly restarting

**Solutions:**
1. Check logs for errors: `docker logs <container_name>`
2. Verify configuration files have no syntax errors
3. Check that required volumes exist: `ls /home/$(whoami)/data/`
4. Rebuild from scratch: `make fclean && make`

### Problem: "Port already in use"

**Symptoms:** Error message about port 443 being in use

**Solutions:**
```bash
# Find what's using port 443
sudo lsof -i :443

# If it's another service (like Apache or NGINX)
sudo systemctl stop nginx
sudo systemctl stop apache2

# Then try starting again
make
```

### Problem: Permission denied on volumes

**Symptoms:** Errors about not being able to write to `/home/login/data/`

**Solutions:**
```bash
# Fix ownership
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/data/

# Fix permissions
sudo chmod -R 755 /home/$(whoami)/data/
```

---

## FAQ

### Q: How do I know if everything is working?

**A:** Run `docker ps` and verify all three containers show "Up" status. Then visit `https://login.42.fr` in your browser and you should see your WordPress site.

### Q: Can I use HTTP instead of HTTPS?

**A:** No. The project only supports HTTPS on port 443. HTTP on port 80 is not available by design for security reasons.

### Q: How do I reset everything and start fresh?

**A:** Run `make fclean` to remove all containers, images, and data. Then run `make` to rebuild from scratch. **Warning: This deletes all your data!**

### Q: Where is my WordPress data stored?

**A:** Your data is stored in two locations:
- WordPress files: `/home/login/data/wordpress/`
- Database: `/home/login/data/mariadb/`

### Q: Can I access the database directly?

**A:** The database is not exposed externally for security. To interact with it, you can enter the MariaDB container:
```bash
docker exec -it mariadb mysql -u root -p
```

### Q: What happens if I reboot the VM?

**A:** Docker containers will not start automatically on reboot. You need to run `make` again after reboot. Your data in volumes will be preserved.

### Q: Can I install WordPress plugins?

**A:** Yes! Log in to the WordPress admin panel (`https://login.42.fr/wp-admin`) and you can install and manage plugins like any normal WordPress installation.

### Q: How do I update WordPress?

**A:** WordPress updates can be done through the admin panel. However, for security, it's recommended to test updates in a backup copy first.

### Q: Is this setup production-ready?

**A:** This is an educational project. For production use, you would need:
- A real SSL certificate (not self-signed)
- A proper domain name (not .42.fr)
- Additional security hardening
- Backup and monitoring solutions
- Regular security updates

---



**Document Version:** 1.0  
**Last Updated:** February 2026  
**For:** 42 Inception Project