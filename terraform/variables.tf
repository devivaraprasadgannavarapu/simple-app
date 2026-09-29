variable "aws_region" {
  description = "AWS region for the platform"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile used by Terraform"
  type        = string
  default     = "dvp"
}

variable "project_name" {
  description = "Name used for AWS resources"
  type        = string
  default     = "sample-app"
}

variable "cluster_version" {
  description = "Kubernetes minor version used by kubeadm"
  type        = string
  default     = "1.33"
}

variable "ssh_key_name" {
  description = "Existing EC2 key pair name used to access the nodes"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to the nodes"
  type        = string
}

variable "kubernetes_api_allowed_cidr" {
  description = "CIDR allowed to reach the Kubernetes API on the control plane"
  type        = string
  default     = "10.0.0.0/16"
}
