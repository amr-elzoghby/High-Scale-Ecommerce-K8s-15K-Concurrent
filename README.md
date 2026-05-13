<div align="center">

# 🛒 High-Scale-Ecommerce-K8s-15K-Concurrent

[![CI/CD](https://github.com/amr-elzoghby/High-Scale-Ecommerce-K8s-15K-Concurrent/actions/workflows/deploy.yml/badge.svg)](https://github.com/amr-elzoghby/High-Scale-Ecommerce-K8s-15K-Concurrent/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://terraform.io)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/eks/)

**Production-grade e-commerce platform on AWS EKS — 5 Node.js microservices, automated scaling, full observability.**  
Engineered to handle **15,000+ concurrent users (100,000+ daily)** via HPA + Cluster Autoscaler.

</div>

---

![ShopScale Platform Preview](docs/images/hero_banner.png)

---

## 📑 Table of Contents

- [Load Testing & Evidence](#-load-testing--auto-scaling-evidence)
- [Quick Start (Local)](#-quick-start-local--docker-compose)
- [Deploy to AWS EKS](#️-deploy-to-aws-eks-production)
- [Architecture Overview](#️-architecture-overview)
- [Technology Stack](#️-technology-stack)
- [Observability Stack](#-observability-stack)
- [Auto-Scaling Architecture](#️-auto-scaling-architecture)
- [Security Highlights](#-security-highlights)
- [Project Structure](#-project-structure)
- [Teardown](#-teardown-avoid-aws-charges)

---

## 📈 Load Testing & Auto-Scaling Evidence

> **Note:** The load test below was executed **locally** on a developer laptop (Intel Core i7 8th Gen, 32GB RAM) using **k3d** (Kubernetes in Docker) — with no cloud infrastructure.  
> On a production **AWS EKS** deployment (t3.medium Spot nodes, max 20 nodes), the same architecture is designed to handle **15,000+ concurrent users** (100,000+ daily) thanks to HPA + Cluster Autoscaler.

### 🖥️ Local Stress Test — 4,000 Concurrent Users (k3d on Laptop)

Under extreme simulated load using **k6**, the Kubernetes HPA was pushed to its limits.  
This test verified the absolute saturation point of a local cluster.

| What Happened | Result |
|:---|:---|
| 🟢 **Steady State** | Handled **4,000 concurrent users** with stable response times |
| 🔴 **Peak Saturation** | Pushed to absolute physical limits — verified scaling logic under extreme load |
| ⚡ **Auto-Scaling** | Services scaled automatically from **2 → 9+ replicas** in seconds |
| 💾 **Resource Impact** | Global RAM hit **91.5%** — validated HPA before reaching hardware ceiling |

#### Grafana Dashboard — Ultimate Saturation Test (4,000 VUs)

![Grafana Saturation Test](docs/images/grafana-saturation.png)

---

#### Terminal — Live Pod Auto-Scaling in Action

![Terminal Auto-Scaling](docs/images/terminal-scaling.png)

*Pods going from `Pending` → `ContainerCreating` → `Running` in real time as HPA triggers scale-out.*

---

### ☁️ Production Capacity (AWS EKS)

| Environment | Nodes | Instance | Max Replicas/Service | Est. Concurrent Users |
|:---|:---:|:---:|:---:|:---:|
| **Local (k3d)** | 3 (Docker) | Core i7 laptop | 9 | **4,000** |
| **AWS EKS Prod** | Up to 20 Spot | `t3.medium` | 20 | **15,000+ (100,000+ daily)** |

---

## 🔄 GitOps & Continuous Delivery (ArgoCD)

This project implements a **Production-Grade GitOps Workflow**. Local development is automated, but production deployments are strictly managed via a **Dual-Repository Architecture** and **ArgoCD**.

![GitOps Automation Demo](docs/gitops_demo.gif)

### 🏗️ The "Zero-Touch" Deployment Flow

1.  **Code Change:** Developer pushes code to this repository.
2.  **CI Pipeline (GitHub Actions):** 
    *   Builds a secure Docker image.
    *   Pushes it to **Amazon ECR**.
    *   Automatically updates the image tag in the [GitOps Repository](GITOPS.md).
3.  **CD Reconciliation (ArgoCD):** 
    *   ArgoCD detects the manifest change in the GitOps repo.
    *   Automatically synchronizes the cluster state to match the Git state.
    *   Performs a **Rolling Update** on the EKS cluster.

> [!TIP]
> This workflow ensures that the **Git repository is the single source of truth** for the entire infrastructure and application state.

---

## ⚡ Quick Start (Local — Docker Compose)

> No AWS account needed. Runs fully on your machine in **~2 minutes**.

### Prerequisites

| Tool | Required Version |
|:---|:---:|
| Docker & Docker Compose | Latest |
| Node.js | v18+ |

```bash
# 1. Clone the repo
git clone https://github.com/amr-elzoghby/High-Scale-Ecommerce-K8s-15K-Concurrent.git
cd High-Scale-Ecommerce-K8s-15K-Concurrent

# 2. Set environment variables
cp .env.example .env
# Edit .env with your values (Mongo URI, Postgres password, JWT secret)

# 3. Start all services
cd web-app/ecommerce-microservices
docker-compose up -d
```

**Access Points:**

| Service | URL |
|:---|:---|
| 🌐 Storefront | http://localhost/ |
| 📦 Catalog API | http://localhost/api/products |
| 👤 User API | http://localhost/api/users |
| 🛒 Cart API | http://localhost/api/cart |
| 📋 Order API | http://localhost/api/orders |

---

## ☸️ Deploy to AWS EKS (Production)

### Prerequisites

| Tool | Required Version |
|:---|:---:|
| AWS CLI | v2 |
| Terraform | v1.5+ |
| kubectl | v1.28+ |
| Helm | v3+ |

```bash
# Verify all tools
aws --version
terraform --version
kubectl version --client
helm version
```

### Step 1 — AWS Setup

```bash
# Configure credentials
aws configure

# Create S3 bucket for Terraform state (one-time setup)
aws s3 mb s3://tf-state-ecommerce-microservices-3mr --region us-east-1

# Create Grafana admin password in Secrets Manager
aws secretsmanager create-secret \
  --name shop-prod/grafana-admin-password \
  --secret-string "YourSecurePassword123!" \
  --region us-east-1
```

### Step 2 — Deploy Infrastructure (in order)

```bash
# 1. Network layer (VPC, Subnets, VPC Endpoints)
cd web-app/environments/prod/network
terraform init && terraform apply

# 2. EKS Cluster + Monitoring Stack
cd ../eks
terraform init && terraform apply
# ⏱️ Takes ~20 minutes
```

---

## 🏗️ Architecture Overview

![Architecture Diagram](docs/images/architecture-diagram.png)

```
┌─────────────────────────────────────────────────────┐
│                    Internet                         │
└─────────────────┬───────────────────────────────────┘
                  │
        ┌─────────▼─────────┐
        │  Application LB   │  (Public Subnets)
        └─────────┬─────────┘
                  │
        ┌─────────▼─────────┐
        │   Nginx Ingress   │  (Routes traffic)
        └─────────┬─────────┘
                  │  Private Subnets
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐   ┌────▼────┐  ┌────▼────┐
│catalog│   │  user   │  │  cart   │  ... (5 services)
└───────┘   └─────────┘  └─────────┘
    │             │
┌───▼───┐   ┌────▼────┐
│MongoDB│   │PostgreSQL│  (StatefulSets on On-Demand nodes)
└───────┘   └─────────┘
```

---

## 🛠️ Technology Stack

| Layer | Technology | AWS Service |
|:---|:---|:---|
| **Backend** | Node.js + Express | EKS (Kubernetes 1.30) |
| **Databases** | MongoDB, PostgreSQL, Redis | StatefulSets + EBS volumes |
| **Ingress** | Nginx | Application Load Balancer |
| **IaC** | Terraform 1.5+ | S3 State + DynamoDB Lock |
| **CI/CD** | GitHub Actions + OIDC | ECR (Docker Registry) |
| **Scaling** | HPA + Cluster Autoscaler | EC2 Spot + On-Demand |
| **Monitoring** | Prometheus + Grafana | Persistent EBS (50GB) |
| **Logging** | Loki + Promtail | Persistent EBS (20GB) |
| **Secrets** | Kubernetes Secrets | AWS Secrets Manager + IRSA |

---

## 📊 Observability Stack

Automatically deployed via **Terraform Helm releases** — zero manual setup required.

| Tool | Purpose | Access |
|:---|:---|:---:|
| **Prometheus** | Metrics collection from all pods | `:9090` |
| **Grafana** | Real-time dashboards & alerting | `:3000` (port-forward) |
| **Loki** | Log aggregation from all containers | Internal |
| **Promtail** | Log shipping agent (DaemonSet) | DaemonSet |
| **cAdvisor** | Container resource metrics | Built-in to kubelet |

```bash
# Access Grafana locally
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

---

## ⚙️ Auto-Scaling Architecture

```
Traffic Spike → CPU > 60% on Pod
    → HPA scales Pod replicas (2 → 20)
    → New pods Pending (not enough nodes)
    → Cluster Autoscaler provisions Spot EC2 node
    → Pods scheduled, traffic served ✅
```

**Scale-in:** When traffic drops, HPA reduces replicas → Cluster Autoscaler removes idle nodes → cost drops automatically.

---

## 🔒 Security Highlights

| Security Control | Implementation |
|:---|:---|
| 🔐 **No NAT Gateway** | VPC Endpoints (EKS, EC2, ECR, S3, STS, SSM) for private subnet access |
| 🔑 **OIDC Auth** | GitHub Actions authenticates to AWS without stored credentials |
| 🎭 **IRSA** | Each pod gets minimal AWS permissions via IAM Roles for Service Accounts |
| 🛡️ **IMDSv2** | Enforced on all EC2 nodes — prevents SSRF-based metadata attacks |
| 👤 **Non-root Containers** | All services run as `USER node` — no privilege escalation |
| 🔍 **ECR Scan-on-Push** | Images scanned for CVEs on every push |

---

## 📂 Project Structure

```
.
├── .github/workflows/          # CI/CD (OIDC Deploy + PR Preview + Cleanup)
└── web-app/
    ├── ecommerce-microservices/
    │   ├── services/           # 5 Node.js microservices
    │   │   ├── user-service/   # Auth, JWT           (Port 3001)
    │   │   ├── catalog-service/# Products            (Port 3002)
    │   │   ├── cart-service/   # Cart + Redis        (Port 3003)
    │   │   ├── order-service/  # Orders              (Port 3004)
    │   │   └── payment-service/# Payments            (Port 3005)
    │   ├── nginx/              # Reverse proxy config
    │   └── docker-compose.yml  # Local development
    ├── k8s/
    │   ├── apps/               # Deployments, Services, HPAs
    │   ├── databases/          # StatefulSets (Mongo, Postgres, Redis)
    │   ├── ingress/            # Nginx Ingress rules
    │   └── monitoring/         # ServiceMonitors for Prometheus
    ├── modules/
    │   ├── network/            # VPC, Subnets, Security Groups, VPC Endpoints
    │   └── eks/                # EKS Cluster, Node Groups, Helm releases
    └── environments/
        ├── prod/               # Production Terraform configs
        └── dev/                # Development Terraform configs
```

---

## 🧹 Teardown (Avoid AWS Charges)

> ⚠️ Always destroy in reverse order — EKS first, then network.

```bash
# 1. Delete EKS cluster (most expensive resource)
cd web-app/environments/prod/eks
terraform destroy -auto-approve

# 2. Delete Network (VPC, subnets, endpoints)
cd ../network
terraform destroy -auto-approve
```

---

<p align="center">
  Built with ❤️ by <a href="https://github.com/amr-elzoghby">Amr Elzoghby</a>
  <br/>
  <sub>
    <a href="https://github.com/amr-elzoghby/High-Scale-Ecommerce-K8s-15K-Concurrent/blob/main/CONTRIBUTING.md">Contributing Guide</a> ·
    <a href="GITOPS.md">GitOps Repo</a>
  </sub>
</p>
