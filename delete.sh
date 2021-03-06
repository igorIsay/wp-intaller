#! /bin/bash

sed 's/\$/\\$/g' config.sh > config.tmp.sh
source ./config.tmp.sh
rm config.tmp.sh

WP_INSTALLER_DB_NAME=$(echo "$WP_INSTALLER_SITE_NAME" | sed -e 's/[^a-zA-Z0-9]//g')
mysql -u $WP_INSTALLER_DB_USER -p$WP_INSTALLER_DB_PASSWORD <<QUERY
DROP DATABASE $WP_INSTALLER_DB_NAME
QUERY

WP_INSTALLER_SITE_PATH=/var/www/$WP_INSTALLER_SITE_NAME
rm -rf $WP_INSTALLER_SITE_PATH

rm /etc/nginx/sites-available/$WP_INSTALLER_SITE_NAME
rm /etc/nginx/sites-enabled/$WP_INSTALLER_SITE_NAME
