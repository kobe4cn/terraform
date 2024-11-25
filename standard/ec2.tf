# Provider 配置
provider "aws" {
  region = var.aws_region
}
resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
  public_key = file(var.aws_key_pair) # 替换为你的公钥路径
}
# # 定义 Internet 网关
# resource "aws_internet_gateway" "my_igw" {
#   vpc_id = module.vpc.vpc_id

#   tags = {
#     Name = "MyInternetGateway"
#   }
# }


# 定义路由表
# resource "aws_route_table" "my_route_table" {
#   vpc_id = module.vpc.vpc_id

#   route {
#     cidr_block = "0.0.0.0/0"
#     # gateway_id = aws_internet_gateway.my_igw.id
#   }

#   tags = {
#     Name = "MyRouteTable"
#   }
# }

# 确保有默认路由到互联网网关
# resource "aws_route" "public_internet_gateway" {
#   route_table_id         = module.vpc.public_route_table_ids[0]
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = module.vpc.igw_id

#   depends_on = [module.vpc]
# }
#重要：添加路由表关联
# resource "aws_route_table_association" "public_subnet_association" {
#   subnet_id      = module.vpc.public_subnets[0]
#   route_table_id = aws_route_table.my_route_table.id
# }

# EC2 Instance for K3s Master Node
resource "aws_instance" "k3s_master" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.my_key.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true # 确保分配外网 IP
  #   iam_instance_profile = aws_iam_instance_profile.k3s_profile.name

  tags = {
    Name = "k3s-master"
  }

  #   user_data = <<-EOT
  #     #!/bin/bash
  #     curl -sfL https://get.k3s.io | sh -
  #     sleep 30
  #     cat /var/lib/rancher/k3s/server/node-token > /tmp/node-token
  #     cat /etc/rancher/k3s/k3s.yaml > /tmp/k3s.yaml
  #     cat /var/lib/rancher/k3s/server/tls/server-ca.crt > /tmp/ca.crt
  #     sudo chown ec2-user:ec2-user /tmp/k3s.yaml
  #     sudo chown ec2-user:ec2-user /tmp/node-token
  #     sudo chown ec2-user:ec2-user /tmp/ca.crt

  #   EOT

  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  #   provisioner "local-exec" {
  #     command = "scp -i ${var.aws_key_pair} -o StrictHostKeyChecking=no ec2-user@${self.public_ip}:/tmp/node-token ${path.module}/node-token; scp  -i ${var.aws_key_pair} -o StrictHostKeyChecking=no ec2-user@${aws_instance.k3s_master.public_ip}:/tmp/k3s.yaml ${path.module}/k3s.yaml;"

  #   }

}
resource "null_resource" "get_k3s" {
  # 指定实例的 SSH 访问配置
  connection {
    type        = "ssh"
    user        = "ec2-user"                # 根据实际用户修改
    private_key = file(var.aws_key_private) # SSH 私钥路径
    host        = aws_instance.k3s_master.public_ip
  }
  provisioner "remote-exec" {
    inline = [

      "curl -sfL https://get.k3s.io | sh -s - --tls-san ${aws_instance.k3s_master.public_ip}",
      "sleep 30",
      "sudo cat /var/lib/rancher/k3s/server/node-token > /tmp/node-token",
      "sudo cat /etc/rancher/k3s/k3s.yaml > /tmp/k3s.yaml",
      "sudo cat /var/lib/rancher/k3s/server/tls/server-ca.crt > /tmp/ca.crt",
      "sudo chown ec2-user:ec2-user /tmp/k3s.yaml",
      "sudo chown ec2-user:ec2-user /tmp/node-token",
      "sudo chown ec2-user:ec2-user /tmp/ca.crt",
    ]
  }
  depends_on = [aws_instance.k3s_master]
}
resource "null_resource" "get_k3s_token" {
  provisioner "local-exec" {
    # command = "sleep 60; scp -i ${var.aws_key_pair} -o StrictHostKeyChecking=no ec2-user@${aws_instance.k3s_master.public_ip}:/tmp/node-token ./node-token; scp  -i ${var.aws_key_pair} -o StrictHostKeyChecking=no ec2-user@${aws_instance.k3s_master.public_ip}:/tmp/k3s.yaml ./k3s.yaml; sed -i 's/127.0.0.1/${aws_instance.k3s_master.public_ip}/g' ./node-token;"

    command = <<EOT
  sleep 120;
  echo "Starting SCP for node-token...";
  scp -i ${var.aws_key_pair} -o StrictHostKeyChecking=no ec2-user@${aws_instance.k3s_master.public_ip}:/tmp/node-token ./node-token || exit 1;
  echo "Starting SCP for k3s.yaml...";
  scp -i ${var.aws_key_pair} -o StrictHostKeyChecking=no ec2-user@${aws_instance.k3s_master.public_ip}:/tmp/k3s.yaml ./config.yaml || exit 1;
  echo "Starting SCP for ca.crt...";
  scp -i ${var.aws_key_pair} -o StrictHostKeyChecking=no ec2-user@${aws_instance.k3s_master.public_ip}:/tmp/ca.crt ./ca.crt || exit 1;
  echo "Updating config.yaml...";
  if [ -f ./config.yaml ]; then
    sed -i '' "s/127.0.0.1/${aws_instance.k3s_master.public_ip}/g" ./config.yaml || exit 1;
  else
    echo "Error: ./config.yaml not found!";
    exit 1;
  fi
  EOT

  }

  depends_on = [aws_instance.k3s_master, null_resource.get_k3s]
}
# EC2 Instances for K3s Worker Nodes
resource "aws_instance" "k3s_worker" {
  count         = var.worker_count
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.my_key.key_name
  subnet_id     = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]

  tags = {
    Name = "k3s-worker-${count.index}"
  }

  user_data = <<-EOT
    #!/bin/bash
    sleep 30
    scp -i ${var.aws_key_pair} -o StrictHostKeyChecking=no ec2-user@${aws_instance.k3s_master.public_ip}:/tmp/node-token /tmp/node-token
    curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_master.public_ip}:6443 K3S_TOKEN=`cat /tmp/node-token` sh -
  EOT

  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  depends_on = [aws_instance.k3s_master, null_resource.get_k3s_token]
}

resource "local_sensitive_file" "kubeconfig" {

  #   apiVersion: v1
  #   clusters:
  #   - cluster:
  #       server: https://${aws_instance.k3s_master.public_ip}:6443
  #       certificate-authority-data: ${base64encode(file("${path.module}/ca.crt"))}
  #     name: k3s-cluster
  #   contexts:
  #   - context:
  #       cluster: k3s-cluster
  #       user: admin
  #     name: k3s-context
  #   current-context: k3s-context
  #   kind: Config
  #   preferences: {}
  #   users:
  #   - name: admin
  #     user:
  #       token: ${file("${path.module}/node-token")}
  content    = file("${path.module}/config.yaml")
  filename   = "${path.module}/k3s.yaml"
  depends_on = [aws_instance.k3s_master, null_resource.get_k3s_token, aws_instance.k3s_worker]
}

# Security Group
resource "aws_security_group" "k3s_sg" {
  name_prefix = "k3s-sg-"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


