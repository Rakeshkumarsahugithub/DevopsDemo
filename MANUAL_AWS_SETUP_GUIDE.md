# Manual AWS Setup Guide (Without Terraform)

Complete step-by-step guide to deploy your DevOps Demo to AWS manually, then setup GitHub Actions for CI/CD.

---

## 📋 Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Create S3 Bucket for Frontend](#2-create-s3-bucket-for-frontend)
3. [Create CloudFront Distribution](#3-create-cloudfront-distribution)
4. [Create ECR Repository](#4-create-ecr-repository)
5. [Create EC2 Instance for Backend](#5-create-ec2-instance-for-backend)
6. [Create Application Load Balancer](#6-create-application-load-balancer)
7. [Deploy Frontend to S3](#7-deploy-frontend-to-s3)
8. [Deploy Backend to EC2](#8-deploy-backend-to-ec2)
9. [Setup GitHub Actions](#9-setup-github-actions)
10. [Test Deployment](#10-test-deployment)

---

## 1. Prerequisites

### Install Required Tools

**AWS CLI:**
```powershell
# Download and install
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Verify
aws --version
```

**Configure AWS CLI:**
```powershell
aws configure

# Enter:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json
```

**Verify Configuration:**
```powershell
aws sts get-caller-identity
```

---

## 2. Create S3 Bucket for Frontend

### Step 2.1: Create S3 Bucket

```powershell
# Set variables
$BUCKET_NAME = "devdem-$(Get-Random -Maximum 9999)"
$REGION = "us-east-1"

# Create bucket
aws s3api create-bucket `
  --bucket $BUCKET_NAME `
  --region $REGION

# Save bucket name for later
$BUCKET_NAME | Out-File -FilePath bucket-name.txt
Write-Host "Bucket created: $BUCKET_NAME"
```

### Step 2.2: Configure Bucket for Static Website Hosting

```powershell
# Enable static website hosting
aws s3 website s3://$BUCKET_NAME/ `
  --index-document index.html `
  --error-document index.html
```

### Step 2.3: Disable Block Public Access

```powershell
aws s3api put-public-access-block `
  --bucket $BUCKET_NAME `
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
```

### Step 2.4: Add Bucket Policy

Create a file `bucket-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
    }
  ]
}
```

Replace `YOUR_BUCKET_NAME` and apply:
```powershell
# Replace bucket name in policy
(Get-Content bucket-policy.json) -replace 'YOUR_BUCKET_NAME', $BUCKET_NAME | Set-Content bucket-policy.json

# Apply policy
aws s3api put-bucket-policy `
  --bucket $BUCKET_NAME `
  --policy file://bucket-policy.json
```

### Step 2.5: Enable CORS

Create `cors-config.json`:
```json
{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}
```

Apply CORS:
```powershell
aws s3api put-bucket-cors `
  --bucket $BUCKET_NAME `
  --cors-configuration file://cors-config.json
```

---

## 3. Create CloudFront Distribution

### Step 3.1: Create Distribution Configuration

Create `cloudfront-config.json`:
```json
{
  "CallerReference": "devops-demo-TIMESTAMP",
  "Comment": "DevOps Demo Frontend Distribution",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-devdem-frontend",
        "DomainName": "YOUR_BUCKET_NAME.s3-website-us-east-1.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-devdem-frontend",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 3,
      "Items": ["GET", "HEAD", "OPTIONS"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 3600,
    "MaxTTL": 86400,
    "Compress": true
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      },
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "PriceClass": "PriceClass_100",
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true
  }
}
```

### Step 3.2: Create Distribution

```powershell
# Replace bucket name and timestamp
$TIMESTAMP = Get-Date -Format "yyyyMMddHHmmss"
$WEBSITE_ENDPOINT = "$BUCKET_NAME.s3-website-$REGION.amazonaws.com"

(Get-Content cloudfront-config.json) `
  -replace 'YOUR_BUCKET_NAME', $BUCKET_NAME `
  -replace 'TIMESTAMP', $TIMESTAMP | Set-Content cloudfront-config.json

# Create distribution
$DISTRIBUTION = aws cloudfront create-distribution `
  --distribution-config file://cloudfront-config.json `
  --output json | ConvertFrom-Json

$DISTRIBUTION_ID = $DISTRIBUTION.Distribution.Id
$CLOUDFRONT_URL = $DISTRIBUTION.Distribution.DomainName

# Save for later
$DISTRIBUTION_ID | Out-File -FilePath cloudfront-id.txt
$CLOUDFRONT_URL | Out-File -FilePath cloudfront-url.txt

Write-Host "CloudFront Distribution ID: $DISTRIBUTION_ID"
Write-Host "CloudFront URL: https://$CLOUDFRONT_URL"
Write-Host "Note: Distribution deployment takes 15-20 minutes"
```

---

## 4. Create ECR Repository

### Step 4.1: Create Repository

```powershell
# Create ECR repository for backend
aws ecr create-repository `
  --repository-name devdemo-backend `
  --region $REGION

# Get repository URI
$ECR_URI = aws ecr describe-repositories `
  --repository-names devdemo-backend `
  --query 'repositories[0].repositoryUri' `
  --output text

# Save for later
$ECR_URI | Out-File -FilePath ecr-uri.txt
Write-Host "ECR Repository URI: $ECR_URI"
```

---

## 5. Create EC2 Instance for Backend

### Step 5.1: Create Key Pair

```powershell
# Create EC2 key pair
aws ec2 create-key-pair `
  --key-name devops-demo-key `
  --query 'KeyMaterial' `
  --output text | Out-File -Encoding ASCII devops-demo-key.pem

Write-Host "Key pair created: devops-demo-key.pem"
Write-Host "IMPORTANT: Save this file securely!"
```

### Step 5.2: Create Security Group

```powershell
# Get default VPC ID
$VPC_ID = aws ec2 describe-vpcs `
  --filters "Name=isDefault,Values=true" `
  --query 'Vpcs[0].VpcId' `
  --output text

# Create security group for EC2
$SG_ID = aws ec2 create-security-group `
  --group-name devops-demo-ec2-sg `
  --description "Security group for DevOps Demo EC2" `
  --vpc-id $VPC_ID `
  --query 'GroupId' `
  --output text

Write-Host "Security Group ID: $SG_ID"

# Allow SSH (port 22) from your IP
$MY_IP = (Invoke-WebRequest -Uri "https://api.ipify.org").Content
aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID `
  --protocol tcp `
  --port 22 `
  --cidr "$MY_IP/32"

# Allow HTTP (port 5000) from anywhere (for ALB)
aws ec2 authorize-security-group-ingress `
  --group-id $SG_ID `
  --protocol tcp `
  --port 5000 `
  --cidr 0.0.0.0/0

Write-Host "Security group configured"
```

### Step 5.3: Create IAM Role for EC2

```powershell
# Create trust policy
@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@ | Out-File -Encoding ASCII ec2-trust-policy.json

# Create IAM role
aws iam create-role `
  --role-name devops-demo-ec2-role `
  --assume-role-policy-document file://ec2-trust-policy.json

# Attach ECR read-only policy
aws iam attach-role-policy `
  --role-name devops-demo-ec2-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Attach CloudWatch policy
aws iam attach-role-policy `
  --role-name devops-demo-ec2-role `
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

# Create instance profile
aws iam create-instance-profile `
  --instance-profile-name devops-demo-ec2-profile

# Add role to instance profile
aws iam add-role-to-instance-profile `
  --instance-profile-name devops-demo-ec2-profile `
  --role-name devops-demo-ec2-role

Write-Host "IAM role created"
Start-Sleep -Seconds 10  # Wait for IAM propagation
```

### Step 5.4: Create User Data Script

Create `user-data.sh`:
```bash
#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Create application directory
mkdir -p /opt/devops-demo
cd /opt/devops-demo

echo "EC2 instance setup completed"
```

### Step 5.5: Launch EC2 Instance

```powershell
# Get latest Amazon Linux 2023 AMI
$AMI_ID = aws ec2 describe-images `
  --owners amazon `
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" `
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' `
  --output text

# Launch instance
$INSTANCE_ID = aws ec2 run-instances `
  --image-id $AMI_ID `
  --instance-type t3.micro `
  --key-name devops-demo-key `
  --security-group-ids $SG_ID `
  --iam-instance-profile Name=devops-demo-ec2-profile `
  --user-data file://user-data.sh `
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=devdemo}]' `
  --query 'Instances[0].InstanceId' `
  --output text

Write-Host "EC2 Instance ID: $INSTANCE_ID"
Write-Host "Waiting for instance to start..."

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP
$EC2_PUBLIC_IP = aws ec2 describe-instances `
  --instance-ids $INSTANCE_ID `
  --query 'Reservations[0].Instances[0].PublicIpAddress' `
  --output text

# Save for later
$EC2_PUBLIC_IP | Out-File -FilePath ec2-ip.txt
Write-Host "EC2 Public IP: $EC2_PUBLIC_IP"
Write-Host "Wait 2-3 minutes for user data script to complete"
```

---

## 6. Create Application Load Balancer

### Step 6.1: Create ALB Security Group

```powershell
# Create security group for ALB
$ALB_SG_ID = aws ec2 create-security-group `
  --group-name devops-demo-alb-sg `
  --description "Security group for DevOps Demo ALB" `
  --vpc-id $VPC_ID `
  --query 'GroupId' `
  --output text

# Allow HTTP (port 80) from anywhere
aws ec2 authorize-security-group-ingress `
  --group-id $ALB_SG_ID `
  --protocol tcp `
  --port 80 `
  --cidr 0.0.0.0/0

# Allow HTTPS (port 443) from anywhere
aws ec2 authorize-security-group-ingress `
  --group-id $ALB_SG_ID `
  --protocol tcp `
  --port 443 `
  --cidr 0.0.0.0/0

Write-Host "ALB Security Group ID: $ALB_SG_ID"
```

### Step 6.2: Get Subnets

```powershell
# Get subnets in default VPC
$SUBNETS = aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=$VPC_ID" `
  --query 'Subnets[*].SubnetId' `
  --output text

$SUBNET_IDS = $SUBNETS -split '\s+'
Write-Host "Subnets: $SUBNET_IDS"
```

### Step 6.3: Create Application Load Balancer

```powershell
# Create ALB
$ALB_ARN = aws elbv2 create-load-balancer `
  --name devops-demo-alb `
  --subnets $SUBNET_IDS[0] $SUBNET_IDS[1] `
  --security-groups $ALB_SG_ID `
  --scheme internet-facing `
  --type application `
  --ip-address-type ipv4 `
  --query 'LoadBalancers[0].LoadBalancerArn' `
  --output text

# Get ALB DNS name
$ALB_DNS = aws elbv2 describe-load-balancers `
  --load-balancer-arns $ALB_ARN `
  --query 'LoadBalancers[0].DNSName' `
  --output text

# Save for later
$ALB_DNS | Out-File -FilePath alb-dns.txt
Write-Host "ALB DNS: $ALB_DNS"
```

### Step 6.4: Create Target Group

```powershell
# Create target group
$TG_ARN = aws elbv2 create-target-group `
  --name devops-demo-tg `
  --protocol HTTP `
  --port 5000 `
  --vpc-id $VPC_ID `
  --health-check-enabled `
  --health-check-protocol HTTP `
  --health-check-path /api/health `
  --health-check-interval-seconds 30 `
  --health-check-timeout-seconds 5 `
  --healthy-threshold-count 2 `
  --unhealthy-threshold-count 3 `
  --query 'TargetGroups[0].TargetGroupArn' `
  --output text

Write-Host "Target Group ARN: $TG_ARN"
```

### Step 6.5: Register EC2 Instance with Target Group

```powershell
# Register instance
aws elbv2 register-targets `
  --target-group-arn $TG_ARN `
  --targets Id=$INSTANCE_ID

Write-Host "EC2 instance registered with target group"
```

### Step 6.6: Create Listener

```powershell
# Create HTTP listener
aws elbv2 create-listener `
  --load-balancer-arn $ALB_ARN `
  --protocol HTTP `
  --port 80 `
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

Write-Host "ALB listener created"
Write-Host "ALB URL: http://$ALB_DNS"
```

---

## 7. Deploy Frontend to S3

### Step 7.1: Build Frontend

```powershell
cd frontend

# Install dependencies
npm install

# Build for production
npm run build

Write-Host "Frontend built successfully"
```

### Step 7.2: Upload to S3

```powershell
# Get bucket name
$BUCKET_NAME = Get-Content ../bucket-name.txt

# Upload files
aws s3 sync dist/ s3://$BUCKET_NAME --delete

Write-Host "Frontend deployed to S3"
```

### Step 7.3: Invalidate CloudFront Cache

```powershell
# Get distribution ID
$DISTRIBUTION_ID = Get-Content ../cloudfront-id.txt

# Create invalidation
aws cloudfront create-invalidation `
  --distribution-id $DISTRIBUTION_ID `
  --paths "/*"

Write-Host "CloudFront cache invalidated"
```

---

## 8. Deploy Backend to EC2

### Step 8.1: Build and Push Docker Image

```powershell
cd ../backend

# Get ECR URI
$ECR_URI = Get-Content ../ecr-uri.txt
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# Login to ECR
aws ecr get-login-password --region us-east-1 | `
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Build image
docker build -t devdemo-backend .

# Tag image
docker tag devdemo-backend:latest "$ECR_URI:latest"

# Push to ECR
docker push "$ECR_URI:latest"

Write-Host "Backend image pushed to ECR"
```

### Step 8.2: Deploy to EC2

```powershell
# Get EC2 IP
$EC2_IP = Get-Content ../ec2-ip.txt

# SSH to EC2 and deploy
ssh -i ../devops-demo-key.pem ec2-user@$EC2_IP @"
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

# Pull image
docker pull $ECR_URI:latest

# Stop old container
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

# Check status
docker ps
docker logs devops-backend
"@

Write-Host "Backend deployed to EC2"
```

---

## 9. Setup GitHub Actions

### Step 9.1: Collect All Information

Create a file `deployment-info.txt` with all the values:

```powershell
@"
AWS_ACCESS_KEY_ID: (Get from AWS IAM Console)
AWS_SECRET_ACCESS_KEY: (Get from AWS IAM Console)
AWS_REGION: us-east-1
ECR_REPOSITORY: devdemo-backend
S3_BUCKET: $(Get-Content bucket-name.txt)
CLOUDFRONT_DISTRIBUTION_ID: $(Get-Content cloudfront-id.txt)
EC2_HOST: $(Get-Content ec2-ip.txt)
EC2_USER: ec2-user
EC2_SSH_KEY: (Content of devops-demo-key.pem)
BACKEND_API_URL: $(Get-Content alb-dns.txt)
"@ | Out-File -FilePath deployment-info.txt

Write-Host "Deployment info saved to deployment-info.txt"
notepad deployment-info.txt
```

### Step 9.2: Add GitHub Secrets

1. Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret from `deployment-info.txt`

**Required Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `ECR_REPOSITORY`
- `S3_BUCKET`
- `CLOUDFRONT_DISTRIBUTION_ID`
- `EC2_HOST`
- `EC2_USER`
- `EC2_SSH_KEY` (entire content of devops-demo-key.pem)
- `BACKEND_API_URL`

### Step 9.3: Get EC2 SSH Key Content

```powershell
# Display key content
Get-Content devops-demo-key.pem

# Copy the entire output including:
# -----BEGIN RSA PRIVATE KEY-----
# ...
# -----END RSA PRIVATE KEY-----
```

### Step 9.4: Update Frontend API URL

```powershell
cd frontend

# Get ALB DNS
$ALB_DNS = Get-Content ../alb-dns.txt

# Update .env
@"
VITE_API_URL=http://$ALB_DNS
"@ | Out-File -Encoding ASCII .env

# Rebuild and redeploy
npm run build
$BUCKET_NAME = Get-Content ../bucket-name.txt
aws s3 sync dist/ s3://$BUCKET_NAME --delete

# Invalidate CloudFront
$DISTRIBUTION_ID = Get-Content ../cloudfront-id.txt
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
```

### Step 9.5: Test GitHub Actions

```powershell
cd ..

# Make a small change
"# Test deployment" | Out-File -Append README.md

# Commit and push
git add .
git commit -m "Test GitHub Actions deployment"
git push origin main
```

Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/actions

Watch the workflow run!

---

## 10. Test Deployment

### Step 10.1: Test Frontend

```powershell
# Get CloudFront URL
$CF_URL = Get-Content cloudfront-url.txt

# Open in browser
Start-Process "https://$CF_URL"
```

### Step 10.2: Test Backend

```powershell
# Get ALB DNS
$ALB_DNS = Get-Content alb-dns.txt

# Test health endpoint
curl "http://$ALB_DNS/api/health"

# Test messages endpoint
curl "http://$ALB_DNS/api/messages"
```

### Step 10.3: Test Responsive Design

1. Open CloudFront URL in browser
2. Press F12 (DevTools)
3. Press Ctrl+Shift+M (Device Toolbar)
4. Test different screen sizes

---

## 📝 Summary of Created Resources

Save this information:

```powershell
@"
=== AWS Resources Created ===

S3 Bucket: $(Get-Content bucket-name.txt)
CloudFront Distribution ID: $(Get-Content cloudfront-id.txt)
CloudFront URL: https://$(Get-Content cloudfront-url.txt)
ECR Repository URI: $(Get-Content ecr-uri.txt)
EC2 Instance ID: $INSTANCE_ID
EC2 Public IP: $(Get-Content ec2-ip.txt)
ALB DNS: http://$(Get-Content alb-dns.txt)
Security Group (EC2): $SG_ID
Security Group (ALB): $ALB_SG_ID
Target Group ARN: $TG_ARN
IAM Role: devops-demo-ec2-role
Key Pair: devops-demo-key.pem

=== Access URLs ===

Frontend: https://$(Get-Content cloudfront-url.txt)
Backend: http://$(Get-Content alb-dns.txt)
Health Check: http://$(Get-Content alb-dns.txt)/api/health
Messages API: http://$(Get-Content alb-dns.txt)/api/messages

=== GitHub Repository ===

https://github.com/Rakeshkumarsahugithub/DevopsDemo
"@ | Out-File -FilePath aws-resources.txt

notepad aws-resources.txt
```

---

## 🧹 Cleanup (When Done)

To delete all resources:

```powershell
# Delete CloudFront distribution (must disable first)
aws cloudfront get-distribution-config --id $DISTRIBUTION_ID
# Manually disable in AWS Console, then delete

# Empty and delete S3 bucket
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3api delete-bucket --bucket $BUCKET_NAME

# Delete ECR repository
aws ecr delete-repository --repository-name devdemo-backend --force

# Terminate EC2 instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Delete ALB
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN

# Delete target group (wait for ALB to delete first)
Start-Sleep -Seconds 60
aws elbv2 delete-target-group --target-group-arn $TG_ARN

# Delete security groups
aws ec2 delete-security-group --group-id $SG_ID
aws ec2 delete-security-group --group-id $ALB_SG_ID

# Delete IAM resources
aws iam remove-role-from-instance-profile --instance-profile-name devops-demo-ec2-profile --role-name devops-demo-ec2-role
aws iam delete-instance-profile --instance-profile-name devops-demo-ec2-profile
aws iam detach-role-policy --role-name devops-demo-ec2-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam detach-role-policy --role-name devops-demo-ec2-role --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
aws iam delete-role --role-name devops-demo-ec2-role

# Delete key pair
aws ec2 delete-key-pair --key-name devops-demo-key
```

---

## 🎉 Congratulations!

You've successfully deployed your DevOps Demo to AWS manually!

**What you have:**
- ✅ Frontend on S3 + CloudFront
- ✅ Backend on EC2 with Docker
- ✅ Application Load Balancer
- ✅ GitHub Actions CI/CD
- ✅ Fully responsive design
- ✅ No Nginx required!

**Estimated Cost:** ~$31-37/month

**Next Steps:**
- Monitor CloudWatch logs
- Set up custom domain (optional)
- Configure HTTPS for backend (optional)
- Set up auto-scaling (optional)
