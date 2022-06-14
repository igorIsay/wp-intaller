#! /bin/bash

sed 's/\$/\\$/g' config.sh > config.tmp.sh
source ./config.tmp.sh
rm config.tmp.sh

WP_INSTALLER_DB_NAME=$(echo "$WP_INSTALLER_SITE_NAME" | sed -e 's/[^a-zA-Z0-9]//g')
mysql -u $WP_INSTALLER_DB_USER -p$WP_INSTALLER_DB_PASSWORD <<QUERY
CREATE DATABASE $WP_INSTALLER_DB_NAME
QUERY

WP_INSTALLER_SITE_PATH=/var/www/$WP_INSTALLER_SITE_NAME

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

wp core download --path=$WP_INSTALLER_SITE_PATH --allow-root

wp config create --path=$WP_INSTALLER_SITE_PATH --dbname=$WP_INSTALLER_DB_NAME --dbuser="$WP_INSTALLER_DB_USER" --dbpass="$WP_INSTALLER_DB_PASSWORD" --allow-root
WP_INSTALLER_SITE_CONFIG_FILE=$WP_INSTALLER_SITE_PATH/wp-config.php
echo "define('FS_METHOD', 'direct');" >> $WP_INSTALLER_SITE_CONFIG_FILE

wp core install --path=$WP_INSTALLER_SITE_PATH --url=http://$WP_INSTALLER_SITE_NAME --title="$WP_INSTALLER_SITE_TITLE" --admin_user="$WP_INSTALLER_ADMIN_USER" --admin_password="$WP_INSTALLER_ADMIN_PASSWORD" --admin_email="$WP_INSTALLER_ADMIN_EMAIL" --allow-root

sudo rm -rf $WP_INSTALLER_SITE_PATH/wp-content/themes/twentytwenty
sudo rm -rf $WP_INSTALLER_SITE_PATH/wp-content/themes/twentytwentyone

find $WP_INSTALLER_SITE_PATH -type d -exec chmod 0755 {} \;
find $WP_INSTALLER_SITE_PATH -type f -exec chmod 0644 {} \;
chown -R www-data:www-data $WP_INSTALLER_SITE_PATH


WP_INSTALLER_NGINX_CONFIG=/etc/nginx/sites-available/$WP_INSTALLER_SITE_NAME
cat > $WP_INSTALLER_NGINX_CONFIG <<EOF
server {
        listen 80;
        root $WP_INSTALLER_SITE_PATH;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name $WP_INSTALLER_SITE_NAME www.$WP_INSTALLER_SITE_NAME;

        location / {
                try_files \$uri \$uri/ /index.php?\$args;
        }

        location ~ \.php\$ {
                try_files            \$uri /index.php;
                include              fastcgi_params;
                fastcgi_keep_conn    on;
                fastcgi_pass         unix:/run/php/php7.4-fpm.sock;
                fastcgi_param        SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                fastcgi_param        SCRIPT_NAME     \$fastcgi_script_name;
        }

        location ~ /\.ht {
                deny all;
        }



        location = /xmlrpc.php {
            deny all;
        }

        location /phpmyadmin {
            root /usr/share/;
            index index.php index.html index.htm;
            location ~ ^/phpmyadmin/(.+\.php)\$ {
                try_files \$uri =404;
                root /usr/share/;
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include /etc/nginx/fastcgi_params;
            }
            location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))\$ {
                root /usr/share/;
            }
        }

}
EOF

ln -s $WP_INSTALLER_NGINX_CONFIG /etc/nginx/sites-enabled/

service php7.4-fpm restart
service mysql restart
service nginx restart