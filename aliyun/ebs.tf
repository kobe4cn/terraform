resource "alicloud_ecs_disk" "ebs" {
  zone_id     = data.alicloud_zones.default.zones.0.id
  disk_name   = var.name
  description = "terraform-k3s"
  category    = "cloud_essd_entry"
  size        = "40"
 
  tags = {
    Name = "terraform-k3s"
  }
}

