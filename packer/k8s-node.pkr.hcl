packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

source "amazon-ebs" "k8s-node" {
  ami_name      = "k8s-node-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username = "ubuntu"

  tags = {
    Name    = "k8s-node"
    Project = "devops-practical"
    Builder = "packer"
  }
}

build {
  sources = ["source.amazon-ebs.k8s-node"]

  provisioner "ansible" {
    playbook_file = "../ansible/packer-playbook.yml"
    user          = "ubuntu"
  }
}
