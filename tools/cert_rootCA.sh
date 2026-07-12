#! /bin/bash

SCRIPT_NAME="${0##*/}"
LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR=${LOCATION}/certs

echo "[$SCRIPT_NAME] Setting up directory"
mkdir -p ${CERT_DIR}

#Server CA generation
echo "[$SCRIPT_NAME] Generating CA"
cd ${CERT_DIR}

openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes \
	    -key ca.key \
	    -sha256 \
	    -days 30 \
	    -out ca.crt 

if [ -f "/usr/local/share/ca-certificates/inception-root-ca.cert" ]; then
	sudo rm -rf "/usr/local/share/ca-certificates/inception-root-ca.crt"
	sudo update-ca-certificates
fi
sudo cp ca.crt /usr/local/share/ca-certificates/inception-root-ca.crt
sudo update-ca-certificates
