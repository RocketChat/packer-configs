locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "rocketchat_version" {
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

source "amazon-ebs" "aws-ami" {
  access_key    = "${var.aws_key_id}"
  ami_name      = "${local.image_name}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  secret_key    = "${var.aws_secret_key}"
  source_ami    = "ami-04505e74c0741db8d"
  ssh_username  = "ubuntu"
}

source "digitalocean" "do-marketplace" {
  api_token     = "${var.do_token}"
  snapshot_name = "${local.image_name}"
  size          = "s-1vcpu-1gb-amd"
  region        = "blr1"
  image         = "ubuntu-20-04-x64"
  ssh_username  = "root"
}

build {
  sources = [
    "source.digitalocean.do-marketplace",
    "source.amazon-ebs.aws-ami",
  ]

  # remove old manifests if they exist
  provisioner "shell-local" {
    inline = [
      "rm -rf manifest.json",
    ]
  }

  provisioner "shell" {
    pause_before      = "30s"
    expect_disconnect = true
    inline = [
      "sudo apt-get update -qqq",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get -y upgrade",
      "sudo reboot",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo dd if=/dev/zero of=/swapfile count=512 bs=1M",
      "sudo chmod 600 /swapfile",
      "sudo mkswap /swapfile",
      "sudo swapon /swapfile",
      "echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null"
    ]
    expect_disconnect = true // thanks aws . for some reason at swap creation step the connection gets frequently dropped
  }

  provisioner "file" {
    source      = "./scripts/motd.sh"
    destination = "/tmp/motd.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv -v /tmp/motd.sh /etc/update-motd.d/99-image-readme",
      "sudo chmod 755 /etc/update-motd.d/99-image-readme",
      "sudo sed -i 's/^PrintMotd no/PrintMotd yes/' /etc/ssh/sshd_config",
      "sudo touch /etc/motd.tail",
    ]
  }

  provisioner "file" {
    source = "./scripts/01-start-containers.sh"
    destination  = "/tmp/01-start-containers.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv -v /tmp/01-start-containers.sh /var/lib/cloud/scripts/per-instance/01-start-containers.sh",
      "sudo chmod a+x /var/lib/cloud/scripts/per-instance/01-start-containers.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "DEBIAN_FRONTEND=noninteractive sudo apt-get update",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y ufw",
      "bash -c 'for allow in ssh 3000/tcp 80/tcp 443/tcp; do sudo ufw allow $allow; done'",
      "sudo ufw default deny incoming",
      "sudo ufw default allow outgoing",
      "bash -c 'yes | sudo ufw enable'"
    ]
  }

  provisioner "shell" {
    inline = [
      "bash -c 'if [[ -e /etc/machine-id ]]; then sudo rm -f /etc/machine-id && sudo touch /etc/machine-id; fi'",
      "bash -c 'if [[ -e /var/lib/dbus/machine-id && ! -L /var/lib/dbus/machine-id ]]; then sudo rm -f /var/lib/dbus/machine-id; fi'"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo curl https://get.docker.com | sh",
      "sudo mkdir rocketchat",
      "sudo curl -O https://raw.githubusercontent.com/RocketChat/Docker.Official.Image/master/compose.yml",
      "bash -c 'cd rocketchat && sudo docker compose pull'"
    ]
  }

  # DigitalOcean cleanup script (fancy and fun for all builds)
  provisioner "shell" {
    inline = ["wget -O- https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/90-cleanup.sh | sudo bash"]
  }

  # Things that the previous script doesn't handle
  provisioner "shell" {
    only = ["digitalocean.do-marketplace"]
    inline = [
      "sudo rm -rf /root/.ssh",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get purge droplet-agent -y"
    ]
  }

  provisioner "shell" {
    only = ["amazon-ebs.aws-ami"]
    inline = [
      "sudo rm -rf /home/ubuntu/.ssh"
    ]
  }

  # Makes sure the images are clean
  provisioner "shell" {
    inline = ["wget -O- https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/99-img-check.sh | sudo bash || true"]
  }

  // post-processor "manifest" {
  //   only       = ["digitalocean.do-marketplace"]
  //   output     = "manifest.json"
  //   strip_path = true
  //   custom_data = {
  //     do_size    = "${var.do_size}"
  //     do_region  = "${var.do_region}"
  //     image_name = "${local.image_name}"
  //   }
  // }

  // post-processor "shell-local" {
  //   only = ["amazon-ebs.aws-ami"]
  //   inline = [
  //     "packer build -var 'image_name=${local.image_name}' -var 'aws_secret_key=${var.aws_secret_key}' -var 'aws_key_id=${var.aws_key_id}' -only amazon-ebs.aws-ami image_test/image_test.pkr.hcl",
  //   ]
  // }

  // post-processor "shell-local" {
  //   only = ["digitalocean.do-marketplace"]
  //   inline = [
  //     "packer build -var 'image_name=${local.image_name}' -var \"do_image_id=$(jq -r '.builds[] | select(.builder_type== \"digitalocean\")' manifest.json | jq -r '.artifact_id' | cut -d':' -f 2 )\" -var 'do_token=${var.do_token}' -only digitalocean.do-marketplace image_test/image_test.pkr.hcl",
  //   ]
  // }
}
