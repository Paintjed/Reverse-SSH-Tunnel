#!/bin/bash
STARTUP_SERVICE="autossh-tunnel.service"
LOG_FILE="/var/log/autossh.log"

echo "error_check_script.sh: Script started and is processing input..." >&2

while read -r line; do
    echo "$line" >>$LOG_FILE
    if [[ "$line" == *"remote port forwarding failed"* ]]; then
        echo "Error detected: $line" >>$LOG_FILE
        echo "Restart $STARTUP_SERVICE" >>$LOG_FILE
        systemctl restart $STARTUP_SERVICE
    fi
done
