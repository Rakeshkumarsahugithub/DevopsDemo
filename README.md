# DevOps Demo Project

A full-stack microservices application demonstrating modern DevOps practices with React frontend, Express backend, Docker containerization, and AWS deployment.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Users                                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Route 53 (DNS)                            │
│                    + SSL/TLS (ACM)                           │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────┐            ┌──────────────────┐
│   CloudFront    │            │       ALB        │
│   (Frontend)    │            │   (Backend API)  │
└────────┬────────┘            └────────┬─────────┘
         │                              │
         ▼                              ▼
┌─────────────────┐            ┌──────────────────┐
│   S3 Bucket     │            │   EC2 Instance   │
│  (Static Site)  │            │  (Docker + App)  │
└─────────────────┘            └──────────────────┘
         │                              │
         └──────────────┬───────────────┘
                        ▼
              ┌──────────────────┐
              │   CloudWatch     │
              │  (Monitoring)    │
              └──────────────────┘
```

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Docker Setup](#docker-setup)
- [AWS Infrastructure](#aws-infrastructure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Security](#security)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)

## ✨ Features

- **Microservices Architecture**: Separate frontend and backend services
- **Containerization**: Docker containers for both services
- **CI/CD**: Automated deployment with GitHub Actions
- **Monitoring**: CloudWatch logs and metrics
- **Security**: IAM roles, security groups, HTTPS enforcement
- **Scalability**: Load balancer ready for auto-scaling

## 🛠️ Tech Stack

### Frontend
- React 18
- Vite
- Modern CSS with gradients and animations
- Containerization: Docker

### Backend
- Node.js 20
- Express.js
- CORS enabled
- RESTful API
- Containerization: Docker

### DevOps
- Docker & Docker Compose
- AWS (S3, EC2, CloudFront)
- GitHub Actions CI/CD
- Automated deployment pipeline

## 📦 Prerequisites

- Node.js 20+ and npm
- Docker and Docker Compose
- AWS Account with appropriate permissions
- AWS CLI configured
- Git
- (Optional) Domain name for production deployment

## 🚀 Local Development

### 1. Clone the Repository

\`\`\`bash
git clone <your-repo-url>
cd devops-demo
\`\`\`

### 2. Backend Setup

\`\`\`bash
cd backend
npm install
npm run dev
\`\`\`

The backend will start on `http://localhost:5000`

**Available Endpoints:**
- `GET /` - API status: `{"message":"DevOps Demo API is running!"}`
- `GET /api/health` - Health check: `{"status":"healthy"}`
- `GET /api/tasks` - Sample tasks API
- `GET /api/messages` - Sample messages API

### 3. Frontend Setup

\`\`\`bash
cd frontend
npm install
npm run dev
\`\`\`

The frontend will start on `http://localhost:5173`

### 4. Environment Variables

**Backend (.env):**
\`\`\`env
PORT=5000
NODE_ENV=development
\`\`\`

**Frontend (.env):**
\`\`\`env
VITE_API_URL=http://localhost:5000
\`\`\`

## 🐳 Docker Setup

### Build and Run with Docker Compose

\`\`\`bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
\`\`\`

Access the application:
- Frontend: `http://localhost`
- Backend: `http://localhost:5000`

### Individual Docker Commands

**Backend:**
\`\`\`bash
cd backend
docker build -t devdemo-backend .
docker run -p 5000:5000 devdemo-backend
\`\`\`

**Frontend:**
\`\`\`bash
cd frontend
docker build -t devdem-frontend .
docker run -p 80:80 devdem-frontend
\`\`\`

## ☁️ AWS Infrastructure

### Infrastructure Components

1. **S3 + CloudFront**: Static website hosting for frontend
2. **EC2**: Backend application server with Docker
3. **Security Groups**: Network security for EC2 instance
4. **IAM**: Roles and policies for secure access

### Current Deployment

- **Backend**: EC2 instance `devdemo` at `http://18.210.24.182:5000`
- **Frontend**: S3 bucket with CloudFront distribution
- **Container**: `devdemo-backend` running on EC2 with Docker



## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The pipeline automatically:
1. Lints and tests code
2. Builds Docker images
3. Pushes images to ECR
4. Deploys frontend to S3
5. Deploys backend to EC2
6. Invalidates CloudFront cache

### Required GitHub Secrets

Add these secrets in GitHub repository settings:

\`\`\`
AWS_ACCESS_KEY_ID          # AWS access key
AWS_SECRET_ACCESS_KEY      # AWS secret key
S3_BUCKET                  # S3 bucket name (e.g., devdem-1234)
CLOUDFRONT_DISTRIBUTION_ID # CloudFront distribution ID
EC2_HOST                   # EC2 public IP: 18.210.24.182
EC2_USER                   # EC2 username: ubuntu
EC2_SSH_KEY                # EC2 private key content
BACKEND_API_URL            # Backend API URL: http://18.210.24.182:5000
\`\`\`

### Trigger Deployment

\`\`\`bash
git add .
git commit -m "Deploy to production"
git push origin main
\`\`\`

## 📤 Deployment

### Current Production Deployment

**Backend (EC2 + Docker):**
- Instance: `devdemo` (Ubuntu 24.04.3 LTS)
- Public IP: `18.210.24.182`
- Container: `devdemo-backend` (running 9+ hours)
- Status: ✅ Healthy
- API: `http://18.210.24.182:5000`

**Frontend (S3 + CloudFront):**
- S3 Bucket: Static website hosting
- CloudFront: Global CDN distribution
- Deployment: Automated via GitHub Actions

### Deployment Process

1. **Automated CI/CD**: Push to `main` branch triggers GitHub Actions
2. **Backend**: Builds Docker image and deploys to EC2
3. **Frontend**: Builds React app and deploys to S3
4. **Cache**: Invalidates CloudFront cache for instant updates

### Manual Deployment Commands

**Backend:**
\`\`\`bash
# Connect to EC2
ssh -i devopsdemo.pem ubuntu@18.210.24.182

# Check container status
docker ps

# View logs
docker logs devdemo-backend

# Restart container if needed
docker restart devdemo-backend
\`\`\`

**Frontend:**
\`\`\`bash
cd frontend
npm run build
aws s3 sync dist/ s3://devdem-XXXX --delete
aws cloudfront create-invalidation --distribution-id EXXXXXXXXXX --paths "/*"
\`\`\`

## 📊 Monitoring

### CloudWatch Dashboard

Access at: AWS Console → CloudWatch → Dashboards → `devops-demo-dashboard`

**Metrics Monitored:**
- EC2 CPU utilization
- ALB response time
- Request count
- Unhealthy host count

### CloudWatch Alarms

- **High CPU**: Alerts when EC2 CPU > 80%
- **Unhealthy Hosts**: Alerts when targets are unhealthy

### Logs

\`\`\`bash
# View EC2 logs
aws logs tail /aws/ec2/devdemo --follow

# View application logs on EC2
ssh -i devops-demo-key.pem ec2-user@<EC2_PUBLIC_IP>
docker logs -f devops-backend
\`\`\`


## 📄 License

MIT License - feel free to use this project for learning and development.

## 👥 Support

For issues and questions:
- Open a GitHub issue
- Check existing documentation
- Review CloudWatch logs

---

**Built with ❤️ for DevOps learning and demonstration**
