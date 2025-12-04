# AWS Deployment Guide - Without Nginx

This guide shows how to deploy your DevOps Demo application to AWS **without using Nginx**.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Frontend Deployment (S3 + CloudFront)](#frontend-deployment-s3--cloudfront)
- [Backend Deployment Options](#backend-deployment-options)
  - [Option 1: EC2 + Docker + ALB](#option-1-ec2--docker--alb-recommended)
  - [Option 2: Elastic Beanstalk](#option-2-elastic-beanstalk-easiest)
  - [Option 3: AWS Lambda (Serverless)](#option-3-aws-lambda-serverless)
  - [Option 4: ECS Fargate](#option-4-ecs-fargate)
  - [Option 5: App Runner](#option-5-app-runner)
- [Complete Deployment Steps](#complete-deployment-steps)
- [Cost Comparison](#cost-comparison)

---

## Architecture Overview

### Without Nginx Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Users                                │
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
│  (Static HTML)  │            │  Docker Container│
│  (No Nginx!)    │            │   Node.js:5000   │
│                 │            │   (No Nginx!)    │
└─────────────────┘            └──────────────────┘
```

**Key Points:**
- ✅ Frontend: Static files served directly from S3 via CloudFront
- ✅ Backend: Express.js handles HTTP directly on port 5000
- ✅ No Nginx required for either frontend or backend
- ✅ ALB provides load balancing and SSL termination

---

## Frontend Deployment (S3 + CloudFront)

### Why No Nginx for Frontend?

React builds to static HTML/CSS/JS files that can be served directly from S3. CloudFront acts as the CDN.

### Deployment Steps

#### 1. Build the React App

```bash
cd frontend
npm install
npm run build
```

This creates a `dist/` folder with optimized static files.

#### 2. Create S3 Bucket (via Terraform)

Your `infrastructure/s3.tf` already configures this:

```bash
cd infrastructure
terraform init
terraform apply
```

#### 3. Upload to S3

```bash
# Get bucket name from Terraform output
terraform output s3_bucket_name

# Sync files to S3
aws s3 sync ../frontend/dist/ s3://YOUR-BUCKET-NAME --delete

# Set proper content types
aws s3 cp ../frontend/dist/ s3://YOUR-BUCKET-NAME/ --recursive \
  --exclude "*" --include "*.html" --content-type "text/html" \
  --metadata-directive REPLACE

aws s3 cp ../frontend/dist/ s3://YOUR-BUCKET-NAME/ --recursive \
  --exclude "*" --include "*.js" --content-type "application/javascript" \
  --metadata-directive REPLACE

aws s3 cp ../frontend/dist/ s3://YOUR-BUCKET-NAME/ --recursive \
  --exclude "*" --include "*.css" --content-type "text/css" \
  --metadata-directive REPLACE
```

#### 4. Invalidate CloudFront Cache

```bash
# Get CloudFront distribution ID
terraform output cloudfront_distribution_id

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

#### 5. Access Your Frontend

```bash
# Get CloudFront URL
terraform output cloudfront_url

# Open in browser
https://YOUR_CLOUDFRONT_URL
```

---

## Backend Deployment Options

### Option 1: EC2 + Docker + ALB (Recommended)

**Current setup - No Nginx needed!**

#### Architecture
```
ALB → EC2 → Docker → Node.js Express (Port 5000)
```

#### Deployment Steps

**1. Build Docker Image**

```bash
cd backend
docker build -t devops-demo-backend .
```

**2. Create ECR Repository**

```bash
aws ecr create-repository --repository-name devops-demo-backend
```

**3. Push to ECR**

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag image
docker tag devops-demo-backend:latest \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-demo-backend:latest

# Push image
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-demo-backend:latest
```

**4. Deploy Infrastructure**

```bash
cd infrastructure
terraform apply
```

**5. Deploy to EC2**

```bash
# SSH to EC2
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Pull and run
docker pull YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-demo-backend:latest

docker run -d \
  --name devops-backend \
  -p 5000:5000 \
  --restart unless-stopped \
  -e NODE_ENV=production \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-demo-backend:latest

# Check logs
docker logs -f devops-backend
```

**6. Test Backend**

```bash
# Get ALB DNS from Terraform
terraform output alb_dns_name

# Test health endpoint
curl http://YOUR_ALB_DNS/api/health
```

**Cost:** ~$10-15/month (t3.micro EC2)

---

### Option 2: Elastic Beanstalk (Easiest)

**No Docker, No Nginx - Just Node.js!**

#### Setup

**1. Install EB CLI**

```bash
pip install awsebcli
```

**2. Initialize EB**

```bash
cd backend
eb init -p node.js-20 devops-demo-backend --region us-east-1
```

**3. Create Environment**

```bash
eb create devops-demo-backend-env \
  --instance-type t3.micro \
  --envvars NODE_ENV=production,PORT=5000
```

**4. Deploy**

```bash
eb deploy
```

**5. Open Application**

```bash
eb open
```

**6. View Logs**

```bash
eb logs
```

**7. Update Application**

```bash
# Make changes to code
eb deploy
```

**Cost:** ~$15-20/month (includes load balancer)

---

### Option 3: AWS Lambda (Serverless)

**No servers at all!**

#### Setup

**1. Install Dependencies**

```bash
cd backend
npm install serverless-http
```

**2. Create Lambda Handler**

The `lambda.js` file is already created in your backend folder.

**3. Create SAM Template**

```bash
# Create template.yaml
cat > template.yaml << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  BackendFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: lambda.handler
      Runtime: nodejs20.x
      MemorySize: 512
      Timeout: 30
      Environment:
        Variables:
          NODE_ENV: production
      Events:
        ApiRoot:
          Type: Api
          Properties:
            Path: /
            Method: ANY
        ApiProxy:
          Type: Api
          Properties:
            Path: /{proxy+}
            Method: ANY

Outputs:
  ApiUrl:
    Description: API Gateway endpoint URL
    Value: !Sub 'https://${ServerlessRestApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/'
EOF
```

**4. Deploy with SAM**

```bash
# Install SAM CLI
pip install aws-sam-cli

# Build
sam build

# Deploy
sam deploy --guided
```

**5. Get API URL**

```bash
sam list endpoints --output json
```

**Cost:** ~$0-5/month (pay per request)

---

### Option 4: ECS Fargate

**Containers without managing servers**

#### Setup

**1. Create ECS Cluster**

```bash
aws ecs create-cluster --cluster-name devops-demo-cluster
```

**2. Create Task Definition**

```bash
cat > task-definition.json << 'EOF'
{
  "family": "devops-demo-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "YOUR_ECR_URI:latest",
      "portMappings": [
        {
          "containerPort": 5000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "5000"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/devops-demo-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://task-definition.json
```

**3. Create Service**

```bash
aws ecs create-service \
  --cluster devops-demo-cluster \
  --service-name devops-demo-backend \
  --task-definition devops-demo-backend \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

**Cost:** ~$15-20/month

---

### Option 5: App Runner

**Easiest container deployment**

#### Setup

**1. Push Code to GitHub**

```bash
git add .
git commit -m "Deploy to App Runner"
git push origin main
```

**2. Create App Runner Service (AWS Console)**

1. Go to AWS App Runner console
2. Click "Create service"
3. Choose "Source code repository"
4. Connect to GitHub
5. Select your repository
6. Configure:
   - Runtime: Node.js 20
   - Build command: `npm install`
   - Start command: `npm start`
   - Port: 5000
7. Click "Create & deploy"

**3. Access Your API**

App Runner provides a URL like: `https://xxx.us-east-1.awsapprunner.com`

**Cost:** ~$5-10/month

---

## Complete Deployment Steps

### Full Stack Deployment (Recommended)

**Frontend: S3 + CloudFront**
**Backend: EC2 + Docker + ALB**

```bash
# 1. Deploy Infrastructure
cd infrastructure
terraform init
terraform apply

# 2. Build and Deploy Frontend
cd ../frontend
npm install
npm run build
aws s3 sync dist/ s3://$(terraform -chdir=../infrastructure output -raw s3_bucket_name) --delete
aws cloudfront create-invalidation \
  --distribution-id $(terraform -chdir=../infrastructure output -raw cloudfront_distribution_id) \
  --paths "/*"

# 3. Build and Push Backend
cd ../backend
docker build -t devops-demo-backend .
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
docker tag devops-demo-backend:latest \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/devops-demo-backend:latest
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/devops-demo-backend:latest

# 4. Deploy to EC2
EC2_IP=$(terraform -chdir=../infrastructure output -raw ec2_public_ip)
ssh -i your-key.pem ec2-user@$EC2_IP << 'ENDSSH'
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
docker pull $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/devops-demo-backend:latest
docker stop devops-backend || true
docker rm devops-backend || true
docker run -d --name devops-backend -p 5000:5000 --restart unless-stopped \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/devops-demo-backend:latest
ENDSSH

# 5. Test Deployment
echo "Frontend: https://$(terraform -chdir=../infrastructure output -raw cloudfront_url)"
echo "Backend: http://$(terraform -chdir=../infrastructure output -raw alb_dns_name)/api/health"
```

---

## Cost Comparison

| Option | Monthly Cost | Pros | Cons |
|--------|-------------|------|------|
| **S3 + CloudFront** (Frontend) | $1-5 | Cheap, scalable, fast | Static only |
| **EC2 + Docker + ALB** (Backend) | $10-15 | Full control, predictable | Manual scaling |
| **Elastic Beanstalk** | $15-20 | Easy, auto-scaling | Less control |
| **Lambda + API Gateway** | $0-5 | Serverless, cheap | Cold starts |
| **ECS Fargate** | $15-20 | Containers, no servers | More complex |
| **App Runner** | $5-10 | Easiest, auto-scaling | Less control |

---

## Monitoring

### CloudWatch Logs

**Backend Logs:**
```bash
aws logs tail /aws/ec2/devops-demo-backend --follow
```

**Lambda Logs:**
```bash
aws logs tail /aws/lambda/BackendFunction --follow
```

### Health Checks

**Backend Health:**
```bash
curl http://YOUR_ALB_DNS/api/health
```

**Frontend:**
```bash
curl https://YOUR_CLOUDFRONT_URL
```

---

## Troubleshooting

### Frontend Issues

**Problem: 404 errors on refresh**
- Solution: CloudFront custom error responses already configured in Terraform

**Problem: Old content showing**
- Solution: Invalidate CloudFront cache
```bash
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

### Backend Issues

**Problem: Container won't start**
```bash
ssh -i key.pem ec2-user@EC2_IP
docker logs devops-backend
```

**Problem: ALB health check failing**
- Check security group allows traffic on port 5000
- Verify `/api/health` endpoint is responding

---

## CI/CD Integration

### GitHub Actions (Already Configured)

Your `.github/workflows/deploy.yml` handles:
1. Build frontend → Deploy to S3
2. Build backend → Push to ECR → Deploy to EC2

Just push to main branch:
```bash
git push origin main
```

---

## Summary

✅ **No Nginx Required!**
- Frontend: S3 serves static files directly
- Backend: Express.js handles HTTP on port 5000
- ALB provides load balancing and SSL

✅ **Recommended Setup:**
- Frontend: S3 + CloudFront ($1-5/month)
- Backend: EC2 + Docker + ALB ($10-15/month)
- Total: ~$15-20/month

✅ **Alternative (Cheapest):**
- Frontend: S3 + CloudFront ($1-5/month)
- Backend: Lambda + API Gateway ($0-5/month)
- Total: ~$5-10/month

---

## Next Steps

1. Deploy infrastructure: `terraform apply`
2. Build and deploy frontend to S3
3. Build and deploy backend (choose your option)
4. Configure custom domain (optional)
5. Set up monitoring and alerts
6. Configure CI/CD pipeline

**Your application is production-ready without Nginx!**
