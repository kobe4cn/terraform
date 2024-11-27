module "k3s" {
  source                   = "xunleii/k3s/module"
#   k3s_version              = "v1.28.11+k3s2"
  generate_ca_certificates = true
  drain_timeout            = "30s"
  global_flags = [
    "--tls-san ${aws_instance.k3s_master.public_ip}",
    "--write-kubeconfig-mode 644",
    "--disable=traefik",
    "--kube-controller-manager-arg bind-address=0.0.0.0",
    "--kube-proxy-arg metrics-bind-address=0.0.0.0",
    "--kube-scheduler-arg bind-address=0.0.0.0"
  ]
  k3s_install_env_vars = {}

  servers = {
    "k3s" = {
      ip = aws_instance.k3s_master.public_ip
      connection = {
        timeout  = "60s"
        type     = "ssh"
        host     = aws_instance.k3s_master.public_ip
        private_key = file(var.aws_key_private)
        user     = "ec2-user"
      }
    }
  }
  depends_on = [ aws_instance.k3s_master ]
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
      "sleep 30",
      "sudo cat /var/lib/rancher/k3s/server/node-token > /tmp/node-token",
      "sudo cat /etc/rancher/k3s/k3s.yaml > /tmp/k3s.yaml",
      "sudo cat /var/lib/rancher/k3s/server/tls/server-ca.crt > /tmp/ca.crt",
      "sudo chown ec2-user:ec2-user /tmp/k3s.yaml",
      "sudo chown ec2-user:ec2-user /tmp/node-token",
      "sudo chown ec2-user:ec2-user /tmp/ca.crt",
    ]
  }
  depends_on = [module.k3s]
}
resource "null_resource" "get_k3s_token" {
  provisioner "local-exec" {
    command = <<EOT
  sleep 30;
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

  depends_on = [module.k3s, null_resource.get_k3s]
}