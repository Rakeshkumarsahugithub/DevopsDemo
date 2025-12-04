# Complete Deployment Guide

Deploy your DevOps Demo to AWS using GitHub Actions, S3, CloudFront, and EC2 (No ECR/Docker required).

---

## 🎯 Architecture

```
GitHub → GitHub Actions
           ↓
    ┌──────┴──────┐
    ▼             ▼
  S3 + CF       EC2
(Frontend)   (Backend)
```

**What You'll Deploy:**
- **Frontend**: React app → S3 + CloudFront
- **Backend**: Node.js app → EC2 (with PM2)
- **CI/CD**: GitHub Actions (automatic deployment)

**No Docker/ECR needed!** - Direct deployment to EC2.

---

## 📋 Prerequisites

1. **AWS Account** with admin access
2. **AWS CLI** installed and configured
3. **GitHub Repository** (already done ✅)
4. **Local Docker** running (for testing)

---

## Step 1: Install & Configure AWS CLI (5 min)

### Install AWS CLI

Already installed! If you restarted PowerShell, verify:

```powershell
aws --version
```

### Configure AWS CLI

```powershell
aws configure
```

**Enter:**
- **AWS Access Key ID**: Get from AWS Console → IAM → Users → Security credentials
- **AWS Secret Access Key**: From same place
- **Default region**: `us-east-1`
- **Default output format**: `json`

**Verify:**
```powershell
aws sts get-caller-identity
```

---

## Step 2: Create S3 Bucket (2 min)

```powershell
# Generate unique bucket name
$BUCKET_NAME = "devdem-$(Get-Random -Maximum 9999)"

# Create bucket
aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document index.html

# Make bucket public
aws s3api put-public-access-block `
  --bucket $BUCKET_NAME `
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Add bucket policy
@"
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
  }]
}
"@ | Out-File -Encoding ASCII bucket-policy.json

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Save bucket name
$BUCKET_NAME | Out-File bucket-name.txt
Write-Host "✅ S3 Bucket created: $BUCKET_NAME"
```

---

## Step 3: Create CloudFront Distribution (3 min)

**AWS Console** (easier):

1. Go to: https://console.aws.amazon.com/cloudfront
2. Click **Create Distribution**
3. **Origin domain**: Select your S3 bucket
4. **Viewer protocol policy**: Redirect HTTP to HTTPS
5. **Default root object**: `index.html`
6. **Custom error responses**:
   - 404 → /index.html → 200
   - 403 → /index.html → 200
7. Click **Create**
8. **Save Distribution ID and Domain Name**

```powershell
# Save these
"YOUR_DISTRIBUTION_ID" | Out-File cloudfront-id.txt
"YOUR_DOMAIN.cloudfront.net" | Out-File cloudfront-url.txt
```

---

## Step 4: Create EC2 Instance (10 min)

### 4.1 Create Key Pair

```powershell
aws ec2 create-key-pair --key-name devops-demo-key --query 'KeyMaterial' --output text | Out-File -Encoding ASCII devops-demo-key.pem
Write-Host "✅ Key pair created"
```

### 4.2 Create Security Group

```powershell
# Get default VPC
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text

# Create security group
$SG_ID = aws ec2 create-security-group `
  --group-name devops-demo-sg `
  --description "DevOps Demo Security Group" `
  --vpc-id $VPC_ID `
  --query 'GroupId' `
  --output text

# Allow SSH from your IP
$MY_IP = (Invoke-WebRequest -Uri "https://api.ipify.org").Content
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr "$MY_IP/32"

# Allow HTTP (port 5000) from anywhere
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 5000 --cidr 0.0.0.0/0

