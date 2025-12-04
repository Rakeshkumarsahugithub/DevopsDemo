# Complete Deployment Guide - Step by Step

This guide provides complete step-by-step instructions for deploying your DevOps Demo application to AWS using EC2, S3+CloudFront, and GitHub Actions.

---

## Table of Contents

1. [Local Container Testing](#1-local-container-testing)
2. [AWS Prerequisites](#2-aws-prerequisites)
3. [EC2 + S3 Deployment](#3-ec2--s3-deployment)
4. [GitHub Actions CI/CD](#4-github-actions-cicd)
5. [Verification](#5-verification)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Local Container Testing

### 1.1 Start Docker Desktop

**Windows:**
```powershell
# Start Docker Desktop from Start Menu
# Or run:
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait for Docker to start (check system tray icon)
# Verify Docker is running:
docker info
```

### 1.2 Build and Run Containers

```powershell
# Navigate to project root
cd C:\PRACTICE\devops demo

# Build images
docker-compose build

# Start containers
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 1.3 Test Locally

```powershell
# Test backend
curl http://localhost:5000/api/health

# Test frontend
# Open browser: http://localhost

# Stop containers
docker-compose down
```

---

## 2. AWS Prerequisites

### 2.1 Install AWS CLI

**Windows (PowerShell as Administrator):**
```powershell
# Download installer
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Verify installation
aws --version
```

### 2.2 Configure AWS Credentials

```powershell
# Configure AWS CLI
aws configure

# Enter your credentials:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

**Output should show:**
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### 2.3 Install Terraform

**Windows (PowerShell as Administrator):**
```powershell
# Using Chocolatey
choco install terraform

# Or download from: https://www.terraform.io/downloads

# Verify installation
terraform --version
```

### 2.4 Create EC2 Key Pair

```powershell
# Create key pair
aws ec2 create-key-pair `
  --key-name devops-demo-key `
  --query 'KeyMaterial' `
  --output text | Out-File -Encoding ASCII devops-demo-key.pem

# Verify key was created
aws ec2 describe-key-pairs --key-names devops-demo-key
```

**Save the key file in a secure location!**

---

## 3. EC2 + S3 Deployment

### Step 1: Configure Terraform Variables

```powershell
cd infrastructure

# Copy example file
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
notepad terraform.tfvars
```

**Update these values:**
```hcl
aws_region       = "us-east-1"
project_name     = "devops-demo"
environment      = "prod"
ec2_instance_type = "t3.micro"
ec2_key_name     = "devops-demo-key"  # The key you created
```

### Step 2: Deploy Infrastructure

```powershell
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Type 'yes' when prompted

# Wait 5-10 minutes for deployment to complete
```

**Save the outputs:**
```powershell
# Save all outputs to file
terraform output > ../deployment-outputs.txt

# View specific outputs
terraform output s3_bucket_name
terraform output cloudfront_url
terraform output ec2_public_ip
terraform output alb_dns_name
terraform output ecr_repository_url
```

### Step 3: Deploy Frontend to S3

```powershell
cd ../frontend

# Install dependencies
npm install

# Build for production
npm run build

# Get S3 bucket name
$BUCKET_NAME = terraform -chdir=../infrastructure output -raw s3_bucket_name

# Upload to S3
aws s3 sync dist/ s3://$BUCKET_NAME --delete

# Verify upload
aws s3 ls s3://$BUCKET_NAME/
```

**Expected output:**
```
2025-12-04 10:00:00        455 index.html
2025-12-04 10:00:00      70763 assets/index-B4vFKcRV.js
2025-12-04 10:00:00       1656 assets/index-DM8dfa5V.css
2025-12-04 10:00:00       1497 vite.svg
```

### Step 4: Invalidate CloudFront Cache

```powershell
# Get CloudFront distribution ID
$DIST_ID = terraform -chdir=../infrastructure output -raw cloudfront_distribution_id

# Invalidate cache
aws cloudfront create-invalidation `
  --distribution-id $DIST_ID `
  --paths "/*"

# Check invalidation status
aws cloudfront get-invalidation `
  --distribution-id $DIST_ID `
  --id INVALIDATION_ID
```

### Step 5: Deploy Backend to EC2

#### 5.1 Build and Push Docker Image to ECR

```powershell
cd ../backend

# Get ECR repository URL
$ECR_URI = terraform -chdir=../infrastructure output -raw ecr_repository_url

# Get AWS account ID
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# Login to ECR
aws ecr get-login-password --region us-east-1 | `
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Build Docker image
docker build -t devops-demo-backend .

# Tag image
docker tag devops-demo-backend:latest "$ECR_URI:latest"

# Push to ECR
docker push "$ECR_URI:latest"

# Verify image was pushed
aws ecr describe-images --repository-name devops-demo-backend
```

#### 5.2 Deploy to EC2

```powershell
# Get EC2 public IP
$EC2_IP = terraform -chdir=../infrastructure output -raw ec2_public_ip

# SSH to EC2 (use Git Bash or WSL for SSH)
ssh -i devops-demo-key.pem ec2-user@$EC2_IP
```

**On EC2 instance, run these commands:**

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# Get ECR URI
ECR_URI=$(aws ecr describe-repositories --repository-names devops-demo-backend --query 'repositories[0].repositoryUri' --output text)

# Pull image
docker pull $ECR_URI:latest

# Stop old container (if exists)
docker stop devops-backend 2>/dev/null || true
docker rm devops-backend 2>/dev/null || true

# Run new container
docker run -d \
  --name devops-backend \
  -p 5000:5000 \
  --restart unless-stopped \
  -e NODE_ENV=production \
  -e PORT=5000 \
  $ECR_URI:latest

# Check container status
docker ps

# View logs
docker logs -f devops-backend

# Test locally on EC2
curl http://localhost:5000/api/health

# Exit EC2
exit
```

### Step 6: Update Frontend API URL

```powershell
cd ../frontend

# Get ALB DNS name
$ALB_DNS = terraform -chdir=../infrastructure output -raw alb_dns_name

# Update .env file
@"
VITE_API_URL=http://$ALB_DNS
"@ | Out-File -Encoding ASCII .env

# Rebuild frontend
npm run build

# Redeploy to S3
$BUCKET_NAME = terraform -chdir=../infrastructure output -raw s3_bucket_name
aws s3 sync dist/ s3://$BUCKET_NAME --delete

# Invalidate CloudFront
$DIST_ID = terraform -chdir=../infrastructure output -raw cloudfront_distribution_id
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

### Step 7: Test Deployment

```powershell
# Get CloudFront URL
$CF_URL = terraform -chdir=../infrastructure output -raw cloudfront_url

# Test frontend
Start-Process "https://$CF_URL"

# Test backend via ALB
$ALB_DNS = terraform -chdir=../infrastructure output -raw alb_dns_name
curl "http://$ALB_DNS/api/health"
curl "http://$ALB_DNS/api/messages"
```

---

## 4. GitHub Actions CI/CD

### Step 1: Prepare GitHub Repository

```powershell
# Initialize git (if not already)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit - DevOps Demo"

# Create GitHub repository (via GitHub website)
# Then add remote
git remote add origin https://github.com/YOUR_USERNAME/devops-demo.git

# Push to GitHub
git push -u origin main
```

### Step 2: Configure GitHub Secrets

Go to your GitHub repository:
1. Click **Settings**
2. Click **Secrets and variables** → **Actions**
3. Click **New repository secret**

**Add these secrets:**

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS IAM Console |
| `AWS_REGION` | `us-east-1` | Your region |
| `ECR_REPOSITORY` | `devops-demo-backend` | Repository name |
| `S3_BUCKET` | Your bucket name | `terraform output s3_bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | Your distribution ID | `terraform output cloudfront_distribution_id` |
| `EC2_HOST` | Your EC2 public IP | `terraform output ec2_public_ip` |
| `EC2_USER` | `ec2-user` | Default for Amazon Linux |
| `EC2_SSH_KEY` | Content of devops-demo-key.pem | Copy entire file content |
| `BACKEND_API_URL` | Your ALB DNS | `terraform output alb_dns_name` |

**To get EC2_SSH_KEY content:**
```powershell
Get-Content devops-demo-key.pem | Out-String
```

Copy the entire output including:
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

### Step 3: Create GitHub Actions Workflow

```powershell
# Create workflow directory
New-Item -ItemType Directory -Force -Path .github/workflows

# Create workflow file
notepad .github/workflows/deploy.yml
```

**Copy this content:**

```yaml
name: Deploy to AWS

on:
  push:
    branches: [ main ]
  workflow_dispatch:

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}

jobs:
  deploy-frontend:
    name: Deploy Frontend to S3
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Build frontend
        working-directory: ./frontend
        env:
          VITE_API_URL: http://${{ secrets.BACKEND_API_URL }}
        run: npm run build

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Deploy to S3
        working-directory: ./frontend
        run: |
          aws s3 sync dist/ s3://${{ secrets.S3_BUCKET }} --delete

      - name: Invalidate CloudFront cache
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"

  deploy-backend:
    name: Deploy Backend to EC2
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image to Amazon ECR
        working-directory: ./backend
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      - name: Deploy to EC2
        env:
          EC2_HOST: ${{ secrets.EC2_HOST }}
          EC2_USER: ${{ secrets.EC2_USER }}
          EC2_SSH_KEY: ${{ secrets.EC2_SSH_KEY }}
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          # Save SSH key
          echo "$EC2_SSH_KEY" > private_key.pem
          chmod 600 private_key.pem
          
          # Deploy to EC2
          ssh -o StrictHostKeyChecking=no -i private_key.pem $EC2_USER@$EC2_HOST << 'ENDSSH'
            # Login to ECR
            aws ecr get-login-password --region ${{ secrets.AWS_REGION }} | \
              docker login --username AWS --password-stdin ${{ steps.login-ecr.outputs.registry }}
            
            # Pull latest image
            docker pull ${{ steps.login-ecr.outputs.registry }}/${{ secrets.ECR_REPOSITORY }}:latest
            
            # Stop and remove old container
            docker stop devops-backend || true
            docker rm devops-backend || true
            
            # Run new container
            docker run -d \
              --name devops-backend \
              -p 5000:5000 \
              --restart unless-stopped \
              -e NODE_ENV=production \
              -e PORT=5000 \
              ${{ steps.login-ecr.outputs.registry }}/${{ secrets.ECR_REPOSITORY }}:latest
            
            # Clean up old images
            docker image prune -af
          ENDSSH
          
          # Clean up SSH key
          rm -f private_key.pem

      - name: Verify deployment
        env:
          EC2_HOST: ${{ secrets.EC2_HOST }}
          EC2_USER: ${{ secrets.EC2_USER }}
          EC2_SSH_KEY: ${{ secrets.EC2_SSH_KEY }}
        run: |
          echo "$EC2_SSH_KEY" > private_key.pem
          chmod 600 private_key.pem
          
          ssh -o StrictHostKeyChecking=no -i private_key.pem $EC2_USER@$EC2_HOST << 'ENDSSH'
            # Check if container is running
            docker ps | grep devops-backend
            
            # Test health endpoint
            sleep 5
            curl -f http://localhost:5000/api/health || exit 1
          ENDSSH
          
          rm -f private_key.pem
```

### Step 4: Commit and Push Workflow

```powershell
# Add workflow file
git add .github/workflows/deploy.yml

# Commit
git commit -m "Add GitHub Actions deployment workflow"

# Push to GitHub
git push origin main
```

### Step 5: Monitor Deployment

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see the workflow running
4. Click on the workflow run to see details
5. Monitor each job (deploy-frontend, deploy-backend)

**Workflow will:**
- ✅ Build frontend
- ✅ Deploy to S3
- ✅ Invalidate CloudFront
- ✅ Build backend Docker image
- ✅ Push to ECR
- ✅ Deploy to EC2
- ✅ Verify deployment

---

## 5. Verification

### 5.1 Test Frontend

```powershell
# Get CloudFront URL
$CF_URL = terraform -chdir=infrastructure output -raw cloudfront_url

# Open in browser
Start-Process "https://$CF_URL"
```

**You should see:**
- ✅ DevOps Demo Application
- ✅ Backend health status showing "healthy"
- ✅ Messages from backend
- ✅ Responsive design working

### 5.2 Test Backend

```powershell
# Get ALB DNS
$ALB_DNS = terraform -chdir=infrastructure output -raw alb_dns_name

# Test health endpoint
curl "http://$ALB_DNS/api/health"

# Test messages endpoint
curl "http://$ALB_DNS/api/messages"
```

**Expected response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-12-04T10:30:00.000Z",
  "uptime": 123.456
}
```

### 5.3 Test Responsive Design

1. Open CloudFront URL in browser
2. Press **F12** (DevTools)
3. Press **Ctrl+Shift+M** (Device Toolbar)
4. Test these devices:
   - iPhone SE (375px)
   - iPhone 12 Pro (390px)
   - iPad (768px)
   - Desktop (1920px)

### 5.4 Check Logs

**CloudWatch Logs:**
```powershell
# View backend logs
aws logs tail /aws/ec2/devops-demo-backend --follow
```

**EC2 Container Logs:**
```powershell
# SSH to EC2
ssh -i devops-demo-key.pem ec2-user@$EC2_IP

# View container logs
docker logs -f devops-backend

# Exit
exit
```

---

## 6. Troubleshooting

### Frontend Issues

**Problem: 404 errors on page refresh**
- **Solution**: CloudFront custom error responses already configured
- Verify in AWS Console: CloudFront → Your Distribution → Error Pages

**Problem: Old content showing**
```powershell
# Invalidate CloudFront cache
$DIST_ID = terraform -chdir=infrastructure output -raw cloudfront_distribution_id
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"

# Check invalidation status
aws cloudfront list-invalidations --distribution-id $DIST_ID
```

**Problem: Can't connect to backend**
```powershell
# Check frontend .env file
Get-Content frontend/.env

# Should show:
# VITE_API_URL=http://YOUR_ALB_DNS

# If wrong, update and redeploy
```

### Backend Issues

**Problem: Container won't start**
```powershell
# SSH to EC2
ssh -i devops-demo-key.pem ec2-user@$EC2_IP

# Check container status
docker ps -a

# View logs
docker logs devops-backend

# Check if port is in use
sudo netstat -tulpn | grep 5000
```

**Problem: ALB health check failing**
```powershell
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups --query 'TargetGroups[0].TargetGroupArn' --output text)

# SSH to EC2 and test locally
ssh -i devops-demo-key.pem ec2-user@$EC2_IP
curl http://localhost:5000/api/health
```

**Problem: Can't pull from ECR**
```powershell
# Re-authenticate
aws ecr get-login-password --region us-east-1 | `
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Check ECR permissions
aws ecr get-repository-policy --repository-name devops-demo-backend
```

### GitHub Actions Issues

**Problem: Workflow fails on frontend build**
- Check Node.js version in workflow (should be 20)
- Verify package.json dependencies
- Check workflow logs for specific error

**Problem: Workflow fails on ECR push**
- Verify AWS credentials in GitHub Secrets
- Check ECR repository exists
- Verify IAM permissions for ECR

**Problem: Workflow fails on EC2 deployment**
- Verify EC2_SSH_KEY secret is correct (include BEGIN/END lines)
- Check EC2 security group allows SSH (port 22)
- Verify EC2 instance is running

**Problem: Workflow succeeds but app doesn't work**
- Check CloudWatch logs
- SSH to EC2 and check container logs
- Verify environment variables are set correctly

### Infrastructure Issues

**Problem: Terraform apply fails**
```powershell
# Refresh state
terraform refresh

# Re-run plan
terraform plan

# Check for specific errors in output
```

**Problem: EC2 can't access ECR**
- Verify IAM role is attached to EC2
- Check security group allows outbound HTTPS (port 443)
- Verify VPC has internet gateway

**Problem: S3 bucket access denied**
```powershell
# Check bucket policy
aws s3api get-bucket-policy --bucket YOUR_BUCKET_NAME

# Check bucket ACL
aws s3api get-bucket-acl --bucket YOUR_BUCKET_NAME
```

---

## Quick Reference Commands

### Local Development

```powershell
# Start Docker containers
docker-compose up -d

# View logs
docker-compose logs -f

# Stop containers
docker-compose down
```

### AWS Deployment

```powershell
# Deploy infrastructure
cd infrastructure && terraform apply

# Deploy frontend
cd frontend && npm run build
aws s3 sync dist/ s3://BUCKET_NAME --delete

# Deploy backend
cd backend && docker build -t backend .
docker push ECR_URI:latest
# Then SSH to EC2 and pull/run
```

### Monitoring

```powershell
# CloudWatch logs
aws logs tail /aws/ec2/devops-demo-backend --follow

# EC2 container logs
ssh -i key.pem ec2-user@EC2_IP
docker logs -f devops-backend

# Check deployment status
curl http://ALB_DNS/api/health
```

### GitHub Actions

```powershell
# Trigger manual deployment
# Go to GitHub → Actions → Deploy to AWS → Run workflow

# View logs
# GitHub → Actions → Click on workflow run
```

---

## Cost Summary

### Monthly Costs

| Service | Cost |
|---------|------|
| S3 Storage + Requests | $1-2 |
| CloudFront | $1-2 |
| EC2 t3.micro | $10-12 |
| EBS 20GB | $2 |
| ALB | $16-18 |
| Data Transfer | $1-2 |
| **Total** | **$31-37/month** |

### Cost Optimization

- ✅ Use AWS Free Tier (12 months)
- ✅ Stop EC2 when not in use (dev/test)
- ✅ Use S3 lifecycle policies
- ✅ Enable CloudFront caching
- ✅ Consider Reserved Instances

---

## Next Steps

### 1. Custom Domain (Optional)

```powershell
# Register domain in Route 53
# Create ACM certificate
# Update CloudFront distribution
# Update ALB listener
```

### 2. HTTPS for Backend

```powershell
# Request ACM certificate
# Add HTTPS listener to ALB
# Update security groups
# Update frontend VITE_API_URL to https://
```

### 3. Monitoring & Alerts

```powershell
# Set up CloudWatch alarms
# Configure SNS notifications
# Enable detailed monitoring
```

### 4. Auto Scaling (Optional)

```powershell
# Create launch template
# Create auto scaling group
# Configure scaling policies
```

---

## Summary

✅ **You now have:**
- Local Docker containers running
- Complete AWS infrastructure (Terraform)
- Frontend deployed to S3 + CloudFront
- Backend deployed to EC2 with Docker
- GitHub Actions CI/CD pipeline
- Fully responsive design
- No Nginx required!

✅ **Deployment flow:**
1. Push code to GitHub
2. GitHub Actions automatically:
   - Builds frontend → Deploys to S3
   - Builds backend → Pushes to ECR → Deploys to EC2
3. Application is live!

✅ **Cost:** ~$31-37/month (can be reduced with Free Tier)

**Your application is production-ready and fully automated!** 🚀

---

**For detailed information, see:**
- `EC2_DEPLOYMENT_GUIDE.md` - EC2 deployment details
- `RESPONSIVE_DESIGN.md` - Responsive design documentation
- `README.md` - Project overview
