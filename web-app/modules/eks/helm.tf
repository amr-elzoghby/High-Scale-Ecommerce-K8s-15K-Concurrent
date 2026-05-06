# ─── Metrics Server ───────────────────────────────────────────────────────────
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  values = [
    file("${path.module}/templates/metrics-server-values.yaml.tpl")
  ]
}

# ─── Cluster Autoscaler ───────────────────────────────────────────────────────
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"

  values = [
    templatefile("${path.module}/templates/cluster-autoscaler-values.yaml.tpl", {
      cluster_name = aws_eks_cluster.main.name
      aws_region   = var.aws_region
      role_arn     = module.cluster_autoscaler_irsa_role.iam_role_arn
    })
  ]
}
