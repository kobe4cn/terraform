# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name                 = "k3s-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets      = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  # 启用 DNS 支持
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # 为公共子网启用自动分配公共 IP
  map_public_ip_on_launch = true
#   public_subnet_tags = {
#     "kubernetes.io/role/elb" = "1"
#     "Type"                   = "public"
#   }
  
#   private_subnet_tags = {
#     "kubernetes.io/role/internal-elb" = "1"
#     "Type"                           = "private"
#   }
}