#!/bin/bash

# ── Log everything ──
exec > /var/log/userdata.log 2>&1
echo "=== Final Architecture Deploy $(date) ==="

# ── Swap Space (Crucial) ──
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# ── Dependencies ──
sudo apt-get update -y
sudo apt-get install -y docker.io git
sudo systemctl start docker
sudo systemctl enable docker

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# ── Clone & Env ──
cd /home/ubuntu
sudo git clone https://github.com/3MR-MLops/ecommerce-microservices.git
cd ecommerce-microservices

sudo tee .env > /dev/null <<'EOF'
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=Amr123
MONGO_URI=mongodb://admin:Amr123@mongodb:27017/admin?authSource=admin
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Amrsaad010900
POSTGRES_DB=payment_service_db
JWT_SECRET=Amrsaad010900
REDIS_HOST=redis
EOF

# ── 🚨 NEW STRATEGY: Nginx First! 🚨 ──
echo "Building NGINX first for immediate availability..."
sudo docker-compose build nginx
sudo docker-compose up -d nginx

# ── Build others in background to save RAM ──
echo "Building background services sequentially..."
for s in catalog-services cart-services order-services user-service payment-service; do
  sudo docker-compose build $s
  sudo docker-compose up -d $s
  sleep 10
done

# Final catch-all
sudo docker-compose up -d

echo "=== Deployment stable at $(date) ==="