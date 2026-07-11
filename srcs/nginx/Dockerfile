FROM alpine:3.23

RUN apk update && apk add --no-cache nginx envsubst
RUN rm /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/template_nginx.conf
RUN mkdir -p /run/nginx
COPY entrypoint.sh /home/
RUN chmod +x /home/entrypoint.sh
WORKDIR /home
EXPOSE 80 443
CMD ["sh", "entrypoint.sh"]
