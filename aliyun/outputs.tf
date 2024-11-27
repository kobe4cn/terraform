output "public_ip" {
    value = alicloud_instance.master.public_ip
}

output "argo_cd_url" {
  value = "http://${alicloud_instance.master.public_ip}:8080"
}