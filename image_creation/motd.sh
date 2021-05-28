#!/bin/bash

printf "##################################################################################################################################################################
Rocket.Chat is the leading open source team chat software solution. Free, unlimited and completely customizable with on-premises and SaaS cloud hosting.
Replace email, HipChat & Slack with the ultimate team chat software solution.

To configure your Rocket.Chat service and traefik loadbalancer with your public domain (ROOT_URL) run:

  rocketchatctl configure --lets-encrypt --root-url=ROOT_URL --letsencrypt-email=EMAIL
  example: # rocketchatctl configure --lets-encrypt --root-url=https://myrocketchatserver.org --letsencrypt-email=myemail@example.org
  
Keep your RocketChat server updated using rocketchatctl update. Run rocketchatctl -h to see the full list of available options.
  
In case you do not own a public domain, you could use the public IP of your droplet, but traefik will not be able to fetch certificates for you so you will see a privacy alert message when loading https://droplet-IP
 
Looking for how to use Rocket.Chat? Be sure to check our docs: https://rocket.chat/docs
Need some help? Join our community forums https://forums.rocket.chat
##################################################################################################################################################################
"