provider "alicloud" {
  access_key = var.aliyun_access_key
  secret_key = var.aliyun_secret_key
  # If not set, cn-beijing will be used.
  region = var.region
}
data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "vpc" {
  vpc_name   = var.name
  cidr_block = "172.16.0.0/12"
}
#配置弹性 IP 供 NAT 网关使用
resource "alicloud_eip" "nat_eip" {
  bandwidth            = "10"
  internet_charge_type = "PayByBandwidth"
}
resource "alicloud_eip_association" "nat_association" {
  allocation_id = alicloud_eip.nat_eip.id
  instance_id   = alicloud_nat_gateway.nat.id
}
resource "alicloud_vswitch" "vsw" {
  vpc_id     = alicloud_vpc.vpc.id
  cidr_block = "172.16.0.0/21"
  zone_id    = data.alicloud_zones.default.zones[0].id
  depends_on = [alicloud_vpc.vpc]

}
#创建 NAT 网关
resource "alicloud_nat_gateway" "nat" {
  vpc_id = alicloud_vpc.vpc.id
  #   spec       = "Small"
  payment_type     = "PayAsYouGo"
  nat_gateway_name = "${var.name}-nat-gateway"
  vswitch_id = alicloud_vswitch.vsw.id
  nat_type     = "Enhanced"
}
#添加 SNAT 规则
resource "alicloud_snat_entry" "worker_snat" {
  snat_table_id     = alicloud_nat_gateway.nat.snat_table_ids
  source_vswitch_id = alicloud_vswitch.vsw.id
  snat_ip           = alicloud_eip.nat_eip.ip_address
  depends_on = [alicloud_nat_gateway.nat]
}

resource "alicloud_security_group" "default" {
  name   = var.name
  vpc_id = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.default.id
  cidr_ip           = "0.0.0.0/0"
}
resource "alicloud_key_pair" "publickey" {
  key_pair_name = var.name
  public_key    = file(var.aliyun_key_pair)
}

resource "alicloud_instance" "master" {
  # cn-hongkong
  availability_zone = data.alicloud_zones.default.zones.0.id
  security_groups   = alicloud_security_group.default.*.id
  # series III
  instance_type              = var.instance_type
  instance_charge_type       = "PostPaid"
  system_disk_category       = "cloud_essd_entry"
  system_disk_size           = 40
  image_id                   = var.image_id
  instance_name              = "k3s-master"
  vswitch_id                 = alicloud_vswitch.vsw.id
  internet_max_bandwidth_out = 10
  key_name                   = alicloud_key_pair.publickey.key_pair_name
#   user_data                  = <<-EOT
# #!/bin/bash
#     curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --flannel-backend none --token ${var.k3s_token}
#     cat /etc/rancher/k3s/k3s.yaml > /tmp/k3s.yaml
#   EOT

}



resource "alicloud_instance" "worker" {
  count             = var.worker_count
  availability_zone = data.alicloud_zones.default.zones.0.id
  security_groups   = alicloud_security_group.default.*.id
  # series III
  instance_type              = var.instance_type
  instance_charge_type       = "PostPaid"
  system_disk_category       = "cloud_essd_entry"
  system_disk_size           = 40
  image_id                   = var.image_id
  instance_name              = "k3s-worker-${count.index}"
  vswitch_id                 = alicloud_vswitch.vsw.id
  internet_max_bandwidth_out = 0
  key_name                   = alicloud_key_pair.publickey.key_pair_name
  user_data                  = <<-EOT
#!/bin/bash
    curl -sfL https://get.k3s.io | K3S_URL=https://${alicloud_instance.master.public_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s -
  EOT
  depends_on                 = [module.k3s]
}







