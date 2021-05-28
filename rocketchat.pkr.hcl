locals { 
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "rocketchat_version" {
    type    = string
    default = "latest"
}

variable "aws_key_id" {
    type    = string
}
variable "aws_secret_key" {
    type    = string
}

variable "do_token" {
    type    = string
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
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

source "digitalocean" "do-marketplace" {
  api_token     = "${var.do_token}"
  snapshot_name = "${local.image_name}"
  size          = "s-1vcpu-1gb-amd"
  region        = "nyc3"
  image         = "ubuntu-20-04-x64"
  ssh_username  = "root"
}

source "vagrant" "rocket-chat" {
  source_path = "bento/ubuntu-20.04"
  provider = "virtualbox"
  communicator = "ssh"
  add_force = true
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
    # Allow time for the instance to properly initialize after SSH is ready
    pause_before = "30s" 
    expect_disconnect = true
    inline = [
      "sudo apt-get -y update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' -y -q upgrade",
      "sudo reboot",
    ]
  }

  provisioner "file"{
    pause_before = "30s"
    source = "image_creation/motd.sh"
    destination = "/tmp/motd.sh"
  }

  provisioner "shell" {
    script = "image_creation/provision.sh"
    environment_vars = [
      "SOURCE_NAME=${source.name}",
      "BUILD_HOST=${build.Host}",
      "ROCKETCHAT_VERSION=${var.rocketchat_version}",
    ]
  }

  provisioner "shell" {
    only = ["amazon-ebs.aws-ami"]
    # Allow it to run on the 8GB free-tier instance
    inline = [
      "sudo sed -i '/^ExecStart/ s/$/ --smallfiles/' /lib/systemd/system/mongod.service", 
    ]
  }

  provisioner "shell" {
    only = ["digitalocean.do-marketplace"]
    inline = [
      "git clone https://github.com/digitalocean/marketplace-partners.git",
      "./marketplace-partners/scripts/90-cleanup.sh ",
      "./marketplace-partners/scripts/99-img-check.sh ",
      "rm -rf marketplace-partners",
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
    custom_data = {
      do_size    = "${var.do_size}"
      do_region  = "${var.do_region}"
      image_name = "${local.image_name}"
    }
  }

  post-processor "shell-local" {
    only = ["amazon-ebs.aws-ami"]
    inline = [
      "packer build -var 'image_name=${local.image_name}' -var 'aws_secret_key=${var.aws_secret_key}' -var 'aws_key_id=${var.aws_key_id}' -only amazon-ebs.aws-ami image_test/image_test.pkr.hcl",
    ]
  }

  post-processor "shell-local" {
    only = ["digitalocean.do-marketplace"]
    inline = [
      "packer build -var 'image_name=${local.image_name}' -var \"do_image_id=$(jq -r '.builds[] | select(.builder_type== \"digitalocean\")' manifest.json | jq -r '.artifact_id' | cut -d':' -f 2 )\" -var 'do_token=${var.do_token}' -only digitalocean.do-marketplace image_test/image_test.pkr.hcl",
    ]
  }
}
