# Contributing to High-Scale-Ecommerce-K8s-15K-Concurrent

Welcome! This guide will help you set up your development environment and understand the workflow for contributing to this platform.

---

## 🛠️ Prerequisites

To contribute to this project, you need:

| Tool | Version | Purpose |
|:---|:---:|:---|
| **AWS CLI** | v2 | Credentials & resource management |
| **Terraform** | v1.5+ | Infrastructure changes |
| **kubectl** | v1.28+ | Interacting with the EKS cluster |
| **Docker & Docker Compose** | Latest | Local testing and image building |
| **Node.js** | v18+ | Local service development |
| **Python** | v3.12 | Load testing scripts (k6 helper) |

---

## 💻 Local Development Workflow

1. **Clone & Setup**:
   ```bash
   git clone https://github.com/amr-elzoghby/High-Scale-Ecommerce-K8s-15K-Concurrent.git
   cd High-Scale-Ecommerce-K8s-15K-Concurrent
   cp .env.example .env
   ```
2. **Environment Variables**: Update `.env` with your local secrets (Mongo URI, Postgres password, JWT secret).
3. **Run Services**:
   ```bash
   cd web-app/ecommerce-microservices
   docker-compose up -d
   ```

---

## 🏗️ Infrastructure Workflow (Terraform)

We use a **layered state strategy**. If you are modifying infrastructure, follow this lifecycle:

1. **Format Check**: Always run `terraform fmt -recursive` before committing.
2. **Lifecycle Order**:
   - Change common code in `modules/`.
   - Test in `environments/dev/` before touching `environments/prod/`.
3. **Deployment Order**:
   1. `network` — VPC and Security components.
   2. `eks` — Amazon EKS Cluster and Worker Nodes.

---

## ☸️ Kubernetes (K8s) Workflow

While local development uses `docker-compose`, production runs on **Kubernetes (EKS)**.

1. **Manifests Location**: All K8s YAML files are stored in `web-app/k8s/`.
2. **Applying Changes**:
   - Always apply namespaces and secrets first.
   - Run: `kubectl apply -f web-app/k8s/namespaces/` then `databases/`, `apps/`, and `ingress/`.
3. **Secrets Management**: Never commit actual secrets. Use `k8s/secrets/` locally, but ensure it remains in `.gitignore`.

---

## 🔄 Branching & Pull Requests

1. **Branch Naming**:
   - `feature/description` — for new features
   - `fix/description` — for bug fixes
   - `infra/description` — for IaC changes
2. **PR Previews**:
   - Add the label `pr-deploy` to your PR to trigger a temporary preview environment.
   - Wait for **GitHub Actions** status checks to pass before requesting a review.
3. **Code Review**: All PRs must be reviewed and approved before merging into `main`.

---

## 🧪 Testing Standards

| Layer | Standard |
|:---|:---|
| **Terraform** | Must pass `terraform validate` and `tflint` |
| **Docker** | No secrets in Dockerfiles; images must scan clean on ECR |
| **Backend** | Ensure service-to-service communication works through the `nginx` gateway |

---

## 📜 Code of Conduct

Be professional, respect the non-root container constraints, and always optimize for cloud costs — **delete temporary resources when done!**
