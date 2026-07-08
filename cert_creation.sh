#!/bin/bash
SCRIPT_NAME="${0##*/}"

#Safeguard
set -euo pipefail
SCRIPT_NAME="${0##*/}"
if [ ! $# -eq 3 ]; then
	echo "Usage: ${SCRIPT_NAME} <ca_dir_absolute_path> <subj> <certificate_name>"
	exit 1
fi

#Setup
CA_DIR=$1
SUBJ=$2
CERT_NAME=$3
CERT_DIR="$HOME/docker_certs/"
mkdir -p ${CERT_DIR}
cd ${CERT_DIR}


#Subj key generation
if [ ! -f ${CERT_NAME}.key ]; then
    echo "[$SCRIPT_NAME] generating ${CERT_NAME} key"
    openssl genrsa -out ${CERT_NAME}.key 4096
else
    echo "[$SCRIPT_NAME] ${CERT_NAME} key already exist"
fi

#CSR generation
if [ ! -f ${CERT_NAME}.csr ]; then
    echo "[$SCRIPT_NAME] generating ${CERT_NAME} CSR"
    #San config creation
    cat > ${CERT_NAME}.cnf <<EOF
    [req]
    default_bits = 4096
    default_md = sha256
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    prompt = no

    [req_distinguished_name]
    CN = ${SUBJ}

    [v3_req]
    subjectAltName = @alt_names

    [alt_names]
    IP.1 = ${SUBJ}
    DNS.1=${CERT_NAME}
EOF
    openssl req -new \
	    -key ${CERT_NAME}.key \
	    -out ${CERT_NAME}.csr \
	    -config ${CERT_NAME}.cnf
else
    echo "[$SCRIPT_NAME] ${CERT_NAME} CSR already exist"
fi

#Sig certification
if [ ! -f ${CERT_NAME}.crt ]; then
    echo "[$SCRIPT_NAME] signing ${CERT_NAME} certificate"
    doas openssl x509 -req \
	    -in ${CERT_NAME}.csr \
	    -CA ${CA_DIR}/ca.crt \
	    -CAkey ${CA_DIR}/ca.key \
	    -CAcreateserial \
	    -CAserial ./ca.srl \
	    -out ${CERT_NAME}.crt \
	    -days 30 \
	    -sha256 \
	    -extensions v3_req \
	    -extfile ${CERT_NAME}.cnf
else
    echo "[$SCRIPT_NAME] ${CERT_NAME} certificate already signed"
fi

#clean up
if [ -f ${CERT_NAME} ]; then
    echo "[$SCRIPT_NAME] removing temp files"
    rm -f ${CERT_NAME}.cnf
fi
