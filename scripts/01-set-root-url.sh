#!/bin/bash

url="http://$(curl -s ipinfo.io/ip):3000"
find /root/rocketchat /home/ubuntu/rocketchat \
  -maxdepth 1 \
  -name compose.yml \
  -type f \
  -execdir sed -iE "s@ROOT_URL=.+@ROOT_URL=$url@" .env
