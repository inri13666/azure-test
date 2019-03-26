#!/bin/sh

WEBSOCKET_ADDR=CHANGE_ME_FROM_INIT_CONATINER_SH
RESULT=`curl --include --no-buffer \
     --header "Connection: close" \
     --header "Upgrade: websocket" \
     --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
     --header "Sec-WebSocket-Version: 13" \
     ${WEBSOCKET_ADDR} 2> /dev/null | grep 'HTTP/1.1 101 Switching Protocols'`

date
echo Checking ${WEBSOCKET_ADDR}

if [ ! "${RESULT}" ]; then
    echo Bad Websocket status
    echo Restarting ...
    ps aux | grep loopars:ws-server:run | awk '{print $2}' | xargs kill -9
else
    echo Websocket health is OK
fi
