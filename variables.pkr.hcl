locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "rocketchat_release" {
  type    = string
  default = "latest"
}

variable "aws_key_id" {
  type = string
  default = ""
}
variable "aws_secret_key" {
  type = string
  default = ""
}

variable "do_token" {
  type = string
  default = ""
}
variable "do_size" {
  type    = string
  default = "s-1vcpu-1gb"
}
variable "do_region" {
  type    = string
  default = "nyc3"
}

locals {
  image_name = "rocket-chat-${var.rocketchat_version}-${local.timestamp}"
}