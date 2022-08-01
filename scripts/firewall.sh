#!/bin/bash

echo "Setting firewall rules"

sudo apt -y install ufw
sudo ufw allow ssh
sudo ufw allow 3000/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing
yes | sudo ufw enable
