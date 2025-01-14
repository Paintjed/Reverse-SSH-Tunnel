#!/bin/bash
STARTUP_SERVICE="autossh-tunnel.service"

while read -r line; do
    echo "$line" >>/var/log/autossh.log
    if [[ "$line" == *"remote port forwarding failed"* ]]; then
        echo "Error detected: $line"
        systemctl restart $STARTUP_SERVICE
    fi
done
