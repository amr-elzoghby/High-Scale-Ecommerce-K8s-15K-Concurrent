# Falco Module Main Configuration
resource "helm_release" "falco" {
  name             = "falco-${var.environment}"
  repository       = "https://falcosecurity.github.io/charts"
  chart            = "falco"
  namespace        = "falco"
  create_namespace = true
  wait             = true

  values = [
    yamlencode({
      falcosidekick = {
        enabled = true
        config = {
          slack = {
            webhookurl = var.slack_webhook_url
          }
        }
      }
    })
  ]
}
