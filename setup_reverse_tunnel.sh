#!/bin/bash

if [ -z "$SUDO_USER" ]; then
  echo "$0 must be called from sudo. Try: 'sudo ${0}'"
  exit 1
fi

STARTUP_SERVICE="autossh-tunnel.service"
STARTUP_SERVICE_LOCATION="/etc/systemd/system/$STARTUP_SERVICE"

# Check if the service file exists
if [ -f "$STARTUP_SERVICE_LOCATION" ]; then
  echo "Service $STARTUP_SERVICE exists. It appears there is a duplicate service. Please remove it manually and then restart the script."
  exit 0
fi

echo "Installing openssh-server ,autossh and sshpass"
apt-get install openssh-server autossh sshpass

read -p "Enter the ip address of server host: " SERVER_IP
read -p "Enter the user name of server host: " SERVER_USERNAME
read -s -p "Enter the password of server host: " SERVER_PASSWORD

# 使用 ssh 嘗試連接
if sshpass -p "$SERVER_PASSWORD" ssh "$SERVER_USERNAME@$SERVER_IP" true; then
  echo "Login successful"
else
  echo "Login failed"
  exit 1
fi

RSA_KEY_NAME="autossh"
RSA_KEY_LOCATION="$HOME/.ssh"

echo "Generate RSA Public key and Private key without password"
ssh-keygen -t rsa -N "" -f $RSA_KEY_LOCATION/$RSA_KEY_NAME
public_key_content=$(cat $RSA_KEY_LOCATION/$RSA_KEY_NAME.pub)

sshpass -p "$SERVER_PASSWORD" ssh $SERVER_USERNAME@$SERVER_IP "echo ${SERVER_PASSWORD} | sudo -S lsof -i4 -iTCP -sTCP:LISTEN -P -n"
echo "Enter port number that will be mapped in the server (Not duplicate the above port numbers):"
read PORT_NUMBER

echo "Enter the name of device"
read DEVICE_NAME

# Create an account specifically for using "lsof" to identify the port number associated with each device.
# add_user_error=($(ssh $SERVER_USERNAME@$SERVER_IP "useradd $DEVICE_NAME -m -s /bin/rbash"))
# if [ $? -eq 0 ]; then
#   echo "$DEVICE_NAME added successfully."
# else
#   echo $result
# fi

remote_script=$(
  cat <<EOF
  #!/bin/bash
  set -e
  echo ${SERVER_PASSWORD} | sudo -S useradd ${DEVICE_NAME} -m -s /bin/rbash # Use sudo for user creation
  echo ${SERVER_PASSWORD} | sudo -S mkdir /home/${DEVICE_NAME}/.ssh 
  echo ${SERVER_PASSWORD} | sudo -S mkdir /home/${DEVICE_NAME}/bin
  echo ${SERVER_PASSWORD} | sudo -S touch /home/${DEVICE_NAME}/.ssh/authorized_keys
  echo ${SERVER_PASSWORD} | sudo -S tee -a /home/${DEVICE_NAME}/.ssh/authorized_keys >/dev/null <<< "$public_key_content" # Double quotes for variable expansion
  echo ${SERVER_PASSWORD} | sudo -S chown -R ${DEVICE_NAME}:${DEVICE_NAME} /home/${DEVICE_NAME}/.ssh # Use sudo for ownership changes
  echo ${SERVER_PASSWORD} | sudo -S chmod -R 700 /home/${DEVICE_NAME}/.ssh
EOF
)

sshpass -p "$SERVER_PASSWORD" ssh $SERVER_USERNAME@$SERVER_IP 'bash -s' <<<"$remote_script"
remote_script_exit_status=$?

if [ $remote_script_exit_status -ne 0 ]; then
  echo "remote_script execution failed."
  exit 1
fi

echo "remote_script execution successfully."
# ps x | grep ssh
# autossh -f -o "ServerAliveInterval 20" -o "ServerAliveCountMax 3" -NR $PORT_NUMBER:localhost:22 -i $RSA_KEY_LOCATION/$RSA_KEY_NAME $DEVICE_NAME@$SERVER_IP
# ps x | grep ssh

# Add error check script for restarting the service.
CHECK_ERROR_SCRIPT="error-check-script.sh"
CHECK_ERROR_SCRIPT_FORWARD_LOC="/opt/autossh/"
sudo mkdir -p /opt/autossh
sudo cp $CHECK_ERROR_SCRIPT $CHECK_ERROR_SCRIPT_FORWARD_LOC
sudo chmod +x $CHECK_ERROR_SCRIPT_FORWARD_LOC$CHECK_ERROR_SCRIPT_LOC

tee $STARTUP_SERVICE_LOCATION <<EOF
[Unit]
Description=AutoSSH tunnel service
After=network.target

[Service]
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -o "ServerAliveInterval=60" -o "ServerAliveCountMax=5" -NR ${PORT_NUMBER}:localhost:22 -i $RSA_KEY_LOCATION/$RSA_KEY_NAME ${DEVICE_NAME}@${SERVER_IP} 2>&1 | $CHECK_ERROR_SCRIPT_FORWARD_LOC$CHECK_ERROR_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $STARTUP_SERVICE
systemctl start $STARTUP_SERVICE
systemctl status $STARTUP_SERVICE
