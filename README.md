<div align="center">

# 🛒 High-Scale-Ecommerce-K8s-15K-Concurrent

[![CI/CD](https://github.com/amr-elzoghby/High-Scale-Ecommerce-K8s-15K-Concurrent/actions/workflows/deploy.yml/badge.svg)](https://github.com/amr-elzoghby/High-Scale-Ecommerce-K8s-15K-Concurrent/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://terraform.io)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/eks/)

**Production-grade e-commerce platform on AWS EKS — 5 polyglot microservices (Node.js & Python FastAPI), automated scaling, full observability.**  
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
| **Backend** | Node.js (Express) & Python (FastAPI) | EKS (Kubernetes 1.30) |
| **Service Communication** | REST (HTTP/JSON) for cart & catalog · gRPC (Protobuf) for payment & order | Internal Kubernetes DNS |
| **Authentication** | JWT RS256 (Asymmetric) · Access Token 15m · httpOnly Refresh Token 7d | Kubernetes Secrets (RSA Key Pair) |
| **Databases** | Polyglot: MongoDB, PostgreSQL (Numeric, CheckConstraint), Redis (7-day TTL) | StatefulSets + EBS volumes |
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

## ⚙️ Auto-Scaling & Resilience Architecture

```
Traffic Spike → CPU > 60% on Pod
    → HPA scales Pod replicas (2 → 20)
    → New pods Pending (not enough nodes)
    → Cluster Autoscaler provisions Spot EC2 node
    → Pods scheduled, traffic served ✅
```

**Scale-in:** When traffic drops, HPA reduces replicas → Cluster Autoscaler removes idle nodes → cost drops automatically.

### 🛠️ Self-Healing & High Availability (Resilience)
Every microservice in the cluster is configured with strict **Kubernetes Probes** to ensure zero-downtime operations and maximum uptime:

- **Readiness Probes (`httpGet`):** Prevents routing web traffic to pods that are not fully initialized or still connecting to databases. This guarantees **zero-downtime rolling deployments** and eliminates `502 Bad Gateway` errors.
- **Liveness Probes (`httpGet`):** Constantly monitors container health. If a microservice freezes or hits a deadlock, Kubernetes detects the failure within seconds, terminates the dead container, and spawns a healthy replica automatically (**Self-Healing**).
- **Data Constraints & Expiration:**
  - **Payments Safety:** The Payment service uses PostgreSQL with explicit **ACID transactions**, `Numeric(10, 2)` column precision for precise decimals, and custom DB-level `CheckConstraint` rules to enforce `amount > 0` and secure financial logs.
  - **Cart Expiration:** Customer shopping carts are cached inside Redis with a dynamic **7-day Time-To-Live (TTL)**. Every user action renews the lease, preventing memory bloat while preserving active sessions.

### ⚡ gRPC Communication Architecture (Dual-Protocol Design)
The platform uses a **Dual-Protocol** strategy — each protocol serves a different purpose based on performance requirements:

```
[ Browser / Frontend ]
        │
        │  REST (HTTP/JSON)
        ▼
   AWS ALB → Nginx Ingress
        │
   ┌────┴────────────────────────────────────────────────┐
   │                                                     │
   ▼  REST only                  ▼  REST (browser)      │
cart-service (3003)         payment-service (3005)      │
catalog-service (3002)      order-service   (3004)      │
                                   │                    │
                         ┌─────────┘                    │
                         │  gRPC (Protobuf)              │
                         ▼  Internal Cluster Only        │
                   payment-service (:50051)             │
                   order-service   (:50052)             │
```

| Service | Protocol | Port | Used By |
|:---|:---|:---:|:---|
| **cart-service** | REST only | `3003` | Browser |
| **catalog-service** | REST only | `3002` | Browser |
| **payment-service** | REST + **gRPC** | `3005` + `50051` | Browser + Internal services |
| **order-service** | REST + **gRPC** | `3004` + `50052` | Browser + Internal services |

> **Why gRPC for Payment & Order?** These two services handle the most critical and latency-sensitive flows (checkout, payment processing). gRPC uses **Protocol Buffers (binary)** which is ~7x faster to serialize than JSON and enforces strict typed contracts via `.proto` schema files, making it ideal for **high-throughput, low-latency inter-service communication**.

---

## 🔒 Security Highlights

| Security Control | Implementation |
|:---|:---|
| 🔐 **No NAT Gateway** | VPC Endpoints (EKS, EC2, ECR, S3, STS, SSM) for private subnet access |
| 🔑 **OIDC Auth** | GitHub Actions authenticates to AWS without stored credentials |
| 🎭 **IRSA** | Each pod gets minimal AWS permissions via IAM Roles for Service Accounts |
| 🛡️ **IMDSv2** | Enforced on all EC2 nodes — prevents SSRF-based metadata attacks |
| 👤 **Non-root Containers** | All services run as `USER node` — no privilege escalation |
| 🔏 **JWT RS256 (Asymmetric)** | Tokens signed with RSA-4096 **private key** (user-service only). All other services verify using the **public key** only — a compromised service cannot forge tokens |
| 🍪 **Secure Refresh Tokens** | Refresh tokens stored in `httpOnly + Secure + SameSite=Strict` cookies — immune to XSS attacks. Short-lived Access Tokens (15 min) with 7-day rotation |
| 🚦 **Stateless Auth Middleware** | Every protected route in cart, order, and payment services performs RS256 JWT verification in-memory — **zero database calls** per request |
| 🛡️ **Trivy Image Scanning** | Automated vulnerability scanning in CI/CD pipelines, strictly blocking deployments with `CRITICAL` severity CVEs |
| 🐕 **Falco Runtime Security** | Real-time threat detection (eBPF) monitoring container syscalls, integrated with **Falcosidekick** for automated Slack alerts |

### 🚨 Real-Time Threat Detection (Falco + Slack)

The EKS cluster is actively protected by **Falco**, which monitors system calls at the kernel level using eBPF. If anomalous behavior is detected (e.g., spawning a shell in a container or reading sensitive files like `/etc/shadow`), **Falcosidekick** immediately forwards the alert to a dedicated security Slack channel.

![Falco Slack Alert](docs/images/falco-slack-alert.png)

---

## 📂 Project Structure

```
.
├── .github/workflows/          # CI/CD (OIDC Deploy + PR Preview + Cleanup)
└── web-app/
    ├── ecommerce-microservices/
    │   ├── services/           # 5 Polyglot microservices
    │   │   ├── user-service/   # Auth, JWT (Node.js)             (REST :3001)
    │   │   ├── catalog-service/# Products (Node.js)              (REST :3002)
    │   │   ├── cart-service/   # Cart + Redis (Node.js)           (REST :3003)
    │   │   ├── order-service/  # Orders (Node.js)       (REST :3004 + gRPC :50052)
    │   │   │   ├── order.proto     # gRPC contract definition
    │   │   │   └── grpcServer.js   # gRPC server implementation
    │   │   └── payment-service/# Payments (Python FastAPI)(REST :3005 + gRPC :50051)
    │   │       ├── payment.proto   # gRPC contract definition
    │   │       └── grpc_server.py  # gRPC server implementation
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

## 🚀 Quickstart (One-Click Deploy)

This project includes a root `Makefile` to fully automate both Local Development (via k3d) and Production Provisioning (AWS EKS via Terraform).

### Option A: Local Development (k3d)
Perfect for testing without incurring AWS charges. Requires [k3d](https://k3d.io/) and Docker.

```bash
# Create local cluster, generate keys, and deploy everything
make local-up

# Tear down local cluster
make local-down
```

### Option B: Production (AWS EKS)
Requires AWS credentials, Terraform, and kubectl.

```bash
# Deploy everything (Generates RSA keys, provisions Terraform infra, and deploys K8s apps)
make up

# Destroy everything safely to avoid charges
make down
```

---

## 🛠️ Makefile Commands Reference

To see all available individual commands:
```bash
make help
```

---

## 🧹 Teardown (Avoid AWS Charges)

> ⚠️ Always destroy resources when you are done to prevent unexpected AWS costs.

```bash
# Safely clean up K8s resources and destroy all Terraform infrastructure in reverse order
make down
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
