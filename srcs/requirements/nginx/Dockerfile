FROM alpine:3.23

RUN apk update && apk add --no-cache nginx
RUN rm /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /run/nginx
COPY entrypoint.sh /home/
RUN chmod +x /home/entrypoint.sh
WORKDIR /home
CMD ["sh", "entrypoint.sh"]
