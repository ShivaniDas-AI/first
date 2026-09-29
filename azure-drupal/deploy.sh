#!/bin/bash
# Creates an Ubuntu 24.04 VM on Azure and installs Drupal on it via cloud-init.
# Requires the Azure CLI, logged in (`az login`).
# Override defaults with env vars, e.g. LOCATION=westeurope ./deploy.sh
set -euo pipefail

RESOURCE_GROUP=${RESOURCE_GROUP:-drupal-rg}
LOCATION=${LOCATION:-centralindia}
VM_NAME=${VM_NAME:-drupal-vm}
VM_SIZE=${VM_SIZE:-Standard_B2s}
ADMIN_USER=${ADMIN_USER:-azureuser}

cd "$(dirname "$0")"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image Ubuntu2404 \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --custom-data cloud-init.yaml \
  --output none

az vm open-port --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --port 80 --priority 1010 --output none

IP=$(az vm show -d --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query publicIps -o tsv)

cat <<MSG

VM created. Drupal is installing in the background (about 5-10 minutes).
  Site:        http://$IP
  SSH:         ssh $ADMIN_USER@$IP
  Progress:    ssh $ADMIN_USER@$IP 'sudo tail -f /var/log/install-drupal.log'
  Credentials: ssh $ADMIN_USER@$IP 'sudo cat /root/drupal-credentials.txt'

Delete everything later with:
  az group delete --name $RESOURCE_GROUP --yes
MSG
