# Drupal on Azure

Creates an Ubuntu 24.04 VM running Apache, MariaDB, PHP 8.3, and Drupal 11 (installed with Composer and Drush).

## Usage

From Azure Cloud Shell (https://shell.azure.com), or from any machine where the Azure CLI is installed and you're logged in:

```bash
git clone <this repo> && cd first/azure-drupal
./deploy.sh
```

Defaults: resource group `drupal-rg`, region `centralindia`, size `Standard_B2s`. To change them, set environment variables:

```bash
RESOURCE_GROUP=my-rg LOCATION=eastus VM_SIZE=Standard_B2ms ./deploy.sh
```

The script prints the site URL and SSH commands. The Drupal admin password is generated on the VM and saved in `/root/drupal-credentials.txt`.

## Files
- `deploy.sh`: creates the resource group and VM, and opens port 80.
- `cloud-init.yaml`: runs when the VM first boots and installs the LAMP stack and Drupal.

## Next steps for production
- Point a domain at the VM's IP and add HTTPS (`sudo apt install certbot python3-certbot-apache && sudo certbot --apache`).
- Add `trusted_host_patterns` to `web/sites/default/settings.php`.
- Consider Azure Database for MySQL instead of the local MariaDB.
