LOCATION:=$(shell pwd)
CERT_DIR=$(LOCATION)/certs
DOMAIN_NAME:=stempels.42.fr
IP:=$(shell ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($$i=="src") print $$(i+1)}')
setup:
	mkdir -p $(CERT_DIR)
	if [ ! -f $(CERT_DIR)/ca.key ]; then \
		chmod +x cert_rootCA.sh; \
		bash cert_rootCA.sh; \
	fi
	if [ ! -f $(CERT_DIR)/nginx.key ]; then \
		chmod +x cert_creation.sh; \
		bash cert_creation.sh $(CERT_DIR) $(IP) nginx; \
	fi
up:
	DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) docker compose -f ./srcs/requirements/docker-compose.yml -d up

down:
	docker compose inception down

clean:
	docker stop $$(docker ps -aq)
	docker rm $$(docker ps -aq)
	docker image rm $$(docker image ls -q)

fclean: clean
	docker volume rm $$(docker volume ls -q)

.PHONY: all re clean fclean
