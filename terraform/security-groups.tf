resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion"
  description = "Allow SSH and NodePort access to bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP (Nginx reverse proxy)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort services (forwarded to K8s nodes)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.cluster_name}-bastion"
    Project   = var.cluster_name
    Terraform = "true"
  }
}

resource "aws_security_group" "k8s_common" {
  name        = "${var.cluster_name}-common"
  description = "Common rules for all Kubernetes nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "NodePort services from bastion"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "All traffic within the cluster"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.cluster_name}-common"
    Project   = var.cluster_name
    Terraform = "true"
  }
}

resource "aws_security_group" "k8s_master" {
  name        = "${var.cluster_name}-master"
  description = "Additional rules for the Kubernetes master node"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Kubernetes API server from bastion"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  tags = {
    Name      = "${var.cluster_name}-master"
    Project   = var.cluster_name
    Terraform = "true"
  }
}
