# EC2 Deployment Guide - Without Nginx

Simple guide for deploying your DevOps Demo application to AWS using EC2 for backend and S3 for frontend.

---

## Architecture

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
- ✅ Frontend: Static files on S3, served via CloudFront
- ✅ Backend: Express.js on EC2 with Docker
- ✅ No Nginx required anywhere!
- ✅ ALB handles load balancing and SSL

---

## Prerequisites

- AWS Account
- AWS CLI configured (`aws configure`)
- Terraform installed
- Docker installed locally
- SSH key pair for EC2

---

## Step 1: Deploy Infrastructure with Terraform

### 1.1 Configure Variables

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region       = "us-east-1"
project_name     = "devops-demo"
environment      = "prod"
ec2_instance_type = "t3.micro"
ec2_key_name     = "your-key-pair-name"  # Your EC2 key pair
```

### 1.2 Create EC2 Key Pair (if needed)

```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name devops-demo-key \
  --query 'KeyMaterial' \
  --output text > devops-demo-key.pem

# Set permissions
chmod 400 devops-demo-key.pem
```

### 1.3 Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply

# Save outputs
terraform output > ../deployment-outputs.txt
```

**What gets created:**
- VPC with subnets
- S3 bucket for frontend
- CloudFront distribution
- EC2 instance for backend
- ECR repository for Docker images
- Application Load Balancer
- Security groups
- IAM roles

---

## Step 2: Deploy Frontend to S3

### 2.1 Build Frontend

```bash
cd ../frontend
npm install
npm run build
```

This creates a `dist/` folder with static files.

### 2.2 Get S3 Bucket Name

```bash
cd ../infrastructure
terraform output s3_bucket_name
```

### 2.3 Upload to S3

```bash
cd ../frontend

# Upload files
aws s3 sync dist/ s3://YOUR-BUCKET-NAME --delete

# Verify upload
aws s3 ls s3://YOUR-BUCKET-NAME/
```

### 2.4 Invalidate CloudFront Cache

```bash
# Get CloudFront distribution ID
cd ../infrastructure
terraform output cloudfront_distribution_id

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### 2.5 Access Frontend

```bash
# Get CloudFront URL
terraform output cloudfront_url

# Open in browser
https://YOUR_CLOUDFRONT_URL
```

---

## Step 3: Deploy Backend to EC2

### 3.1 Build Docker Image

```bash
cd ../backend
docker build -t devops-demo-backend .
```

### 3.2 Get ECR Repository URI

```bash
cd ../infrastructure
terraform output ecr_repository_url
```

### 3.3 Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag image
docker tag devops-demo-backend:latest \
  YOUR_ECR_URI:latest

# Push image
docker push YOUR_ECR_URI:latest
```

### 3.4 Deploy to EC2

```bash
# Get EC2 public IP
cd ../infrastructure
terraform output ec2_public_ip

# SSH to EC2
ssh -i devops-demo-key.pem ec2-user@YOUR_EC2_IP
```

**On EC2 instance:**

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Pull image
docker pull YOUR_ECR_URI:latest

# Stop old container (if exists)
docker stop devops-backend || true
docker rm devops-backend || true

# Run new container
docker run -d \
  --name devops-backend \
  -p 5000:5000 \
  --restart unless-stopped \
  -e NODE_ENV=production \
  -e PORT=5000 \
  YOUR_ECR_URI:latest

# Check logs
docker logs -f devops-backend

# Verify it's running
curl http://localhost:5000/api/health
```

### 3.5 Test Backend via ALB

```bash
# Exit from EC2
exit

# Get ALB DNS name
cd infrastructure
terraform output alb_dns_name

# Test backend
curl http://YOUR_ALB_DNS/api/health
curl http://YOUR_ALB_DNS/api/messages
```

---

## Step 4: Update Frontend API URL

The frontend needs to know the backend URL.

### 4.1 Update Environment Variable

Edit `frontend/.env`:
```env
VITE_API_URL=http://YOUR_ALB_DNS
```

Or for production with custom domain:
```env
VITE_API_URL=https://api.yourdomain.com
```

### 4.2 Rebuild and Redeploy Frontend

```bash
cd frontend
npm run build
aws s3 sync dist/ s3://YOUR-BUCKET-NAME --delete
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

---

## Step 5: Verify Deployment

### 5.1 Test Frontend

```bash
# Open CloudFront URL in browser
https://YOUR_CLOUDFRONT_URL
```

You should see:
- ✅ DevOps Demo Application
- ✅ Backend health status showing "healthy"
- ✅ Messages from backend displayed

### 5.2 Test Backend

```bash
# Health check
curl http://YOUR_ALB_DNS/api/health

# Messages API
curl http://YOUR_ALB_DNS/api/messages
```

---

## Deployment Commands Summary

### Quick Deploy Script

