module "k3s" {
  source = "xunleii/k3s/module"
  #   k3s_version              = "v1.28.11+k3s2"
  generate_ca_certificates = true
  drain_timeout            = "30s"
  global_flags = [
    "--tls-san ${alicloud_instance.master.public_ip}",
    "--token ${var.k3s_token}",
    "--write-kubeconfig-mode 644",
    "--disable=traefik",
    "--kube-controller-manager-arg bind-address=0.0.0.0",
    "--kube-proxy-arg metrics-bind-address=0.0.0.0",
    "--kube-scheduler-arg bind-address=0.0.0.0"
  ]
  k3s_install_env_vars = {}
  servers = {
    "k3s" = {
      ip = alicloud_instance.master.public_ip
      connection = {
        timeout     = "60s"
        type        = "ssh"
        host        = alicloud_instance.master.public_ip
        private_key = file(var.aliyun_key_private_pair)
        user        = "root"
      }
    }
  }
  depends_on = [alicloud_instance.master]
}


resource "null_resource" "get_k3s" {
  # 指定实例的 SSH 访问配置
  connection {
    type        = "ssh"
    user        = "root"                # 根据实际用户修改
    private_key = file(var.aliyun_key_private_pair) # SSH 私钥路径
    host        = alicloud_instance.master.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo cat /etc/rancher/k3s/k3s.yaml > /tmp/k3s.yaml",
      "sudo chown root:root /tmp/k3s.yaml",
    ]
  }
  depends_on = [module.k3s]
}


resource "null_resource" "get_k3s_token" {
  provisioner "local-exec" {
    command = <<EOT
  sleep 120;
  echo "Starting SCP for k3s.yaml...";
  scp -i ${var.aliyun_key_pair} -o StrictHostKeyChecking=no root@${alicloud_instance.master.public_ip}:/tmp/k3s.yaml ./config.yaml || exit 1;
  echo "Updating config.yaml...";
  if [ -f ./config.yaml ]; then
    sed -i '' "s/127.0.0.1/${alicloud_instance.master.public_ip}/g" ./config.yaml || exit 1;
  else
    echo "Error: ./config.yaml not found!";
    exit 1;
  fi
  EOT

  }

  depends_on = [null_resource.get_k3s]
}
