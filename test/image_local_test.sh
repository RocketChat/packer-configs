#!/bin/bash

set -e
# set -o xtrace

cd "$(dirname "$0")"

function wait_http () {
  attempt_counter=0
  max_attempts=150

  until $(curl --connect-timeout 5 --output /dev/null --silent --head --fail $1); do
      if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo "Timed out waiting for rocket.chat server"
        exit 1
      fi

      echo -n '.'
      attempt_counter=$(($attempt_counter+1))
      sleep 1
  done
}

echo "Waiting for server to start on droplet"
wait_http http://$droplet_ip:3000
sleep 5

echo "Running tests on rocketchat"
./basic_test.sh http://$droplet_ip:3000

if [[ "$1" != "skip-traefik" ]]; then
  echo "Running tests on rocketchat through traefik"
  ./basic_test.sh https://$droplet_ip insecure
fi

echo "Tests passed!"