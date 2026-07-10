FROM alpine:3.23

RUN apk update && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/lib/mysql /var/run/mysqld
RUN chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
RUN chmod 755 /var/run/mysqld
COPY entrypoint.sh /home/
RUN chmod +x /home/entrypoint.sh
WORKDIR /home
ENTRYPOINT ["sh", "entrypoint.sh"]
