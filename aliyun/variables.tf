variable "aliyun_access_key" {
  description = "Aliyun Access Key"
  type        = string
  
  
}
variable "aliyun_secret_key" {
    description = "Aliyun Secret Key"
    type        = string
    
}   



variable "name" {
  default = "terraform-k3s-argocd"
}

variable "region" {
  default = "cn-hongkong"
}

variable "instance_type" {
  default = "ecs.e-c1m2.large"
  
}
variable "image_id" {
  default = "ubuntu_22_04_x64_20G_alibase_20241016.vhd"
  
}

variable "k3s_token" {
  description = "The K3S token for joining worker nodes"
  type        = string
  default     = "aliyunterraform"
}

variable "aliyun_key_pair" {
  description = "The name of the key pair to create."
  default     = "~/.ssh/id_ed25519.pub"
}

variable "aliyun_key_private_pair" {
  description = "The name of the key pair to create."
  default     = "~/.ssh/id_ed25519"
}

variable "worker_count" {
  description = "K3s Worker 节点数量"
  type        = number
  default     = 2
}






