#!/bin/bash

SCRIPT_NAME="${0##*/}"
SCRIPT_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set script variable
CONFIG_FILE="$SCRIPT_LOCATION/worker_config.txt"
using_defaults=false

#Base image -->Default value, overide in CONFIG_FILE
DEFAULT_BASE_DIR="$HOME/sgoinfre/students/stempels/"
BASE_IMG="vm_node_base.vdi"

SSH_KEY_NAME="inception_vm"
SSH_KEY_PASSPHRASE=

# VM Configuration
DEFAULT_VM_DIR="$HOME/goinfre/"

# Vm config
RAM_MB=2048
VRAM_MB=16
CPUS=2
DISK_SIZE_MB=10240

SSH_PORT="2222"
SSH_HOST="localhost"

VM_NAME="inception_vm"
VM_USER="$USER"
VM_TARGET_DIR="/home/$USER"
BASE_DIR=""
VM_DIR=""

#Safeguard
set -euo pipefail

wait_for_ssh() {
    set +e
#    mkdir -p "$HOME/.ssh/ssh-mux"
#    ssh -nNf -o ControlMaster=yes -o ControlPath="$CONTROL_PATH" "$VM_USER"@"$SSH_HOST" -p "$SSH_PORT"
    RESULT=1
    TIMEOUT=30
    INTERVAL=2
    ELAPSED=0
    echo -n "[$SCRIPT_NAME] Waiting for VM to boot."
    while :; do
	status=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=10 ${VM_USER}@${SSH_HOST} -p${SSH_PORT} "exit 0" 2>&1)
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
	    echo " connected"
	    break
	fi
	if [ $RESULT -eq 255 ]; then
	    if [[ $status == *"Permission denied"* ]]; then
		echo " server found"
		break
	    fi
	fi
	TIMEOUT=$((TIMEOUT - 1))
	if [ $TIMEOUT -eq 0 ]; then
	    echo " timed out"
	    exit 1
	fi
	sleep 2
	echo -n "."
    done
    set -e
}

# Check if VM already run, exist, if not create it
if VBoxManage showvminfo "$VM_NAME" --machinereadable 2>&1 | grep -q '^VMState="running"'; then
    wait_for_ssh
elif VBoxManage showvminfo "$VM_NAME" >/dev/null 2>&1; then
    echo "[$SCRIPT_NAME] $VM_NAME exist..."
    # Start VM
    echo "[$SCRIPT_NAME] Starting VM..."
    VBoxManage startvm "$VM_NAME" --type headless
    wait_for_ssh
elif [ -f "$VM_DIR/$VM_NAME/$VM_NAME.vbox" ]; then
    echo "[$SCRIPT_NAME] $VM_NAME exist but is not registered. Registering now..."
    VBoxManage registrvm "$VM_DIR/$VM_NAME/$VM_NAME.vbox"
    # Start VM
    echo "[$SCRIPT_NAME] Starting VM..."
    VBoxManage startvm "$VM_NAME" --type headless
    wait_for_ssh
