# 🚀 Deployment Guide - Govi Sahaya

Complete guide to deploying Govi Sahaya to production environments.

---

## 📋 Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Local Development Setup](#local-development-setup)
3. [Docker Setup](#docker-setup)
4. [Database Setup](#database-setup)
5. [Environment Configuration](#environment-configuration)
6. [Deployment Options](#deployment-options)
   - [AWS Deployment](#aws-deployment)
   - [Google Cloud Deployment](#google-cloud-deployment)
   - [Azure Deployment](#azure-deployment)
   - [DigitalOcean Deployment](#digitalocean-deployment)
   - [Heroku Deployment](#heroku-deployment)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Monitoring & Logging](#monitoring--logging)
9. [Scaling & Performance](#scaling--performance)
10. [Troubleshooting](#troubleshooting)
11. [Rollback Procedures](#rollback-procedures)

---

## ✅ Pre-Deployment Checklist

### Before Deploying to Production

- [ ] All tests pass locally (`npm test` for backend, `flutter test` for frontend)
- [ ] Environment variables configured
- [ ] Database migrations run successfully
- [ ] API endpoints tested with Postman/Insomnia
- [ ] SSL certificate obtained (HTTPS ready)
- [ ] Firewall rules configured
- [ ] Backup strategy in place
- [ ] Monitoring tools set up
- [ ] Error logging configured
- [ ] Security vulnerabilities checked (`npm audit`)
- [ ] Code reviewed and merged to `main` branch
- [ ] Version bumped in `package.json` and `pubspec.yaml`
- [ ] CHANGELOG.md updated
- [ ] Documentation updated

---

## 🖥️ Local Development Setup

### Backend Setup

1. **Install Dependencies**
```bash
cd govi_sahaya_backend
npm install
```

2. **Create Environment File**
```bash
cp .env.example .env
```

3. **Configure Variables**
Edit `.env`:
```env
NODE_ENV=development
PORT=5000
MONGODB_URI=mongodb://localhost:27017/govi_sahaya
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRE=7d
REFRESH_TOKEN_EXPIRE=30d

# Firebase
FIREBASE_API_KEY=
FIREBASE_AUTH_DOMAIN=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_APP_ID=

# Email Service
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# External APIs
OPENWEATHER_API_KEY=
NEWSAPI_KEY=
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=

# ML Service
ML_SERVICE_URL=http://localhost:5001

# AWS S3 (Optional)
AWS_REGION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=

# CORS
CORS_ORIGIN=http://localhost:8080,http://localhost:3000
```

4. **Start MongoDB**
```bash
# Using Docker
docker run -d -p 27017:27017 --name mongodb mongo:latest

# Or using MongoDB Community Edition
mongod
```

5. **Run Backend**
```bash
npm start
# Or for development with hot reload
npm run dev
```

6. **Verify**
```bash
curl http://localhost:5000/api/health
```

### Frontend Setup

1. **Install Dependencies**
```bash
cd govi_sahaya_mobile
flutter pub get
```

2. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

3. **Run on Emulator**
```bash
# Android
flutter run -d emulator-5554

# iOS
flutter run -d iPhone
```

---

## 🐳 Docker Setup

### Docker Installation

**Windows & Mac:**
```bash
# Download Docker Desktop from https://www.docker.com/products/docker-desktop
# Install and start Docker Desktop
```

**Linux:**
```bash
sudo apt-get install docker.io docker-compose
sudo usermod -aG docker $USER
```

### Backend Dockerfile

Create `Dockerfile` in backend root:

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:18-alpine
WORKDIR /app
RUN apk add --no-cache curl

# Copy from builder
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT:-5000}/api/health || exit 1

EXPOSE 5000
CMD ["node", "server.js"]
```

### Docker Compose

Create `docker-compose.yml` in root:

```yaml
version: '3.8'

services:
  # Backend API
  backend:
    build:
      context: ./govi_sahaya_backend
      dockerfile: Dockerfile
    container_name: govi-backend
    ports:
      - "5000:5000"
    environment:
      NODE_ENV: production
      MONGODB_URI: mongodb://mongo:27017/govi_sahaya
      JWT_SECRET: ${JWT_SECRET}
      PORT: 5000
    depends_on:
      - mongo
      - redis
    volumes:
      - ./govi_sahaya_backend/uploads:/app/uploads
      - ./govi_sahaya_backend/logs:/app/logs
    restart: unless-stopped
    networks:
      - govi-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # MongoDB
  mongo:
    image: mongo:5.0
    container_name: govi-mongo
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: govi_sahaya
    volumes:
      - mongo_data:/data/db
      - mongo_config:/data/configdb
    restart: unless-stopped
    networks:
      - govi-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: govi-redis
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - govi-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 3s
      retries: 3

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: govi-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - govi-network

  # ML Service (Python)
  ml_service:
    build:
      context: ./ml_model
      dockerfile: Dockerfile
    container_name: govi-ml
    ports:
      - "5001:5001"
    environment:
      FLASK_ENV: production
      MODEL_PATH: /app/models/best_model.h5
    volumes:
      - ./ml_model/models:/app/models
      - ./ml_model/uploads:/app/uploads
    restart: unless-stopped
    networks:
      - govi-network

volumes:
  mongo_data:
  mongo_config:
  redis_data:

networks:
  govi-network:
    driver: bridge
```

### Build and Run

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Remove all data (careful!)
docker-compose down -v
```

### Nginx Configuration

Create `nginx.conf`:

```nginx
upstream backend {
    server backend:5000;
}

upstream ml_service {
    server ml_service:5001;
}

server {
    listen 80;
    server_name _;

    client_max_body_size 10M;

    # Redirect HTTP to HTTPS (uncomment for production)
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /api/ml/ {
        proxy_pass http://ml_service;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Compression
    gzip on;
    gzip_types text/plain text/css text/javascript application/json;
    gzip_min_length 1000;
}
```

---

## 🗄️ Database Setup

### MongoDB Atlas (Cloud)

1. **Create Account**
   - Go to https://www.mongodb.com/cloud/atlas
   - Sign up for free tier

2. **Create Cluster**
   - Click "Create a Cluster"
   - Choose AWS, preferred region
   - Select shared tier (free)

3. **Network Access**
   - Add IP whitelist (allow all for development: 0.0.0.0/0)
   - For production: add specific IPs

4. **Get Connection String**
   - Go to Clusters → Connect
   - Copy connection string
   - Replace `<password>` with your password
   - Use in `MONGODB_URI`

### Database Initialization

```bash
# Connect to MongoDB
mongosh mongodb://localhost:27017/govi_sahaya

# Create collections with indexes
db.createCollection("users")
db.users.createIndex({ email: 1 }, { unique: true })
db.users.createIndex({ firebaseUID: 1 })
db.users.createIndex({ "location.state": 1 })

db.createCollection("posts")
db.posts.createIndex({ authorId: 1 })
db.posts.createIndex({ category: 1 })
db.posts.createIndex({ createdAt: -1 })

db.createCollection("products")
db.products.createIndex({ category: 1 })
db.products.createIndex({ price: 1 })

db.createCollection("orders")
db.orders.createIndex({ userId: 1 })
db.orders.createIndex({ createdAt: 1 }, { expireAfterSeconds: 2592000 })
```

### Backup Strategy

```bash
# Backup MongoDB
mongodump --uri "mongodb://user:pass@localhost:27017/govi_sahaya" \
  --out=/backups/mongo_$(date +%Y%m%d_%H%M%S)

# Restore MongoDB
mongorestore --uri "mongodb://user:pass@localhost:27017/govi_sahaya" \
  /backups/mongo_20240115_143000

# Automated backup (cron job)
# Add to crontab -e
0 2 * * * mongodump --uri "mongodb://..." --out=/backups/mongo_$(date +\%Y\%m\%d)
```

---

## 🔧 Environment Configuration

### Production Environment Variables

Create `.env.production`:

```env
# Application
NODE_ENV=production
PORT=5000
LOG_LEVEL=info

# Database
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/govi_sahaya
MONGO_MAX_POOL_SIZE=10

# Cache
REDIS_URL=redis://:password@redis.example.com:6379
REDIS_DB=0

# Security
JWT_SECRET=use_strong_random_string_here
JWT_EXPIRE=7d
REFRESH_TOKEN_SECRET=use_different_strong_string
REFRESH_TOKEN_EXPIRE=30d
BCRYPT_SALT_ROUNDS=10

# CORS
CORS_ORIGIN=https://app.govisahaya.com,https://www.govisahaya.com
CORS_CREDENTIALS=true

# Email Service
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=${SENDGRID_API_KEY}
MAIL_FROM=noreply@govisahaya.com

# Firebase
FIREBASE_API_KEY=${FIREBASE_API_KEY}
FIREBASE_AUTH_DOMAIN=govisahaya.firebaseapp.com
FIREBASE_PROJECT_ID=govisahaya
FIREBASE_STORAGE_BUCKET=govisahaya.appspot.com
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}
FIREBASE_APP_ID=${FIREBASE_APP_ID}
FIREBASE_ADMIN_SDK_PATH=/app/config/firebase-admin.json

# External APIs
OPENWEATHER_API_KEY=${OPENWEATHER_API_KEY}
NEWSAPI_KEY=${NEWSAPI_KEY}
RAZORPAY_KEY_ID=${RAZORPAY_KEY_ID}
RAZORPAY_KEY_SECRET=${RAZORPAY_KEY_SECRET}

# ML Service
ML_SERVICE_URL=http://ml_service:5001
ML_SERVICE_TIMEOUT=30000

# AWS S3
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_S3_BUCKET=govisahaya-uploads
AWS_S3_URL_EXPIRATION=3600

# Monitoring
SENTRY_DSN=${SENTRY_DSN}
LOG_DESTINATION=/var/log/govi-sahaya/app.log

# Performance
CACHE_TTL=3600
REQUEST_TIMEOUT=30000
MAX_UPLOAD_SIZE=10485760
```

### Secrets Management

**Using AWS Secrets Manager:**

```bash
# Create secret
aws secretsmanager create-secret \
  --name govi/production/env \
  --secret-string file://secrets.json

# Retrieve secret
aws secretsmanager get-secret-value \
  --secret-id govi/production/env
```

---

## 🌍 Deployment Options

### AWS Deployment (ECS + Fargate)

#### 1. Push Image to ECR

```bash
# Get login token
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.ap-south-1.amazonaws.com

# Build image
docker build -t govi-backend:latest \
  ./govi_sahaya_backend

# Tag image
docker tag govi-backend:latest \
  123456789.dkr.ecr.ap-south-1.amazonaws.com/govi-backend:latest

# Push image
docker push 123456789.dkr.ecr.ap-south-1.amazonaws.com/govi-backend:latest
```

#### 2. Create ECS Cluster

```bash
aws ecs create-cluster --cluster-name govi-prod

aws ecs register-task-definition \
  --cli-input-json file://task-definition.json

aws ecs create-service \
  --cluster govi-prod \
  --service-name govi-backend \
  --task-definition govi-backend:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={ \
    subnets=[subnet-123],securityGroups=[sg-123]}"
```

#### 3. Configure RDS for MongoDB

```bash
# Use DocumentDB (AWS's MongoDB compatible)
aws docdb create-db-cluster \
  --db-cluster-identifier govi-cluster \
  --engine docdb \
  --master-username admin \
  --master-user-password YourPassword123
```

### Google Cloud Deployment

#### 1. Build and Push Image

```bash
# Configure authentication
gcloud auth login
gcloud config set project govi-sahaya-prod

# Build image
gcloud builds submit --tag gcr.io/govi-sahaya-prod/backend

# Deploy to Cloud Run
gcloud run deploy govi-backend \
  --image gcr.io/govi-sahaya-prod/backend \
  --platform managed \
  --region asia-south1 \
  --memory 512Mi \
  --cpu 1 \
  --allow-unauthenticated \
  --set-env-vars MONGODB_URI=$MONGODB_URI
```

#### 2. Enable Cloud SQL

```bash
# Create Cloud SQL instance
gcloud sql instances create govi-mongodb \
  --tier=db-n1-standard-1 \
  --region=asia-south1
```

### Azure Deployment

#### 1. Create Container Registry

```bash
az acr create \
  --resource-group govi-rg \
  --name govisahaya \
  --sku Basic

# Build and push
az acr build \
  --registry govisahaya \
  --image govi-backend:latest \
  ./govi_sahaya_backend
```

#### 2. Deploy to Container Instances

```bash
az container create \
  --resource-group govi-rg \
  --name govi-backend \
  --image govisahaya.azurecr.io/govi-backend:latest \
  --cpu 1 --memory 1 \
  --port 5000 \
  --environment-variables \
    MONGODB_URI=$MONGODB_URI \
    JWT_SECRET=$JWT_SECRET
```

### DigitalOcean Deployment

#### 1. Create Droplet

```bash
# Create droplet
doctl compute droplet create govi-backend \
  --region blr1 \
  --image ubuntu-22-04-x64 \
  --size s-2vcpu-2gb

# SSH into droplet
ssh root@<IP_ADDRESS>
```

#### 2. Setup Server

```bash
# Update and install dependencies
apt-get update
apt-get install -y curl git

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m) \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone repository
git clone https://github.com/yourusername/govi-sahaya.git
cd govi-sahaya

# Start services
docker-compose up -d
```

#### 3. Setup SSL with Let's Encrypt

```bash
apt-get install -y certbot python3-certbot-nginx

certbot certonly --standalone \
  -d api.govisahaya.com \
  -d www.api.govisahaya.com

# Configure Nginx to use SSL
```

### Heroku Deployment

#### 1. Prepare App

```bash
# Install Heroku CLI
curl https://cli.heroku.com/install.sh | sh

# Login
heroku login
```

#### 2. Create Procfile

```
web: npm start
worker: npm run worker
```

#### 3. Deploy

```bash
# Create app
heroku create govi-sahaya-prod

# Add MongoDB Atlas addon
heroku addons:create mongolab:sandbox

# Set environment variables
heroku config:set JWT_SECRET=your_secret_key
heroku config:set FIREBASE_API_KEY=your_key

# Deploy
git push heroku main

# View logs
heroku logs --tail
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/backend

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mongo:
        image: mongo
        options: >-
          --health-cmd mongosh
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: 'npm'
          cache-dependency-path: govi_sahaya_backend/package-lock.json

      - name: Install dependencies
        run: |
          cd govi_sahaya_backend
          npm ci

      - name: Run tests
        env:
          MONGODB_URI: mongodb://localhost:27017/test-govi
        run: |
          cd govi_sahaya_backend
          npm test

      - name: Security audit
        run: |
          cd govi_sahaya_backend
          npm audit --audit-level=moderate

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha

      - name: Build and push image
        uses: docker/build-push-action@v4
        with:
          context: ./govi_sahaya_backend
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: build
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to production
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          # Deploy script
          ./scripts/deploy-to-aws.sh
```

---

## 📊 Monitoring & Logging

### Setup Sentry for Error Tracking

```javascript
// In server.js
const Sentry = require("@sentry/node");

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0
});

app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.errorHandler());
```

### Setup DataDog for Monitoring

```bash
# Install agent
curl -L https://install.datadoghq.com | bash

# Configure
DD_API_KEY=<your_key> \
DD_SITE=datadoghq.com \
DD_LOGS_ENABLED=true \
DD_TRACE_ENABLED=true \
  systemctl restart datadog-agent
```

### View Logs

```bash
# Docker logs
docker logs -f govi-backend

# Tail application logs
tail -f /var/log/govi-sahaya/app.log

# Real-time monitoring with journalctl
journalctl -u govi-backend -f
```

---

## 📈 Scaling & Performance

### Horizontal Scaling

```bash
# Scale services (Docker Swarm)
docker service scale backend=3
docker service scale ml_service=2

# Scale in Kubernetes
kubectl scale deployment govi-backend --replicas=3
```

### Load Balancing

Configure in nginx.conf:

```nginx
upstream backend {
    least_conn;  # Connection load balancing
    server backend-1:5000;
    server backend-2:5000;
    server backend-3:5000;
}
```

### Database Optimization

```javascript
// Add caching
const redis = require('redis');
const cache = redis.createClient();

// Implement connection pooling
mongoose.connect(process.env.MONGODB_URI, {
  maxPoolSize: 10,
  minPoolSize: 5
});
```

---

## 🔍 Troubleshooting

### Common Issues

#### 1. Database Connection Failed

```bash
# Check MongoDB status
docker-compose logs mongo

# Verify connection string
mongosh $MONGODB_URI

# Check network connectivity
docker-compose exec backend curl http://mongo:27017
```

#### 2. High Memory Usage

```bash
# Check process memory
docker stats

# Limit container memory
docker run --memory 512m govi-backend:latest
```

#### 3. API Timeout

```bash
# Increase timeout in nginx
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;

# Check slow queries
db.setProfilingLevel(1, { slowms: 100 })
db.system.profile.find().limit(5).sort({ ts: -1 }).pretty()
```

#### 4. SSL Certificate Issues

```bash
# Verify certificate
openssl x509 -in /etc/ssl/certs/cert.pem -text -noout

# Renew certificate
certbot renew

# Test SSL
openssl s_client -connect api.govisahaya.com:443
```

---

## 🔙 Rollback Procedures

### Docker Rollback

```bash
# View image history
docker image history govi-backend

# Rollback to previous image
docker run --rm -d \
  --name govi-backend-old \
  govi-backend:v1.0.0

# Switch traffic to old version
docker-compose up -d --no-deps --build backend
```

### Database Rollback

```bash
# List backups
ls -la /backups/

# Restore from backup
mongorestore --uri "mongodb://..." /backups/mongo_20240115_120000

# Verify restoration
db.users.count()
```

### Git Rollback

```bash
# Revert to previous commit
git revert HEAD

# Force push (use with caution in production!)
git reset --hard <commit_hash>
git push origin main --force
```

---

## 📚 Additional Resources

- [Docker Official Documentation](https://docs.docker.com/)
- [MongoDB Atlas Setup](https://docs.atlas.mongodb.com/)
- [AWS ECS Deployment](https://docs.aws.amazon.com/AmazonECS/)
- [Google Cloud Deployment](https://cloud.google.com/docs)
- [Azure Deployment](https://learn.microsoft.com/azure/container-instances/)
- [Let's Encrypt SSL](https://letsencrypt.org/docs/)

---

## 🆘 Need Help?

**Issues Checklist:**
- [ ] Read this guide completely
- [ ] Check [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- [ ] Review container logs
- [ ] Check environment variables
- [ ] Verify database connection
- [ ] Contact on GitHub Issues

---

<div align="center">

**Last Updated**: January 2024
**Maintained By**: Govi Sahaya Team
**License**: MIT

</div>
