LOCATION:=$(shell pwd)
IP:=$(shell ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($$i=="src") print $$(i+1)}')
DOMAIN_NAME:=$(shell hostname)

CERT_DIR=$(LOCATION)/certs

SECRET_DIR:="secrets"
SECRET_FILE:="$(SECRET_DIR)/secrets.env"

all: certs secrets up

certs:
	@mkdir -p $(CERT_DIR)
	@if [ ! -f "cert_rootCA.sh" ] || [ ! -f "cert_creation.sh" ]; then \
	    echo "Missing certificates handlers"; \
	    exit 1; \
	fi
	@if [ ! -f $(CERT_DIR)/ca.key ]; then \
		chmod +x cert_rootCA.sh; \
		bash cert_rootCA.sh; \
	fi
	@if [ ! -f $(CERT_DIR)/nginx.key ]; then \
		chmod +x cert_creation.sh; \
		bash cert_creation.sh $(CERT_DIR) $(IP) nginx; \
	fi

secrets:
	@if [ ! -d "$(SECRET_DIR)" ]; then \
	    echo "Missing secrets directory"; \
	    exit 1; \
	fi
	@if [ ! -f "$(SECRET_DIR)"/create_secrets.sh ] || [ ! -f "$(SECRET_DIR)"/check_secrets.sh ]; then \
	    echo "Missing secrets handlers"; \
	    exit 1; \
	fi
	@chmod +x "$(SECRET_DIR)/check_secrets.sh"
	@bash "$(SECRET_DIR)/check_secrets.sh" $(SECRET_FILE)
	@chmod +x "$(SECRET_DIR)/create_secrets.sh"
	@bash "$(SECRET_DIR)/create_secrets.sh" $(SECRET_FILE)

up:
	@mkdir -p "/home/$(USER)/data/mariadb"
	@mkdir -p "/home/$(USER)/data/wordpress"
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) docker compose -f ./srcs/requirements/docker-compose.yml up --force-recreate 

down:
	@docker compose down

clean: down
	@docker ps -a
	@docker image rm $$(docker image ls -q)
	@docker image ls

fclean: clean
	@docker volume rm $$(docker volume ls -q)
	@docker volume ls
	@sudo rm -rf "/home/$(USER)/data"

re: clean up

.PHONY: all certs secrets up down clean fclean re 
