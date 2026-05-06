# ─── Loki + Promtail Values ───────────────────────────────────────────────────


loki:
  enabled: true 
  persistence:
    enabled: true
    storageClassName: gp2
    size: 20Gi

  config:
    chunk_store_config:
      max_look_back_period: 720h 
    table_manager:
      retention_deletes_enabled: true
      retention_period: 720h

promtail:
  enabled: true
  # Promtail runs as a DaemonSet — one instance per Node
  # It automatically collects logs from all Pods on its Node
