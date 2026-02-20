data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  node_ami = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion.id]

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name      = "${var.cluster_name}-bastion"
    Role      = "bastion"
    Project   = var.cluster_name
    Terraform = "true"
  }
}

resource "aws_instance" "master" {
  ami                    = local.node_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.k8s_common.id, aws_security_group.k8s_master.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name      = "${var.cluster_name}-master"
    Role      = "master"
    Project   = var.cluster_name
    Terraform = "true"
  }
}

resource "aws_instance" "worker" {
  ami                    = local.node_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = module.vpc.private_subnets[1]
  vpc_security_group_ids = [aws_security_group.k8s_common.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name      = "${var.cluster_name}-worker"
    Role      = "worker"
    Project   = var.cluster_name
    Terraform = "true"
  }
}
