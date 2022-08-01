#! /bin/bash

chmod +x /tmp/deploy.sh

echo "Installing jq (deploy.sh depends)"
sudo apt install -y jq

/tmp/deploy.sh --release ${RELEASE?no version specified} --no-auth

platform="${PLATFORM?no platform specified}"
search_regex="^(DEPLOY_PLATFORM)=.*"
env_file="$HOME/rocketchat/.env"

grep -qE "$search_regex" "$env_file" && 
  sed -iE "s/$search_regex/\1=$platform/" $env_file ||
    echo "DEPLOY_PLATFORM=$platform" >> $env_file

rm -rf /tmp/deploy.sh