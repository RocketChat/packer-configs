#!/bin/bash
set -e

cd /deploy 

export PKR_VAR_rocketchat_version="$INPUT_ROCKETCHAT_VERSION"
export PKR_VAR_do_token="$INPUT_DO_TOKEN"
export PKR_VAR_aws_key_id="$INPUT_AWS_KEY_ID"
export PKR_VAR_aws_secret_key="$INPUT_AWS_SECRET_KEY"

packer build rocketchat.pkr.hcl

