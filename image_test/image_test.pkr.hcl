variable "do_token" {
    type    = string
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
variable "do_image_id" {
    type    = string
    default = ""
}
variable "aws_key_id" {
    type    = string
    default = ""
}
variable "aws_secret_key" {
    type    = string
    default = ""
}
variable "image_name" {
    type    = string
}


source "digitalocean" "do-marketplace" {
  api_token     = "${var.do_token}"
  image         = "${var.do_image_id}"
  ssh_username  = "root"
  snapshot_name = "test-${var.image_name}"
  size          = "s-1vcpu-1gb"
  region        = "nyc3"
}

source "amazon-ebs" "aws-ami" {
  access_key    = "${var.aws_key_id}"
  ami_name      = "test-${var.image_name}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  secret_key    = "${var.aws_secret_key}"
  source_ami_filter {
    filters = {
      name                = "${var.image_name}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["self"]
  }
  security_group_filter {
    filters = {
      "tag-key": "packer"
    }
  }
  ssh_username = "ubuntu"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = [
    "source.digitalocean.do-marketplace",
    "source.amazon-ebs.aws-ami",
  ]

  provisioner "shell" {
    pause_before = "10s"
    inline = [
      "sudo rocketchatctl configure --rocketchat --root-url=http://${build.Host} --bind-loopback=false",
      "sudo rocketchatctl configure --lets-encrypt --root-url=http://${build.Host} --letsencrypt-email=EMAIL --bind-loopback=false",
    ]
  }

  provisioner "shell-local" {
    script = "image_test/image_local_test.sh"
    environment_vars = [
      "droplet_ip=${build.Host}"
    ]
  }

  # ignore the test artifact
  post-processor "artifice" {
    files = ["manifest.json"]
    keep_input_artifact = false
  }
}
