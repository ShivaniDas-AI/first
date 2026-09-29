# Zeek on Azure

Creates an Ubuntu 24.04 VM and installs Zeek LTS from the official Zeek package repository. Zeek watches the VM's network interface and writes JSON logs to `/opt/zeek/logs/current/`.

## Usage

From Azure Cloud Shell (https://shell.azure.com), or from any machine where the Azure CLI is installed and you're logged in:

```bash
git clone <this repo> && cd first/azure-zeek
./deploy.sh
```

Defaults: resource group `zeek-rg`, region `centralindia`, size `Standard_B2ms` (2 vCPU, 8 GB RAM). To change them, set environment variables:

```bash
RESOURCE_GROUP=my-rg LOCATION=eastus VM_SIZE=Standard_D4s_v5 ./deploy.sh
```

Useful commands on the VM:

```bash
sudo zeekctl status      # is Zeek running?
sudo zeekctl deploy      # apply config changes
ls /opt/zeek/logs/current/
```

## What traffic does it see?

An Azure VM only receives traffic addressed to it. Unlike a physical switch, Azure has no promiscuous-mode span port. So by default this Zeek sensor only sees the VM's own traffic.

To monitor other machines' traffic:
- **Route through it:** make the Zeek VM a gateway (enable IP forwarding on its NIC and add user-defined routes) so the traffic passes through it.
- **Mirror traffic to it:** send copies of other VMs' packets to the sensor with a packet-mirroring or network-TAP product from the Azure Marketplace, for example Gigamon or cPacket.
- **Run Zeek on each VM:** put this same cloud-init on each machine you want to watch, and forward the JSON logs to one central place.

## Files
- `deploy.sh`: creates the resource group and VM.
- `cloud-init.yaml`: runs when the VM first boots and installs, configures and starts Zeek.