Write-Host "✅ Security Group created: $SG_ID"
```

### 4.3 Launch EC2 Instance

**AWS Console** (easier):

1. Go to: https://console.aws.amazon.com/ec2
2. Click **Launch Instance**
3. **Name**: `devdemo`
4. **AMI**: Amazon Linux 2023
5. **Instance type**: t3.micro
6. **Key pair**: devops-demo-key
7. **Security group**: Select devops-demo-sg
8. **User data** (paste this):

```bash
#!/bin/bash
yum update -y
yum install -y nodejs npm git
npm install -g pm2
mkdir -p /home/ec2-user/app
chown -R ec2-user:ec2-user /home/ec2-user/app
```

9. Click **Launch**
10. **Save Public IP**

```powershell
"YOUR_EC2_PUBLIC_IP" | Out-File ec2-ip.txt
```

---

## Step 5: Create Application Load Balancer (Optional, 5 min)

**For production, create an ALB. For testing, skip this and use EC2 IP directly.**

If creating ALB:
1. Go to: https://console.aws.amazon.com/ec2/v2/home#LoadBalancers
2. Create ALB pointing to EC2 instance on port 5000
3. Health check path: `/api/health`
4. Save ALB DNS name

```powershell
"YOUR_ALB_DNS" | Out-File alb-dns.txt
```

---

## Step 6: Setup GitHub Secrets (10 min)

Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/settings/secrets/actions

Add these secrets:

| Secret Name | Value | Where to Get |
|-------------|-------|--------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS IAM Console |
| `S3_BUCKET` | From `bucket-name.txt` | S3 bucket name |
| `CLOUDFRONT_DISTRIBUTION_ID` | From `cloudfront-id.txt` | CloudFront distribution ID |
| `EC2_HOST` | From `ec2-ip.txt` | EC2 public IP |
| `EC2_USER` | `ec2-user` | Default for Amazon Linux |
| `EC2_SSH_KEY` | Content of `devops-demo-key.pem` | Entire key file |
| `BACKEND_API_URL` | `http://YOUR_EC2_IP:5000` or ALB DNS | Backend URL |

**Get EC2_SSH_KEY content:**
```powershell
Get-Content devops-demo-key.pem
# Copy entire output including BEGIN/END lines
```

---

## Step 7: Initial Manual Deployment (5 min)

### Deploy Frontend

```powershell
cd frontend
npm install
npm run build

$BUCKET_NAME = Get-Content ../bucket-name.txt
aws s3 sync dist/ s3://$BUCKET_NAME --delete

$DIST_ID = Get-Content ../cloudfront-id.txt
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"

Write-Host "✅ Frontend deployed"
```

### Deploy Backend

```powershell
cd ../backend

# Get EC2 IP
$EC2_IP = Get-Content ../ec2-ip.txt

# Copy files to EC2
scp -i ../devops-demo-key.pem -r * ec2-user@${EC2_IP}:/home/ec2-user/app/

# SSH and setup
ssh -i ../devops-demo-key.pem ec2-user@$EC2_IP

# On EC2:
cd /home/ec2-user/app
npm install --production
pm2 start server.js --name devops-backend
pm2 startup
pm2 save
exit

Write-Host "✅ Backend deployed"
```

---

## Step 8: Test Deployment (2 min)

```powershell
# Test frontend
$CF_URL = Get-Content cloudfront-url.txt
Start-Process "https://$CF_URL"

# Test backend
$EC2_IP = Get-Content ec2-ip.txt
curl "http://${EC2_IP}:5000/api/health"
```

---

## Step 9: Enable GitHub Actions (2 min)

```powershell
# Make a small change
"# Deployed!" | Out-File -Append README.md

# Commit and push
git add .
git commit -m "Enable GitHub Actions deployment"
git push origin main
```

**Monitor:**
1. Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/actions
2. Watch the workflow run
3. Both jobs should complete successfully

---

## 🎉 Done!

### Your URLs:
- **Frontend**: https://[cloudfront-url]
- **Backend**: http://[ec2-ip]:5000 or http://[alb-dns]

### Future Deployments:
Just push to GitHub - automatic deployment!

```powershell
git add .
git commit -m "Your changes"
git push origin main
```

---

## 💰 Monthly Cost

- S3 + CloudFront: $2-3
- EC2 t3.micro: $10-12
- ALB (optional): $16-18
- **Total: $12-33/month**

---

## 🔧 Troubleshooting

**Frontend not loading?**
- Wait 15-20 min for CloudFront deployment
- Check S3 bucket has files: `aws s3 ls s3://YOUR_BUCKET`

**Backend not responding?**
- SSH to EC2: `ssh -i devops-demo-key.pem ec2-user@EC2_IP`
- Check PM2: `pm2 status` and `pm2 logs`
- Verify security group allows port 5000

**GitHub Actions failing?**
- Check all secrets are added
- Verify EC2_SSH_KEY includes BEGIN/END lines
- Review workflow logs

---

## 📚 Other Guides

- `MANUAL_AWS_SETUP_GUIDE.md` - Detailed AWS setup
- `GITHUB_SETUP.md` - GitHub Actions details
- `DEPLOYMENT_CHECKLIST.md` - Track progress
- `RESPONSIVE_DESIGN.md` - Responsive design docs

---

**Ready to deploy? Start with Step 1!** 🚀
