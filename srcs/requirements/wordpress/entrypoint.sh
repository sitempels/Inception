#! /bin/sh
set -e
SCRIPT_NAME="${0##*/}"
MAX_RETRIES=5

echo "[$SCRIPT_NAME][INFO] Checking MariaDB connection"
COUNT=0;
while ! mariadb-admin ping -h"mariadb" --port=3306 --silent; do
  $COUNT=$((COUNT + 1))
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "[$SCRIPT_NAME][ERROR] No response of MariaDB after $MAX_RETRIES seconds. Stopping"
    exit 1
  fi
  sleep 1
done
if [ ! -f /var/www/$DOMAIN_NAME/wp-settings.php ]; then
  echo "[$SCRIPT_NAME][INFO] Installing wordpress"
  wp core download --path=/var/www/$DOMAIN_NAME --allow-root
  wp config create \
    --dbname=$MARIADB_DATABASE \
    --dbuser=$MYSQL_USER \
    --dbpass=$MYSQL_PASSWORD \
    --dbhost=mariadb \
    --path=/var/www/$DOMAIN_NAME \
    --allow-root
  wp core install \
    --url=$DOMAIN_NAME \
    --title="Inception" \
    --admin_user=$WP_ADMIN_USER \
    --admin_password=$WP_ADMIN_PASSWORD \
    --admin_email=$WP_ADMIN_EMAIL \
    --path=/var/www/$DOMAIN_NAME \
    --allow-root
  wp user create $WP_USER $WP_USER_EMAIL \
    --user_pass=$WP_USER_PASSWORD \
    --role=author \
    --path=/var/www/html \
    --allow-root
fi
chown -R nobody:nobody /var/www/$DOMAIN_NAME
chmod -R 755 /var/www/$DOMAIN_NAME
chmod 600 /var/www/$DOMAIN_NAME/wp-config.php
exec php-fpm83 -F
