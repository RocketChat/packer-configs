#!/bin/bash

wget -O- https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/90-cleanup.sh | sudo bash
wget -O- https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/99-img-check.sh | sudo bash

sudo rm -rf /home/ubuntu/.ssh
sudo rm -rf /root/.ssh
