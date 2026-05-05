# Environments Configuration

This directory contains the root Terraform orchestration files for `dev` and `prod` environments. Each environment is a standalone Terraform project subdivided into isolated state layers.

## Structure

```
environments/
├── dev/
│   ├── network/    # VPC, Subnets, Security Groups
│   ├── storage/    # S3 Buckets
│   └── eks/        # EKS Cluster + Helm Add-ons (Metrics Server, Cluster Autoscaler)
└── prod/
    ├── network/
    ├── storage/
    └── eks/
```

## How to Deploy

### 1. Initialize Backend
For any environment/layer, always run `init` first:
```bash
cd environments/dev/network
terraform init
terraform apply
```

### 2. Follow Deployment Order (REQUIRED)
Each layer depends on the previous one's remote state:

1. **Network** → Creates VPC, Subnets, Security Groups
   ```bash
   cd environments/<env>/network && terraform apply
   ```
2. **Storage** → Creates S3 buckets
   ```bash
   cd environments/<env>/storage && terraform apply
   ```
3. **EKS** → Creates cluster, node groups, and auto-deploys Helm add-ons
   ```bash
   cd environments/<env>/eks && terraform apply
   ```

> ⚠️ **Do not skip steps.** The EKS layer reads VPC/Subnet IDs from the Network remote state. If Network hasn't been applied, the EKS plan will fail.

---

## What Gets Deployed in EKS

When you run `terraform apply` in the `eks` layer, Terraform automatically:

1. Creates the EKS cluster with **dual node groups**:
   - `workers-stable` (On-Demand) — for databases
   - `workers-spot` (Spot, 3 instance types) — for microservices
2. Deploys **Metrics Server** via Helm (required for HPA to work)
3. Deploys **Cluster Autoscaler** via Helm with IRSA IAM permissions

---

## Environment Differences

| Feature | Development (Dev) | Production (Prod) |
| :--- | :--- | :--- |
| **Name Prefix** | `shop-dev` | `shop-prod` |
| **Node Instance Type** | `t3.small` | `t3.medium` |
| **Stable Nodes (On-Demand)** | min: 1, max: 2 | min: 2, max: 4 |
| **Spot Nodes** | min: 1, max: 5 | min: 3, max: 20 |
| **VPC CIDR** | `10.0.0.0/16` | `10.1.0.0/16` |
| **State Path (S3)** | `dev/` | `prod/` |
| **HPA Max Replicas** | 20 (shared config) | 20 |
