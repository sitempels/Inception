#! /bin/sh
set -e
SCRIPT_NAME="${0##*/}"
MAX_RETRIES=5

MARIADB_DATABASE=$(cat /run/secrets/mariadb_database)
MYSQL_USER=$(cat /run/secrets/mysql_user)
MYSQL_USER_PASSWORD=$(cat /run/secrets/mysql_user_password)
WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_email)
WP_USER=$(cat /run/secrets/wp_user)
WP_USER_EMAIL=$(cat /run/secrets/wp_user_email)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

echo "[$SCRIPT_NAME][INFO] Checking MariaDB connection"
COUNT=0;
while ! mariadb-admin ping -h"mariadb" -u"$MYSQL_USER" -p "$MYSQL_USER_PASSWORD" --port=3306 --silent; do
  COUNT=$((COUNT + 1))
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "[$SCRIPT_NAME][ERROR] No response of MariaDB after $MAX_RETRIES seconds. Stopping"
    exit 1
  fi
  sleep 1
done

if [ ! -f /var/www/$DOMAIN_NAME/wp-settings.php ]; then
  echo "[$SCRIPT_NAME][INFO] Installing wordpress"
  mkdir -p /var/www/$DOMAIN_NAME
  wp core download --path=/var/www/$DOMAIN_NAME --allow-root
  echo "[$SCRIPT_NAME][INFO] Creating config"
  wp config create \
    --dbname=$MARIADB_DATABASE \
    --dbuser=$MYSQL_USER \
    --dbpass=$MYSQL_USER_PASSWORD \
    --dbhost=mariadb \
    --path=/var/www/$DOMAIN_NAME \
    --allow-root
  echo "[$SCRIPT_NAME][INFO] Installing core"
  wp core install \
    --url=$DOMAIN_NAME \
    --title="Inception" \
    --admin_user=$WP_ADMIN_USER \
    --admin_password=$WP_ADMIN_PASSWORD \
    --admin_email=$WP_ADMIN_EMAIL \
    --path=/var/www/$DOMAIN_NAME \
    --allow-root
  echo "[$SCRIPT_NAME][INFO] Creating User"
  wp user create $WP_USER $WP_USER_EMAIL \
    --user_pass=$WP_USER_PASSWORD \
    --role=author \
    --path=/var/www/$DOMAIN_NAME \
    --allow-root
fi
chown -R nobody:nobody /var/www/$DOMAIN_NAME
chmod -R 755 /var/www/$DOMAIN_NAME
chmod 600 /var/www/$DOMAIN_NAME/wp-config.php
exec php-fpm83 -F
