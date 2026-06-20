output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "API endpoint of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider (used for pod IAM roles)"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "node_group_role_arn" {
  description = "IAM role ARN of the worker nodes"
  value       = aws_iam_role.eks_nodes.arn
}

output "karpenter_irsa_role_arn" {
  description = "IRSA role ARN for the Karpenter controller"
  value       = module.karpenter.iam_role_arn
}

output "karpenter_queue_name" {
  description = "SQS queue name for Karpenter Spot interruption handling"
  value       = module.karpenter.queue_name
}
