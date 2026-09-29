#!/bin/bash
# Creates an Ubuntu 24.04 VM on Azure and installs Zeek on it via cloud-init.
# Requires the Azure CLI, logged in (`az login`).
# Override defaults with env vars, e.g. LOCATION=westeurope ./deploy.sh
set -euo pipefail

RESOURCE_GROUP=${RESOURCE_GROUP:-zeek-rg}
LOCATION=${LOCATION:-centralindia}
VM_NAME=${VM_NAME:-zeek-vm}
VM_SIZE=${VM_SIZE:-Standard_B2ms}
ADMIN_USER=${ADMIN_USER:-azureuser}

cd "$(dirname "$0")"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# Accelerated networking is off so the NIC shows up as a single plain interface to Zeek.
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image Ubuntu2404 \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --accelerated-networking false \
  --custom-data cloud-init.yaml \
  --output none

IP=$(az vm show -d --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query publicIps -o tsv)

cat <<MSG

VM created. Zeek is installing in the background (about 5 minutes).
  SSH:       ssh $ADMIN_USER@$IP
  Progress:  ssh $ADMIN_USER@$IP 'sudo tail -f /var/log/install-zeek.log'
  Status:    ssh $ADMIN_USER@$IP 'sudo zeekctl status'
  Logs:      /opt/zeek/logs/current/ (conn.log, dns.log, http.log, ssl.log, ...)

Delete everything later with:
  az group delete --name $RESOURCE_GROUP --yes
MSG
