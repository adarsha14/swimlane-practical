output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "master_private_ip" {
  description = "Private IP of the Kubernetes master node"
  value       = aws_instance.master.private_ip
}

output "worker_private_ip" {
  description = "Private IP of the Kubernetes worker node"
  value       = aws_instance.worker.private_ip
}
