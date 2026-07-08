#! /bin/bash

SCRIPT_NAME="${0##*/}"

echo "[$SCRIPT_NAME] Setting up directory"
mkdir -p ${CERT_DIR}

#Server CA generation
echo "[$SCRIPT_NAME] Generating CA"
cd ${CERT_DIR}

openssl genrsa -out ca.key 4096
if [ -f /cert_info.env ]; then
    source "/cert_info.env"
    SUBJECT="/C=${CONTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${OU}/CN=${IP}"
    openssl req -x509 -new -nodes \
		    -key ca.key \
		    -sha256 \
		    -days 30 \
		    -out ca.crt \
		    -subj "$SUBJECT"
else
    openssl req -x509 -new -nodes \
		    -key ca.key \
		    -sha256 \
		    -days 30 \
		    -out ca.crt 
fi
