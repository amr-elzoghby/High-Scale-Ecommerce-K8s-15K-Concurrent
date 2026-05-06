# Cluster Autoscaler Values
# Dynamic values are injected by Terraform's templatefile() function at apply time.

# Target EKS cluster for auto-discovery
autoDiscovery:
  clusterName: "${cluster_name}"

# AWS region where the cluster resides
awsRegion: "${aws_region}"

# Service Account with IRSA annotation for AWS permissions
rbac:
  serviceAccount:
    name: cluster-autoscaler
    annotations:
      eks.amazonaws.com/role-arn: "${role_arn}"

# Scaling behavior tuning
extraArgs:
  scale-down-delay-after-add: "5m"
  scale-down-unneeded-time: "5m"
  scale-down-utilization-threshold: "0.5"
