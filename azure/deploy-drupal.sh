#!/usr/bin/env bash
# Deploys Drupal 11 on an Ubuntu 24.04 VM in Azure (Apache + PHP 8.3 + MariaDB).
# Usage: az login && ./deploy-drupal.sh
# Override defaults with env vars, e.g. LOCATION=westeurope VM_SIZE=Standard_B2ms ./deploy-drupal.sh
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-drupal-rg}"
LOCATION="${LOCATION:-eastus}"
VM_NAME="${VM_NAME:-drupal-vm}"
VM_SIZE="${VM_SIZE:-Standard_B2s}"
ADMIN_USER="${ADMIN_USER:-azureuser}"
SITE_NAME="${SITE_NAME:-My Drupal Site}"

DB_PASS="$(openssl rand -hex 16)"
DRUPAL_ADMIN_PASS="$(openssl rand -base64 12 | tr -d '/+=')"

CLOUD_INIT="$(mktemp)"
trap 'rm -f "$CLOUD_INIT"' EXIT

cat > "$CLOUD_INIT" <<CLOUDINIT
#cloud-config
package_update: true
packages:
  - apache2
  - mariadb-server
  - libapache2-mod-php
  - php
  - php-mysql
  - php-gd
  - php-xml
  - php-mbstring
  - php-curl
  - php-zip
  - php-intl
  - php-opcache
  - composer
  - unzip
  - git
write_files:
  - path: /etc/apache2/sites-available/drupal.conf
    content: |
      <VirtualHost *:80>
          DocumentRoot /var/www/drupal/web
          <Directory /var/www/drupal/web>
              AllowOverride All
              Require all granted
          </Directory>
          ErrorLog \${APACHE_LOG_DIR}/drupal_error.log
          CustomLog \${APACHE_LOG_DIR}/drupal_access.log combined
      </VirtualHost>
runcmd:
  - export HOME=/root COMPOSER_ALLOW_SUPERUSER=1
  - mysql -e "CREATE DATABASE drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
  - mysql -e "CREATE USER 'drupal'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  - mysql -e "GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost'; FLUSH PRIVILEGES;"
  - composer create-project drupal/recommended-project /var/www/drupal --no-interaction
  - cd /var/www/drupal && composer require drush/drush --no-interaction
  - cd /var/www/drupal && vendor/bin/drush site:install standard -y --db-url=mysql://drupal:${DB_PASS}@localhost/drupal --account-name=admin --account-pass='${DRUPAL_ADMIN_PASS}' --site-name='${SITE_NAME}'
  - chown -R www-data:www-data /var/www/drupal
  - a2enmod rewrite
  - a2dissite 000-default
  - a2ensite drupal
  - systemctl restart apache2
CLOUDINIT

echo "Creating resource group $RESOURCE_GROUP in $LOCATION..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

echo "Creating VM $VM_NAME ($VM_SIZE)..."
PUBLIC_IP="$(az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image Ubuntu2404 \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --custom-data "$CLOUD_INIT" \
  --query publicIpAddress --output tsv)"

echo "Opening port 80..."
az vm open-port --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --port 80 --priority 1010 --output none

cat <<DONE

Drupal is installing on the VM (takes about 5-10 minutes).
  Site:           http://$PUBLIC_IP
  Drupal admin:   admin / $DRUPAL_ADMIN_PASS
  SSH:            ssh $ADMIN_USER@$PUBLIC_IP
  Install log:    sudo tail -f /var/log/cloud-init-output.log (on the VM)

Save the admin password now; it is not stored anywhere else.
To delete everything: az group delete --name $RESOURCE_GROUP --yes
DONE
