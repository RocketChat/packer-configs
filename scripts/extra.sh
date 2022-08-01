#!/bin/bash

rm -rvf $HOME/.ssh/authorized_keys
rm -rvf /var/log/*

# provided by DO
wget -O- https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/90-cleanup.sh | sudo bash
wget -O- https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/99-img-check.sh | sudo bash
