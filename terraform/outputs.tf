output "ecr_repository_url" {
  description = "Push Docker images to this ECR repository"
  value       = module.ecr.repository_url
}

output "control_plane_public_ip" {
  description = "Public IP used by Jenkins SSH deployment commands"
  value       = aws_instance.control_plane.public_ip
}

output "control_plane_private_ip" {
  description = "Private IP used for cluster-internal communication"
  value       = aws_instance.control_plane.private_ip
}

output "control_plane_instance_id" {
  description = "Instance ID used by Jenkins for SSM deployments"
  value       = aws_instance.control_plane.id
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_agent_private_ips" {
  description = "Private IPs of the Docker and SonarQube Jenkins agents"
  value       = aws_instance.jenkins_agent[*].private_ip
}

output "worker_public_ips" {
  description = "Public IPs of the two kubeadm workers"
  value       = aws_instance.worker[*].public_ip
}

output "aws_region" {
  description = "AWS region used by the deployment"
  value       = var.aws_region
}