else
	VM_USER="root"
	# Get config argument and set default value if missing
	if [ ! -f "$CONFIG_FILE" ]; then
		using_defaults=true
		echo "[$SCRIPT_NAME] $CONFIG_FILE not found."
	else
		echo "[$SCRIPT_NAME] $CONFIG_FILE found."
		while IFS='=' read -r key value; do
			case "$key" in
				BASE_DIR) BASE_DIR="$value";;
				VM_DIR) VM_DIR="$value";;
			esac
		done < "$CONFIG_FILE"
		if [ -z "$BASE_DIR" ] || [ -z "$VM_DIR" ]; then
			using_defaults=true
			echo "[$SCRIPT_NAME] variable in configuration file."
		fi
	fi

	# Prompt for default value usage
	if [ "$using_defaults" == true ]; then
		echo "[$SCRIPT_NAME] default value:"
		BASE_DIR=$DEFAULT_BASE_DIR
		VM_DIR=$DEFAULT_VM_DIR
		echo -e "\tdirectory: $DEFAULT_VM_DIR\tBase Vm directory: $BASE_DIR"
		read -p " Proceed with these values ? (y/N): " answer
		case "${answer,,}" in
			[y]|[yes]) ;;
			*) echo "[$SCRIPT_NAME] Aborted."
				exit 1 ;;
		esac
	fi

	# Validate the values
	if [ ! -d "$BASE_DIR" ] || [ ! -d "$VM_DIR" ];then
		echo "[$SCRIPT_NAME] directory $BASE_DIR or $VM_DIR does not exist"
		exit 1
	elif [ ! -f "$BASE_DIR/$BASE_IMG" ];then
		echo "[$SCRIPT_NAME] base vm image in $BASE_DIR"
		exit 1
	fi

	echo "[$SCRIPT_NAME] name: $VM_NAME"
	echo "[$SCRIPT_NAME] directory: $VM_DIR"

    # Create VM
    echo "[$SCRIPT_NAME] Creating VM..."
    VBoxManage createvm \
	--name "$VM_NAME" \
	--basefolder "$VM_DIR" \
	--register

    # Configure VM
    echo "[$SCRIPT_NAME] Configuring VM..."
    VBoxManage modifyvm "$VM_NAME" \
	--memory "$RAM_MB" \
	--vram "$VRAM_MB" \
	--cpus "$CPUS" \
	--nic1 nat \
	    --natpf1 "http,tcp,,8080,,80" \
	    --natpf1 "https,tcp,,8443,,443" \
	    --natpf1 "ssh,tcp,,2222,,22" \
	    --paravirtprovider default \
	    --nictype1 virtio \
	    --natdnshostresolver1 on \
	--audio-enabled off \
	--usb off \
	--clipboard bidirectional \
	--draganddrop bidirectional \
	--graphicscontroller vmsvga

    # Create Disk
    echo "[$SCRIPT_NAME] Creating virtual disk..."
    mkdir -p "$VM_DIR/$VM_NAME"
    VBoxManage clonemedium disk \
	"$BASE_DIR/$BASE_IMG" \
	"$VM_DIR/$VM_NAME/$VM_NAME.vdi"

    # Storage Controllers
    echo "[$SCRIPT_NAME] Adding storage controllers..."
    VBoxManage storagectl "$VM_NAME" \
	--name "SATA Controller" \
	--add sata

    echo "[$SCRIPT_NAME] Attaching disk..."
    VBoxManage storageattach "$VM_NAME" \
	--storagectl "SATA Controller" \
	--port 0 \
	--device 0 \
	--type hdd \
	--medium "$VM_DIR/$VM_NAME/$VM_NAME.vdi"

    # Boot Order
    VBoxManage modifyvm "$VM_NAME" \
	--boot1 disk \
	--boot2 none \
	--boot3 none \
	--boot4 none

    # Set scalable GUI
    VBoxManage setextradata "$VM_NAME" \
	    --GUI/SCALEMODE "true"

    # Start VM
    echo "[$SCRIPT_NAME] Starting VM..."
    VBoxManage startvm "$VM_NAME" --type headless

    #Waiting for VM ssh to be ready
    if [ ! -f "$HOME/.ssh/${SSH_KEY_NAME}.pub" ]; then
	ssh-keygen -f $HOME/.ssh/${SSH_KEY_NAME} -N "$SSH_KEY_PASSPHRASE"
    fi
    PUB_KEY="$HOME/.ssh/${SSH_KEY_NAME}.pub"
    wait_for_ssh
#    echo "[$SCRIPT_NAME] SSH is fully ready"
    echo "[$SCRIPT_NAME] Setting up worker"
    echo "$IP" > "infra/host_ip.txt"

#    VM_TARGET_DIR="/home/$USER"

    echo "[$SCRIPT_NAME] Setting up node"
    ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no "$VM_USER"@"$SSH_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh; grep -qxf \"$(cat $PUB_KEY)\" ~/.ssh/authorized_keys 2>/dev/null || echo \"$(cat $PUB_KEY)\" >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; exit 0"
    declare -A BUNDLE
    BUNDLE="vm_management/setup_node.sh vm_management/cert_info.env"
    read -r -a files <<< "${BUNDLE}"
    echo "[$SCRIPT_NAME] adding needed file: ${files[@]}"
    VM_TARGET_DIR="/"
    set +e
    scp -r -P "$SSH_PORT" -o StrictHostKeyChecking=no "${files[@]}" "$VM_USER"@"$SSH_HOST":"$VM_TARGET_DIR"
    ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no "$VM_USER"@"$SSH_HOST" "chmod +x /setup_node.sh; bash /setup_node.sh $TYPE $USER; exit 0"
    set -e

    while ssh -p $SSH_PORT -o ConnectTimeout=2 -o BatchMode=yes "$VM_USER"@"$SSH_HOST" true >/dev/null 2>&1; do
	sleep 2
    done
    echo "[$SCRIPT_NAME] Switching user"
    VM_USER=$USER
    VM_TARGET_DIR="/home/$USER"
    echo "[$SCRIPT_NAME] Current user: $VM_USER"
    wait_for_ssh
    declare -A PACK
    PACK="srcs"
    read -r -a files <<< "${PACK}"
    echo "[$SCRIPT_NAME] adding needed file: ${files[@]}"
    set +e
    scp -r -P "$SSH_PORT" -o StrictHostKeyChecking=no "${files[@]}" "$VM_USER"@"$SSH_HOST":"$VM_TARGET_DIR"
    set -e
fi
set +e
ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no "$VM_USER"@"$SSH_HOST"
set -e
