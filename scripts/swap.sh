#!/bin/bash

echo "Setting up swap (512m)"

sudo dd if=/dev/zero of=/swapfile count=512 bs=1M
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
