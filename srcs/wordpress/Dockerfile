FROM alpine:3.23

RUN apk update && apk add --no-cache \
    wget \
    tar \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-phar \
    php83-mbstring \
    php83-json \
    php83-gd \
    php83-curl \
    mariadb-client
RUN ln -s /usr/bin/php83 /usr/bin/php
RUN echo "memory_limit = 256M" >> /etc/php83/php.ini
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' \
    /etc/php83/php-fpm.d/www.conf
RUN sed -i 's/;clear_env = no/clear_env = no/g' /etc/php83/php-fpm.d/www.conf
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
COPY entrypoint.sh /home
RUN chmod +x /home/entrypoint.sh
EXPOSE 9000
ENTRYPOINT ["/home/entrypoint.sh"]
