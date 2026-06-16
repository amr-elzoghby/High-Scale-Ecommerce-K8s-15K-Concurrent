.PHONY: help generate-keys infra-up infra-down setup-cluster deploy up down local-cluster-up local-up local-down

# Colors for terminal output
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "AWS Production Targets:"
	@echo "  $(GREEN)up                  $(NC) Full End-to-End AWS Deployment (Keys + Infra + Cluster + Deploy)"
	@echo "  $(GREEN)down                $(NC) Destroy Everything safely to avoid AWS charges"
	@echo ""
	@echo "Local Development Targets (k3d):"
	@echo "  $(GREEN)local-up            $(NC) Create a local k3d cluster and deploy everything locally"
	@echo "  $(GREEN)local-down          $(NC) Delete the local k3d cluster"
	@echo ""
	@echo "Individual Steps:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v 'up:\|down:\|local-up:\|local-down:' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

# ─── Common Steps ─────────────────────────────────────────────────────────────

generate-keys: ## Generate RSA 4096-bit keys for JWT RS256 Authentication
	@echo "$(YELLOW)Generating RSA Keys for JWT Authentication...$(NC)"
	mkdir -p web-app/ecommerce-microservices/keys
	openssl genrsa -out web-app/ecommerce-microservices/keys/private.pem 4096 2>/dev/null
	openssl rsa -in web-app/ecommerce-microservices/keys/private.pem -pubout -out web-app/ecommerce-microservices/keys/public.pem 2>/dev/null
	@echo "$(GREEN)Keys generated successfully in web-app/ecommerce-microservices/keys/$(NC)"

setup-cluster: ## Setup K8s Cluster (Nginx Ingress + App Secrets)
	@echo "$(YELLOW)Installing Nginx Ingress Controller via Helm...$(NC)"
	helm upgrade --install ingress-nginx ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx \
		--namespace ingress-nginx --create-namespace
	@echo "$(YELLOW)Injecting Kubernetes Secrets from .env file...$(NC)"
	@if [ ! -f .env ]; then echo "$(YELLOW)⚠ .env file not found! Run: cp .env.example .env$(NC)" && exit 1; fi
	kubectl create namespace ecommerce-apps --dry-run=client -o yaml | kubectl apply -f -
	@set -a && . ./.env && set +a && \
	kubectl create secret generic app-secrets \
		--from-literal=MONGO_URI="$${MONGO_URI}" \
		--from-literal=DATABASE_URL="postgresql://$${POSTGRES_USER}:$${POSTGRES_PASSWORD}@postgres-0.postgres.ecommerce-data.svc.cluster.local:5432/$${POSTGRES_DB}" \
		--from-literal=JWT_PRIVATE_KEY="$$(cat web-app/ecommerce-microservices/keys/private.pem)" \
		--from-literal=JWT_PUBLIC_KEY="$$(cat web-app/ecommerce-microservices/keys/public.pem)" \
		-n ecommerce-apps --dry-run=client -o yaml | kubectl apply -f -
	@echo "$(GREEN)Cluster setup complete!$(NC)"

deploy: ## Deploy Databases, Microservices, and Ingress to Kubernetes
	@echo "$(YELLOW)Deploying Databases (StatefulSets)...$(NC)"
	kubectl apply -f web-app/k8s/databases/
	@echo "$(YELLOW)Deploying Microservices (Deployments & Services)...$(NC)"
	kubectl apply -f web-app/k8s/apps/
	@echo "$(YELLOW)Deploying Ingress Rules...$(NC)"
	kubectl apply -f web-app/k8s/ingress/
	@echo "$(YELLOW)Deploying Monitoring Stack...$(NC)"
	kubectl apply -f web-app/k8s/monitoring/
	@echo "$(GREEN)Application deployment complete!$(NC)"

# ─── AWS Production Deployment ────────────────────────────────────────────────

infra-up: ## Provision AWS Infrastructure using Terraform (Sequentially)
	@echo "$(YELLOW)Provisioning Network Layer...$(NC)"
	cd web-app/environments/prod/network && terraform init && terraform apply -auto-approve
	@echo "$(YELLOW)Provisioning Storage Layer...$(NC)"
	cd web-app/environments/prod/storage && terraform init && terraform apply -auto-approve
	@echo "$(YELLOW)Provisioning EKS Cluster...$(NC)"
	cd web-app/environments/prod/eks && terraform init && terraform apply -auto-approve
	@echo "$(YELLOW)Provisioning Compute Node Groups...$(NC)"
	cd web-app/environments/prod/compute && terraform init && terraform apply -auto-approve
	@echo "$(GREEN)Infrastructure provisioning complete!$(NC)"

infra-down: ## Destroy AWS Infrastructure using Terraform (Reverse Order)
	@echo "$(YELLOW)Destroying Compute Node Groups...$(NC)"
	cd web-app/environments/prod/compute && terraform destroy -auto-approve
	@echo "$(YELLOW)Destroying EKS Cluster...$(NC)"
	cd web-app/environments/prod/eks && terraform destroy -auto-approve
	@echo "$(YELLOW)Destroying Storage Layer...$(NC)"
	cd web-app/environments/prod/storage && terraform destroy -auto-approve
	@echo "$(YELLOW)Destroying Network Layer...$(NC)"
	cd web-app/environments/prod/network && terraform destroy -auto-approve
	@echo "$(GREEN)Infrastructure destroyed successfully!$(NC)"

up: generate-keys infra-up setup-cluster deploy ## Full End-to-End AWS Deployment
	@echo "$(GREEN)🚀 ShopScale Platform is fully deployed on AWS EKS!$(NC)"

down: ## Destroy AWS Deployment
	@echo "$(YELLOW)Cleaning up Kubernetes resources...$(NC)"
	kubectl delete -f web-app/k8s/ingress/ --ignore-not-found
	kubectl delete -f web-app/k8s/apps/ --ignore-not-found
	kubectl delete -f web-app/k8s/databases/ --ignore-not-found
	@echo "$(YELLOW)Proceeding to destroy AWS infrastructure...$(NC)"
	$(MAKE) infra-down
	@echo "$(GREEN)All AWS resources destroyed. No charges will be incurred.$(NC)"

# ─── Local Development (k3d) ──────────────────────────────────────────────────

local-cluster-up: ## Create local Kubernetes cluster using k3d
	@echo "$(YELLOW)Creating local k3d cluster (shopscale-local)...$(NC)"
	k3d cluster create shopscale-local -p "8080:80@loadbalancer" -p "8443:443@loadbalancer" --agents 2
	@echo "$(GREEN)Local cluster created! (Port 8080 mapped to localhost)$(NC)"

local-up: generate-keys local-cluster-up setup-cluster deploy ## Create local cluster and deploy everything
	@echo "$(GREEN)🚀 Local environment is running! Access via http://localhost:8080$(NC)"

local-down: ## Delete local k3d cluster
	@echo "$(YELLOW)Deleting local k3d cluster...$(NC)"
	k3d cluster delete shopscale-local
	@echo "$(GREEN)Local cluster deleted!$(NC)"
