
variable "aws_key_pair" {
  description = "The name of the key pair to create."
  default     = "~/.ssh/id_ed25519.pub"
}
variable "aws_key_private" {
  description = "The name of the key pair to create."
  default     = "~/.ssh/id_ed25519"
}

variable "aws_region" {
  description = "AWS 区域"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "实例类型"
  type        = string
  default     = "t2.micro"
}

variable "ami" {
  description = "AMI ID"
  type        = string
  default     = "ami-012967cc5a8c9f891"
}

variable "worker_count" {
  description = "K3s Worker 节点数量"
  type        = number
  default     = 2
}
variable "k3s_token" {
  description = "The K3S token for joining worker nodes"
  type        = string
  default     = "./node-token"
}
