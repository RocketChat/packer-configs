FROM hashicorp/packer:1.7.2

RUN apk add sudo curl wget openssh jq

COPY . /deploy

WORKDIR /deploy

ENTRYPOINT ["bash", "/deploy/entrypoint.sh"]