```bash
#!/bin/bash

# 1. Deploy infrastructure
cd infrastructure
terraform apply -auto-approve

# 2. Deploy frontend
cd ../frontend
npm run build
aws s3 sync dist/ s3://$(terraform -chdir=../infrastructure output -raw s3_bucket_name) --delete
aws cloudfront create-invalidation \
  --distribution-id $(terraform -chdir=../infrastructure output -raw cloudfront_distribution_id) \
  --paths "/*"

# 3. Build and push backend
cd ../backend
docker build -t devops-demo-backend .
ECR_URI=$(terraform -chdir=../infrastructure output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI
docker tag devops-demo-backend:latest $ECR_URI:latest
docker push $ECR_URI:latest

# 4. Deploy to EC2
EC2_IP=$(terraform -chdir=../infrastructure output -raw ec2_public_ip)
ssh -i devops-demo-key.pem ec2-user@$EC2_IP << 'ENDSSH'
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
docker pull $(aws ecr describe-repositories --repository-names devops-demo-backend --query 'repositories[0].repositoryUri' --output text):latest
docker stop devops-backend || true
docker rm devops-backend || true
docker run -d --name devops-backend -p 5000:5000 --restart unless-stopped \
  $(aws ecr describe-repositories --repository-names devops-demo-backend --query 'repositories[0].repositoryUri' --output text):latest
ENDSSH

echo "Deployment complete!"
echo "Frontend: https://$(terraform -chdir=../infrastructure output -raw cloudfront_url)"
echo "Backend: http://$(terraform -chdir=../infrastructure output -raw alb_dns_name)"
```

---

## Updating the Application

### Update Frontend Only

```bash
cd frontend
npm run build
aws s3 sync dist/ s3://YOUR-BUCKET-NAME --delete
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

### Update Backend Only

```bash
# Build and push new image
cd backend
docker build -t devops-demo-backend .
docker tag devops-demo-backend:latest YOUR_ECR_URI:latest
docker push YOUR_ECR_URI:latest

# Update on EC2
ssh -i devops-demo-key.pem ec2-user@YOUR_EC2_IP
docker pull YOUR_ECR_URI:latest
docker stop devops-backend
docker rm devops-backend
docker run -d --name devops-backend -p 5000:5000 --restart unless-stopped YOUR_ECR_URI:latest
exit
```

---

## Monitoring

### CloudWatch Logs

```bash
# View EC2 logs
aws logs tail /aws/ec2/devops-demo-backend --follow
```

### Check Backend Health

```bash
# Via ALB
curl http://YOUR_ALB_DNS/api/health

# Directly on EC2
ssh -i devops-demo-key.pem ec2-user@YOUR_EC2_IP
docker logs -f devops-backend
```

### Check Frontend

```bash
# Test CloudFront
curl -I https://YOUR_CLOUDFRONT_URL

# Check S3 bucket
aws s3 ls s3://YOUR-BUCKET-NAME/
```

---

## Cost Breakdown

### Monthly Costs (Estimated)

**Frontend:**
- S3 Storage (1GB): $0.50
- S3 Requests: $0.50
- CloudFront (10GB): $1-2
- **Subtotal: $2-3/month**

**Backend:**
- EC2 t3.micro: $10-12
- EBS Volume (20GB): $2
- ALB: $16-18
- Data Transfer: $1-2
- **Subtotal: $29-34/month**

**Total: ~$31-37/month**

**Cost Optimization Tips:**
- Use t3.micro (free tier eligible for 12 months)
- Enable S3 lifecycle policies
- Use CloudFront caching effectively
- Consider Reserved Instances for long-term

---

## Troubleshooting

### Frontend Issues

**Problem: 404 errors on page refresh**
- Solution: CloudFront custom error responses already configured in Terraform

**Problem: Old content showing**
```bash
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

**Problem: Can't connect to backend**
- Check VITE_API_URL in frontend/.env
- Verify ALB DNS is correct
- Check CORS settings in backend

### Backend Issues

**Problem: Container won't start**
```bash
ssh -i key.pem ec2-user@EC2_IP
docker logs devops-backend
```

**Problem: ALB health check failing**
- Verify security group allows traffic on port 5000
- Check `/api/health` endpoint is responding
- Review ALB target group health checks

**Problem: Can't pull from ECR**
```bash
# Re-authenticate
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ECR_URI
```

### Infrastructure Issues

**Problem: Terraform errors**
```bash
terraform refresh
terraform plan
```

**Problem: EC2 can't access ECR**
- Verify IAM role is attached to EC2
- Check security group allows outbound HTTPS

---

## Security Best Practices

1. **Use HTTPS**
   - CloudFront provides free SSL
   - Configure ACM certificate for custom domain

2. **Restrict Security Groups**
   - ALB: Allow 80, 443 from 0.0.0.0/0
   - EC2: Allow 5000 only from ALB security group

3. **Use IAM Roles**
   - EC2 instance profile for ECR access
   - No hardcoded credentials

4. **Enable Logging**
   - CloudWatch logs for EC2
   - S3 access logs
   - ALB access logs

5. **Regular Updates**
   - Update Docker images
   - Patch EC2 instances
   - Update dependencies

---

## Cleanup

To destroy all resources:

```bash
cd infrastructure
terraform destroy
```

This will remove:
- EC2 instance
- S3 bucket (must be empty first)
- CloudFront distribution
- ALB and target groups
- Security groups
- IAM roles

**Before destroying:**
```bash
# Empty S3 bucket
aws s3 rm s3://YOUR-BUCKET-NAME --recursive

# Then destroy
terraform destroy
```

---

## Summary

✅ **What You Deployed:**
- Frontend: S3 + CloudFront (static files, no Nginx)
- Backend: EC2 + Docker (Express.js, no Nginx)
- Infrastructure: Terraform managed

✅ **No Nginx Required:**
- S3 serves static files directly
- Express.js handles HTTP on port 5000
- ALB provides load balancing

✅ **Cost:** ~$31-37/month
- Can be reduced with free tier
- Predictable and scalable

✅ **Production Ready:**
- Auto-restart on failure
- Health checks configured
- Logging enabled
- Secure by default

**Your application is now live on AWS!** 🚀
