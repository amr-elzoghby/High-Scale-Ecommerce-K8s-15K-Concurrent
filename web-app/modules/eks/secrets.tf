# ─── Grafana Admin Password (from AWS Secrets Manager) ───────────────────────
# Secret must be created manually once before terraform apply:
# aws secretsmanager create-secret \
#   --name "${name_prefix}/grafana-admin-password" \
#   --secret-string "YourStrongPassword" \
#   --region us-east-1

data "aws_secretsmanager_secret_version" "grafana" {
  secret_id = "${var.name_prefix}/grafana-admin-password"
}
