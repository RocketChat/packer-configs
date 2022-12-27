#!/bin/bash

readonly ip_address="$(curl ipinfo.io/ip)"
readonly root_url="http://${ip_address}:3000"

if [[ -d /root/rocketchat ]]; then readonly edit_file="/root/rocketchat/.env"; else readonly edit_file="/home/ubuntu/rocketchat/.env"; fi
printf "ROOT_URL=%s" "$root_url" >> "$edit_file"

cd "$(dirname "$edit_file")" && sudo docker compose up -d
