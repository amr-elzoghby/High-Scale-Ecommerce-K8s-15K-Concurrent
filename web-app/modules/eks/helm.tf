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

# ─── Prometheus + Grafana + AlertManager ─────────────────────────────────────
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/prometheus-values.yaml.tpl", {
      grafana_password = data.aws_secretsmanager_secret_version.grafana.secret_string
    })
  ]

  depends_on = [
    aws_eks_addon.ebs_csi_driver
  ]
}

# ─── Loki + Promtail ─────────────────────────────────────────────────────────
resource "helm_release" "loki" {
  name             = "loki-stack"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/templates/loki-values.yaml.tpl")
  ]

  depends_on = [
    aws_eks_addon.ebs_csi_driver
  ]
}
