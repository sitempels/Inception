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
	DOMAIN_NAME=$(DOMAIN_NAME) docker compose -f ./srcs/requirements/docker-compose.yml up
