#!/usr/bin/env bash

SCRIPT_NAME="${0##*/}"
SSH_PORT="2222"
SSH_HOST="localhost"
VM_USER="root"

# VM Configuration
VM_DIR="$HOME/goinfre"   # Default VM directory
VM_NAME="swarmnode_$USER"    # Default VM name

# Start VM
VBoxManage startvm "$VM_NAME"
#    --type headless
echo "Starting VM..."

# Wait until SSH becomes reachable
echo "Waiting for SSH..."

while ! ssh \
    -p 2222 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=2 \
    "$VM_USER@$SSH_HOST" true 2>/dev/null
do
    sleep 2
done

echo "SSH is online"
