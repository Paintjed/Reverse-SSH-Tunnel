# Reverse SSH Tunnel Setup Script

This script automates the setup of a reverse SSH tunnel using autossh. It creates a systemd service that starts automatically at boot, ensuring the SSH tunnel remains active.

## Prerequisites

Before running the script, make sure you have the following packages installed:

- `openssh-server`
- `autossh`
- `sshpass`

## Usage

1. Clone the repository:
```
git clone https://github.com/Paintjed/Reverse-SSH-Tunnel.git
```
2. Navigate to the directory containing the script:
```
cd Your directory
```
3. Make the script executable:
```
chmod +x setup_reverse_tunnel.sh
```
4. Run the script with sudo:
```
sudo ./setup_reverse_tunnel.sh
```

5. Follow the on-screen prompts to enter the required information:

- IP address of the server host
- Username of the server host
- Password of the server host
- Port number to map on the server (ensure it does not conflict with existing ports)
- Name of the device
- Once the script completes execution, a reverse SSH tunnel will be established between the local device and the server.

## Notes

The script generates RSA public and private keys without passwords to facilitate passwordless authentication.
It creates a user account on the server specifically for using lsof to identify port numbers associated with each device.
The systemd service autossh-tunnel.service is created to ensure the SSH tunnel starts automatically at boot.
