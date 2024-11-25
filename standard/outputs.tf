output "master_ip" {
  value = aws_instance.k3s_master.public_ip
}

output "worker_ips" {
  value = aws_instance.k3s_worker.*.public_ip
}

output "argo_cd_url" {
  value = "http://${aws_instance.k3s_master.public_ip}:8080"
}

# output "k3s_token" {
#   value = file("./node-token")

# }
