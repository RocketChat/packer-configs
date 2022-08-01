#! /bin/bash

chmod +x /tmp/deploy.sh

/tmp/deploy.sh --version ${VERSION?no version specified}

platform="${PLATFORM?no platform specified}"
search_regex="^(DEPLOY_PLATFORM)=.*"
env_file="$HOME/rocketchat/.env"

grep -qE "$search_regex" "$env_file" && 
  sed -iE "s/$search_regex/\1=$platform/" $env_file ||
    echo "DEPLOY_PLATFORM=$platform" >> $env_file

rm -rf /tmp/deploy.sh