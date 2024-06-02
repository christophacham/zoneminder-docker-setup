#!/bin/bash

echo "date.timezone = '$PHP_TIMEZONE'" > /etc/php/conf.d/local.ini
sed -e '/extension=zip/ s/^;*/;/' -i /etc/php/php.ini

echo "Starting fcgiwrap"
su -s /bin/bash http -c "spawn-fcgi -s /run/fcgiwrap/fcgiwrap.sock -F 10 -U http -G http -- /usr/bin/fcgiwrap" || exit 1
echo "Starting php-fpm"
chown http:http /run/php-fpm
su -s /bin/bash http -c "php-fpm" || exit 1
echo "Starting nginx"

echo "Updating Zoneminder DB"
COUNT=0
while ! zmupdate.pl --nointeractive && [[ $COUNT -lt 6 ]]; do
    sleep 5
    COUNT=$((COUNT+1))
done

zmupdate.pl --nointeractive -f || exit 1

echo "Starting Zoneminder"
su -s /bin/bash http -c "zmpkg.pl start" || exit 1

echo "ZM started on $(cat /run/zoneminder/zm.pid)"

exec nginx -g "daemon off;"
