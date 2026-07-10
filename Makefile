LOCATION:=$(shell pwd)
IP:=$(shell ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($$i=="src") print $$(i+1)}')
DOMAIN_NAME=$(shell hostname)
SHELL:=/bin/bash

TOOLS_DIR=$(LOCATION)/tools
CERT_DIR=$(TOOLS_DIR)/certs
SECRET_DIR:="$(TOOLS_DIR)/secrets"
ENV_FILE:="$(LOCATION)/.env"

all: host certs secrets up

host: env
	@if [ ! $(DOMAIN_NAME)==$(NEW_HOSTNAME) ]; then \
	    sudo hostnamectl set-hostname $(NEW_HOSTNAME) \
	    sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\tnew-hostname/" /etc/hosts \
	    sudo systemctl restart systemd-hostnamed \
	    sudo systemctl restart ssh \
	    DOMAIN_NAME=$(shell hostname) \
	    @echo "Host name changed to: $(DOMAIN_NAME)" \
	fi

certs:
	@mkdir -p $(CERT_DIR)
	@if [ ! -f "$(TOOLS_DIR)/cert_rootCA.sh" ] || [ ! -f "$(TOOLS_DIR)/cert_creation.sh" ]; then \
	    echo "Missing certificates handlers"; \
	    exit 1; \
	fi
	@if [ ! -f $(CERT_DIR)/ca.key ]; then \
		chmod +x $(TOOLS_DIR)/cert_rootCA.sh; \
		bash $(TOOLS_DIR)/cert_rootCA.sh; \
	fi
	@if [ ! -f $(CERT_DIR)/nginx.key ]; then \
		chmod +x $(TOOLS_DIR)/cert_creation.sh; \
		bash $(TOOLS_DIR)/cert_creation.sh $(CERT_DIR) $(IP) nginx; \
	fi

env:
	@if [ ! -f "$(TOOLS_DIR)"/create_env.sh ] || [ ! -f "$(TOOLS_DIR)"/check_env.sh ]; then \
	    echo "Missing env handlers"; \
	    exit 1; \
	fi
	@chmod +x "$(TOOLS_DIR)/check_env.sh"
	@bash "$(TOOLS_DIR)/check_env.sh" $(ENV_FILE)
	@chmod +x "$(TOOLS_DIR)/create_env.sh"
	@source <($("$(TOOLS_DIR)/create_env.sh" $(ENV_FILE)))
	
secrets:
	@mkdir -p $(SECRETS_DIR)
	@if [ ! -f "$(TOOLS_DIR)"/create_secrets.sh ] || [ ! -f "$(TOOLS_DIR)"/check_env.sh ]; then \
	    echo "Missing secrets handlers"; \
	    exit 1; \
	fi
	@chmod +x "$(TOOLS_DIR)/check_env.sh"
	@bash "$(TOOLS_DIR)/check_env.sh" $(ENV_FILE)
	@chmod +x "$(TOOLS_DIR)/create_secrets.sh"
	@bash "$(TOOLS_DIR)/create_secrets.sh" $(ENV_FILE)

build:
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f ./srcs/requirements/docker-compose.yml build

up:
	@mkdir -p "/home/$(USER)/data/mariadb"
	@mkdir -p "/home/$(USER)/data/wordpress"
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f ./srcs/requirements/docker-compose.yml up -d

down:
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f ./srcs/requirements/docker-compose.yml down

start:
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f ./srcs/requirements/docker-compose.yml start

stop:
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f ./srcs/requirements/docker-compose.yml stop

clean: down
	@docker ps -a
	@docker image rm $$(docker image ls -q) 2>/dev/null || true
	@docker image ls

fclean: clean
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker volume ls
	@sudo rm -rf "/home/$(USER)/data"

re: clean up

.PHONY: all host certs env secrets build up down start stop clean fclean re 
