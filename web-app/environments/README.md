# Infrastructure Deployment Guide

This directory contains layered Terraform configurations for `dev` and `prod` environments.  
Each layer has its own **isolated state** in S3 to minimize blast radius.

## Structure

```
environments/
├── dev/
│   ├── network/    # VPC, Subnets, Security Groups, VPC Endpoints
│   ├── storage/    # S3 Buckets (app data, logs)
│   └── eks/        # EKS Cluster + Helm stack (Metrics Server, Autoscaler, Monitoring)
└── prod/
    ├── network/
    ├── storage/
    └── eks/
```

---

## Deployment Order (REQUIRED)

> ⚠️ Each layer reads outputs from the previous layer via `terraform_remote_state`. Apply in order.

```bash
# Step 1 — Network
cd environments/prod/network
terraform init && terraform apply

# Step 2 — Storage (optional if not using S3 for app data)
cd ../storage
terraform init && terraform apply

# Step 3 — EKS + Full Observability Stack
cd ../eks
terraform init && terraform apply
# ⏱️ ~20 minutes (node groups + Helm releases)
```

---

## What Gets Deployed in the EKS Layer

| Resource | Details |
|:---|:---|
| EKS Cluster | Kubernetes 1.30, Private API endpoint |
| `workers-stable` | On-Demand nodes (`m7i-flex.large`, 8GB) — for databases |
| `workers-spot` | Spot nodes (`c7i-flex.large`, 4GB) — for microservices |
| Metrics Server | Helm — required for HPA |
| Cluster Autoscaler | Helm + IRSA — auto-provisions Spot EC2 nodes |
| EBS CSI Driver | AWS addon — enables persistent storage |
| Prometheus + Grafana | Helm (`kube-prometheus-stack`) — 50GB persistent EBS |
| Loki + Promtail | Helm — log aggregation, 20GB persistent EBS |

---

## Environment Comparison

| Feature | Dev | Prod |
|:---|:---|:---|
| **Name Prefix** | `shop-dev` | `shop-prod` |
| **Stable Nodes** | `t3.small` × min 1 | `m7i-flex.large` × min 2 |
| **Spot Nodes** | min 1, max 5 | min 2, max 10 |
| **VPC CIDR** | `10.0.0.0/16` | `10.1.0.0/16` |
| **Monitoring** | Disabled | Enabled (Prometheus + Loki) |
| **State S3 Path** | `dev/` | `prod/` |

---

## Prerequisites Before Applying

```bash
# 1. Create S3 state bucket (one-time)
aws s3 mb s3://tf-state-ecommerce-microservices-3mr --region us-east-1
aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# 2. Create Grafana admin secret
aws secretsmanager create-secret \
  --name shop-prod/grafana-admin-password \
  --secret-string "YourSecurePassword123!" \
  --region us-east-1
```

---

## Teardown (Destroy in Reverse Order)

```bash
cd environments/prod/eks     && terraform destroy -auto-approve
cd environments/prod/network && terraform destroy -auto-approve
```
