#!/bin/bash

# Get environment variables to show up in PHP-FPM session
eval $(echo "[www]" > /etc/php/7.1/fpm/pool.d/env.conf)
eval $(env | sed "s/\(.*\)=\(.*\)/env[\1]='\2'/" | grep LOOPARS >> /etc/php/7.1/fpm/pool.d/env.conf)

# Get environment variables to show up in SSH session
# eval $(printenv | awk -F= '{print "export " $1"="$2 }' >> /etc/profile)

# setup server root
test ! -d "$HOME_SITE" && echo "INFO: $HOME_SITE not found. creating..." && mkdir -p "$HOME_SITE"
if [ ! $WEBSITES_ENABLE_APP_SERVICE_STORAGE ]; then
    echo "INFO: NOT in Azure, chown for "$HOME_SITE
    chown -R nobody:nogroup $HOME_SITE
fi

echo LOOPARS_WEBSOCKET_ADDRESS=$LOOPARS_WEBSOCKET_ADDRESS

if [ ${LOOPARS_WEBSOCKET_ADDRESS} ]; then
    sed -i "s|WEBSOCKET_ADDR=.*|WEBSOCKET_ADDR=${LOOPARS_WEBSOCKET_ADDRESS}|" /usr/local/bin/websocket_health.sh
    crontab -l | { cat; echo "*/5 * * * * /usr/local/bin/websocket_health.sh >> /tmp/kills"; } | crontab -
else
    crontab -l | { cat; echo "0 * * * * ps aux | grep loopars:ws-server:run | awk '{print \$2}' | xargs kill -9"; } | crontab -
fi


echo "Starting Container ..."
test ! -d /home/LogFiles && mkdir /home/LogFiles
test ! -f /home/LogFiles/nginx-access.log && touch /home/LogFiles/nginx-access.log
test ! -f /home/LogFiles/nginx-error.log && touch /home/LogFiles/nginx-error.log
test ! -f /home/LogFiles/php7.1-fpm.log && touch /home/LogFiles/php7.1-fpm.log
chown -R nobody:nogroup /home/LogFiles
chown -R nobody:nogroup /run/php


if [ ! ${SYMFONY_ENV} ]; then
    export SYMFONY_ENV=prod
else
    export SYMFONY_ENV=${SYMFONY_ENV}
fi

if [ ${DEBUG} ]; then
    ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log \
        && ln -sf /dev/stderr /var/log/php7.1-fpm.log
else
    ln -sf /home/LogFiles/nginx-access.log /var/log/nginx/access.log \
        && ln -sf /home/LogFiles/nginx-error.log /var/log/nginx/error.log \
        && ln -sf /home/LogFiles/php7.1-fpm.log /var/log/php7.1-fpm.log
fi

/usr/bin/supervisord
