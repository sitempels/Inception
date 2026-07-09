#! /bin/sh

SCRIPT_NAME="${0##*/}"
if [ ! -d "/var/run/mysqld" ]; then
  mkdir -p /var/run/mysqld
  chown -R mysql:mysql /var/run/mysqld
  chmod 755 /var/run/mysqld
fi

if [ ! -d /var/lib/mysql/mysql ]; then
  echo "[$SCRIPT_NAME][INFO] Initialising database dir"
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi
echo "[$SCRIPT_NAME][INFO] Configuring database"
tmpfile=`mktemp`
MARIADB_DATABASE=$(cat /run/secrets/mariadb_database)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
MYSQL_USER=$(cat /run/secrets/mysql_user)
MYSQL_USER_PASSWORD=$(cat /run/secrets/mysql_user_password)
cat << EOF > $tmpfile
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS '$MARIADB_DATABASE';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PASSWORD';
GRANT ALL PRIVILEGES ON '$MARIADB_DATABASE'.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF
mariadbd --user=mysql --datadir=/var/lib/mysql --bootstrap < "$tmpfile"
rm -f $tmpfile
exec mariadbd \
    --user=mysql \
    --datadir=/var/lib/mysql \
    --console \
    --bind-address=0.0.0.0 \
    --port=3306 \
    --socket=/var/run/mysqld/mysqld.sock \
    --skip-networking=0
