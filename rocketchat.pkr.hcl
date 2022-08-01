source "amazon-ebs" "aws-ami" {
  access_key    = "${var.aws_key_id}"
  ami_name      = "${local.image_name}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  secret_key    = "${var.aws_secret_key}"
  /** TODO change this hardcode */
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
      "sudo apt update -qqq",
      "DEBIAN_FRONTEND=noninteractive sudo apt -y -qqq upgrade",
      "sudo reboot",
    ]
  }

  provisioner "shell" {
    script = "./scripts/swap.sh"
  }

  provisioner "file" {
    pause_before = "30s"
    source       = "./scripts/01-set-root-url.sh"
    destination  = "/tmp/01-set-root-url.sh"
  }


  provisioner "shell" {
    inline = [
      "sudo mv -v /tmp/01-set-root-url.sh /var/lib/cloud/scripts/per-instance/01-set-root-url.sh"
    ]
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
    source       = "./scripts/docker-deploy.sh"
    destination  = "/tmp/deploy.sh"
  }

  provisioner "shell" {
    script = "./scripts/provision.sh"
    environment_vars = [
      "PLATFORM=${source.name}",
      "VERSION=${var.rocketchat_version}",
    ]
  }

  provisioner "shell" {
    script = "./scripts/firewall.sh"
  }

  provisioner "shell" {
    pause_before = "10s"
    script = "./scripts/remove_machine_id.sh"
  }

  provisioner "shell" {
    script = "./scripts/extra.sh"
  }

  post-processor "manifest" {
    only       = ["digitalocean.do-marketplace"]
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      do_size    = "${var.do_size}"
      do_region  = "${var.do_region}"
      image_name = "${local.image_name}"
    }
  }

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
