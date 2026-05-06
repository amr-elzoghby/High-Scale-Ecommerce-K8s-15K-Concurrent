# ─── Loki + Promtail Values ───────────────────────────────────────────────────
# loki-stack chart deploys both Loki (storage) and Promtail (log collector)

loki:
  enabled: true

  # Persistent storage so logs survive pod restarts
  persistence:
    enabled: true
    storageClassName: gp2
    size: 20Gi

  # Keep logs for 30 days then delete automatically
  config:
    chunk_store_config:
      max_look_back_period: 720h   # 30 days
    table_manager:
      retention_deletes_enabled: true
      retention_period: 720h

promtail:
  enabled: true
  # Promtail runs as a DaemonSet — one instance per Node
  # It automatically collects logs from all Pods on its Node
