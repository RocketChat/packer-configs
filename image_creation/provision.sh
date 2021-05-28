#!/bin/bash

echo "Installing Rocket.Chat and dependencies through rocketchatctl for platform $SOURCE_NAME"
sudo curl -L https://install.rocket.chat/rocketchatctl -o /usr/local/bin/rocketchatctl
sudo chmod +x /usr/local/bin/rocketchatctl
sudo sed -i '/&& print_input_from_pipe_error_and_exit/d' /usr/local/bin/rocketchatctl
sudo rocketchatctl install --root-url=https://$BUILD_HOST --version=$ROCKETCHAT_VERSION --webserver=traefik --letsencrypt-email=MyRocketChat@DO --mongo-version=4.0.3 --bind-loopback=false --install-node --use-mongo
sudo sed -i "/User=rocketchat/a Environment=DEPLOY_PLATFORM=$SOURCE_NAME" /lib/systemd/system/rocketchat.service
mongo rocketchat --eval 'db.rocketchat_settings.deleteOne({ _id: "uniqueID" })'

echo "Updating motd"
ls /tmp
sudo mv /tmp/motd.sh /etc/update-motd.d/99-image-readme
sudo chmod 755 /etc/update-motd.d/99-image-readme
sudo sed -i 's/^PrintMotd no/PrintMotd yes/' /etc/ssh/sshd_config
sudo touch /etc/motd.tail

echo "Setting ufw rules"
sudo apt-get -y install ufw
sudo ufw allow ssh
sudo ufw allow 3000/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing
yes | sudo ufw enable

echo "Cleaning up"
sudo rm -rf /tmp/* /var/tmp/*
unset HISTFILE
rm -rf ~/.bash_history
sudo apt-get -y autoremove
sudo apt-get -y clean
sudo apt-get -y autoclean
sudo find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
sudo rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
sudo rm -rf /var/lib/cloud/instances/*
sudo truncate -s 0 /var/log/lastlog
sudo truncate -s 0 /var/log/wtmp
sudo truncate -s 0 /var/log/kern.log
sudo truncate -s 0 /var/log/ufw.log
sudo truncate -s 0 /var/log/auth.log
sudo truncate -s 0 /var/log/apport.log
sudo rm -f /root/.ssh/authorized_keys /etc/ssh/*key*
