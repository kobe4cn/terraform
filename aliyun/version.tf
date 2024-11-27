terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = "1.235.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
  }
}
provider "helm" {
  kubernetes {
    config_path = "${path.module}/config.yaml"
    # insecure-skip-tls-verify = true
    # insecure    = true
  }
}