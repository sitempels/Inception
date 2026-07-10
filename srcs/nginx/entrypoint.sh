#! /bin/sh
SCRIPT_NAME="${0##*/}"
envsubst '${DOMAIN_NAME}' < /etc/nginx/template_nginx.conf > /etc/nginx/nginx.conf
exec nginx -g "daemon off;"
