#!/bin/bash

url="http://$(curl -s ipinfo.io/ip):3000"
sed -E "s@^Environment=ROOT_URL=.+@Environment=ROOT_URL=$url@" /lib/systemd/system/rocketchat.service -i
# the following is not good, only was used as a temporary fix
# keeping here to keep track of it
# sed -E "/^Environment=ROOT_URL=.+$/a Environment=OVERWRITE_SETTING_Site_Url=$url" /lib/systemd/system/rocketchat.service -i
systemctl daemon-reload
# because I'm not sure whether the server alreay started when this script is being run or not
if [ "$(systemctl is-active rocketchat)" = "active" ]; then
	systemctl restart rocketchat
else
	systemctl start rocketchat
fi
