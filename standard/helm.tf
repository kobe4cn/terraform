resource "helm_release" "argo_cd" {

  depends_on = [null_resource.get_k3s_token, aws_instance.k3s_worker, local_sensitive_file.kubeconfig, null_resource.get_k3s]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  timeout = 600
  create_namespace = true
}
