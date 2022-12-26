#! /bin/bash

export SOURCE_NAME=${SOURCE_NAME}
export ROCKETCHAT_VERSION=${ROCKETCHAT_VERSION:-latest}
export BUILD_HOST="$(curl -s ipinfo.io/ip):3000"

sudo curl -L https://raw.githubusercontent.com/RocketChat/install.sh/master/rocketchatctl -o /usr/local/bin/rocketchatctl
sudo chmod +x /usr/local/bin/rocketchatctl
sudo sed -i '/|| print_input_from_pipe_error_and_exit/d' /usr/local/bin/rocketchatctl
sudo rocketchatctl install --root-url=http://$BUILD_HOST --version=$ROCKETCHAT_VERSION --webserver=traefik --letsencrypt-email=MyRocketChat@DO --bind-loopback=false --use-mongo
sudo sed -E "s/^(Environment=DEPLOY_PLATFORM)=.+/\1=$SOURCE_NAME/" /lib/systemd/system/rocketchat.service -i

