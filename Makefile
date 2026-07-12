LOCATION:=$(shell pwd)
IP:=$(shell ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($$i=="src") print $$(i+1)}')
DOMAIN_NAME=$(shell hostname)
SHELL:=/bin/bash

TOOLS_DIR=$(LOCATION)/tools
CERT_DIR=$(TOOLS_DIR)/certs
SECRET_DIR:="$(TOOLS_DIR)/secrets"
ENV_FILE:="$(LOCATION)/.env"
COMPOSE_FILE:="$(LOCATION)"/srcs/docker-compose.yml 

include .env.mk

export

.env.mk: env

all: host certs secrets up

host: env
	@if [ ! $(DOMAIN_NAME)==$(NEW_HOSTNAME) ]; then \
	    sudo hostnamectl set-hostname $(NEW_HOSTNAME); \
	    sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\tnew-hostname/" /etc/hosts; \
	    sudo systemctl restart systemd-hostnamed; \
	    sudo systemctl restart ssh; \
	    DOMAIN_NAME=$$(hostname); \
	    echo "Host name changed to: $(DOMAIN_NAME)"; \
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

env: .env
	@if [ ! -f "$(TOOLS_DIR)"/create_env.sh ] || [ ! -f "$(TOOLS_DIR)"/check_env.sh ]; then \
	    echo "Missing env handlers"; \
	    exit 1; \
	fi
	@chmod +x "$(TOOLS_DIR)/check_env.sh"
	@bash "$(TOOLS_DIR)/check_env.sh" $(ENV_FILE)
	@chmod +x "$(TOOLS_DIR)/create_env.sh"
	@bash "$(TOOLS_DIR)/create_env.sh" $(ENV_FILE) > .env.mk

.env:
	@if [ -f template_env ]; then \
		echo "Creating .env file, please set all variables"; \
		cp template_env	.env; \
		vim -c 'set shortmess+=I' .env; \
	else \
		echo "Template_env file missing, you will need to create .env file yourself.\n See READ_ME for how to do it"; \
		exit 1; \
	fi

secrets:
	@mkdir -p $(SECRET_DIR)
	@if [ ! -f "$(TOOLS_DIR)"/create_secrets.sh ] || [ ! -f "$(TOOLS_DIR)"/check_env.sh ]; then \
	    echo "Missing secrets handlers"; \
	    exit 1; \
	fi
	@chmod +x "$(TOOLS_DIR)/check_env.sh"
	@bash "$(TOOLS_DIR)/check_env.sh" $(ENV_FILE)
	@chmod +x "$(TOOLS_DIR)/create_secrets.sh"
	@bash "$(TOOLS_DIR)/create_secrets.sh" $(ENV_FILE)

build:
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f $(COMPOSE_FILE) build

up:
	@mkdir -p "/home/$(USER)/data/mariadb"
	@mkdir -p "/home/$(USER)/data/wordpress"
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f $(COMPOSE_FILE) up -d

down:
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f $(COMPOSE_FILE) down

start:
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f $(COMPOSE_FILE) start

stop:
	@DOMAIN_NAME=$(DOMAIN_NAME) CERT_DIR=$(CERT_DIR) SECRET_DIR=$(SECRET_DIR) docker compose -f $(COMPOSE_FILE) stop

clean: down
	@docker ps -a
	@docker image rm $$(docker image ls -q) 2>/dev/null || true
	@docker image ls
	@sudo rm -rf $(SECRET_DIR)
	@rm -rf .env.mk

fclean: clean
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker volume ls
	@sudo rm -rf "/home/$(USER)/data"
	@sudo rm -rf $(CERT_DIR)
	@sudo rm -rf /usr/local/share/ca-certificates/inception-root-ca.crt
	@sudo update-ca-certificates

re: clean all

fre: fclean all

.PHONY: all host certs env secrets build up down start stop clean fclean re fre
