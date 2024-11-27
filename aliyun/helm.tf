resource "helm_release" "argo_cd" {

  depends_on = [null_resource.get_k3s_token]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  timeout = 600
  create_namespace = true
}

resource "helm_release" "crossplane" {
  depends_on = [null_resource.get_k3s_token]
  name       = "crossplane"
  repository = "https://charts.crossplane.io/stable"
  chart      = "crossplane"
  namespace  = "crossplane"
  timeout = 600
  create_namespace = true
  
}

#获取argocd 默认密码
# kubectl \
#     --namespace argocd \
#     get secret argocd-initial-admin-secret \
#     --output jsonpath="{.data.password}" \
#     | base64 --decode
