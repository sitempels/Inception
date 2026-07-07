#!/bin/bash
set -e

#Safeguard
SCRIPT_NAME="${0##*/}"

if [ ! $# -eq 2 ]; then
    echo "Usage: ${SCRIPT_NAME} <node type> <node new username>"
    exit 1
elif [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ${SCRIPT_NAME} <node type> <node new username>"
    exit 1
elif [ "$USER" != "root" ]; then
    echo "[$SCRIPT_NAME] This script need to be runned as root"
    exit 1
fi

#Setup
TYPE="$1"
NEW_USER="$2"
IP=$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
CERT_DIR="/etc/certs/"
SSH_CONFIG="/etc/ssh/sshd_config"
echo "[${SCRIPT_NAME}] VM ip: ${IP}"

#Change for env procured password
NEW_USER_HOME="/home/$NEW_USER"
NEW_USER_PASSWORD="Nd${NEW_USER}123"

echo "[$SCRIPT_NAME] Creating user: $NEW_USER"
adduser -D -h "$NEW_USER_HOME" "$NEW_USER"
echo "${NEW_USER}:${NEW_USER_PASSWORD}" | chpasswd

echo "[$SCRIPT_NAME] Setting up ${NEW_USER} permissions"
addgroup "$NEW_USER" wheel
addgroup "$NEW_USER" docker

echo "[$SCRIPT_NAME] Setting up ${NEW_USER} SSH login"
mkdir -p "$NEW_USER_HOME/.ssh"
chmod 700 "${NEW_USER_HOME}/.ssh"
cat "${HOME}/.ssh/authorized_keys" > "${NEW_USER_HOME}/.ssh/authorized_keys" 
chmod 600 "${NEW_USER_HOME}/.ssh/authorized_keys"
chown -R ${NEW_USER}:${NEW_USER} "${NEW_USER_HOME}/.ssh"

echo "[$SCRIPT_NAME] Disabling root SSH login"
cp "$SSH_CONFIG" "${SSH_CONFIG}.bak"
if grep -q "^#*PermitRootLogin" "$SSH_CONFIG"; then
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
else
    echo "PermitRootLogin no" >> "$SSH_CONFIG"
fi

echo "[$SCRIPT_NAME] Changing VM hostname to: swarmnode.${NEW_USER}"
echo "swarmnode.${NEW_USER}" > /etc/hostname

#Server CA creation
if [ ${TYPE} == "manager" ]; then

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

    echo "[$SCRIPT_NAME] Setting up Docker Daemon"
    mkdir -p "/etc/docker"
    if [ ! -f ${CERT_DIR}/ca.crt ]; then
	echo "[$SCRIPT_NAME] Missing CA certificate, marking registry as insecure"
	if [ -f "/etc/docker/daemon.json" ]; then
	    rm -f "/etc/docker/daemon.json"
	fi
	cat > "/etc/docker/daemon.json" << EOF
	{
	    "insecure-registries": [
		"${IP}:5050"
	    ]
	}
EOF
    else
	echo "[$SCRIPT_NAME] Found CA certificate, marking registry as secure"
	mkdir -p "/etc/docker/certs.d/${IP}:5050/"
	cp "${CERT_DIR}/ca.crt" "/etc/docker/certs.d/${IP}:5050/"
    fi
fi

echo "[${SCRIPT_NAME}] VM ip: ${IP}"

echo "[$SCRIPT_NAME] Restarting VM"
reboot
