# ─── Prometheus + Grafana + AlertManager Values ───────────────────────────────
# Deployed via kube-prometheus-stack (single chart for all three components)

grafana:
  adminPassword: "${grafana_password}"
  additionalDataSources:
    - name: Loki
      type: loki
      url: http://loki-stack:3100
      access: proxy
      isDefault: false

prometheus:
  prometheusSpec:
    # Retain metrics for 30 days
    retention: 30d

    # Persistent storage so metrics survive pod restarts
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

alertmanager:
  alertmanagerSpec:
    # Persistent storage for alert history
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi
