# Next Steps After GitHub Push

Your code is now on GitHub! Here's exactly what to do next.

---

## 🎯 Current Status

✅ **Completed:**
- Code pushed to GitHub
- Docker containers running locally
- Responsive design implemented
- Complete documentation created

❌ **Not Yet Done:**
- AWS infrastructure setup
- GitHub Actions secrets configuration
- Production deployment

---

## 📋 Choose Your Path

### Path A: Manual AWS Setup (Recommended for Learning)
**Time:** ~45 minutes  
**Best for:** Understanding AWS services step-by-step

### Path B: Terraform Setup (Recommended for Production)
**Time:** ~30 minutes  
**Best for:** Quick, repeatable deployments

---

## 🚀 Path A: Manual AWS Setup (Step-by-Step)

### Step 1: Configure AWS CLI (5 minutes)

```powershell
# Install AWS CLI (if not installed)
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Configure credentials
aws configure

# You'll need:
# - AWS Access Key ID (from AWS Console → IAM → Users → Security credentials)
# - AWS Secret Access Key (from AWS Console)
# - Default region: us-east-1
# - Default output format: json

# Verify it works
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

---

### Step 2: Create S3 Bucket for Frontend (2 minutes)

```powershell
# Generate unique bucket name
$BUCKET_NAME = "devdem-$(Get-Random -Maximum 9999)"

# Create bucket
aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document index.html

# Save bucket name
$BUCKET_NAME | Out-File -FilePath bucket-name.txt

Write-Host "✅ S3 Bucket created: $BUCKET_NAME"
```

---

### Step 3: Create CloudFront Distribution (3 minutes)

**Option 1: AWS Console (Easier)**

1. Go to: https://console.aws.amazon.com/cloudfront
2. Click **Create Distribution**
3. **Origin domain**: Select your S3 bucket
4. **Origin path**: Leave empty
5. **Viewer protocol policy**: Redirect HTTP to HTTPS
6. **Default root object**: `index.html`
7. **Custom error responses**:
   - Error code: 404 → Response: /index.html → HTTP code: 200
   - Error code: 403 → Response: /index.html → HTTP code: 200
8. Click **Create Distribution**
9. **Save the Distribution ID and Domain Name**

```powershell
# Save these values
"YOUR_DISTRIBUTION_ID" | Out-File cloudfront-id.txt
"YOUR_CLOUDFRONT_DOMAIN.cloudfront.net" | Out-File cloudfront-url.txt
```

**Option 2: AWS CLI (Advanced)**

See `MANUAL_AWS_SETUP_GUIDE.md` for CLI commands.

---

### Step 4: Create ECR Repository (1 minute)

```powershell
# Create repository
aws ecr create-repository --repository-name devdemo-backend --region us-east-1

# Get repository URI
$ECR_URI = aws ecr describe-repositories --repository-names devdemo-backend --query 'repositories[0].repositoryUri' --output text

# Save for later
$ECR_URI | Out-File ecr-uri.txt

Write-Host "✅ ECR Repository created: $ECR_URI"
```

---

### Step 5: Create EC2 Key Pair (1 minute)

```powershell
# Create key pair
aws ec2 create-key-pair --key-name devops-demo-key --query 'KeyMaterial' --output text | Out-File -Encoding ASCII devops-demo-key.pem

Write-Host "✅ Key pair created: devops-demo-key.pem"
Write-Host "⚠️  IMPORTANT: Keep this file secure!"
```

---

### Step 6: Create EC2 Instance (10 minutes)

**Option 1: AWS Console (Easier)**

1. Go to: https://console.aws.amazon.com/ec2
2. Click **Launch Instance**
3. **Name**: `devdemo`
4. **AMI**: Amazon Linux 2023
5. **Instance type**: t3.micro
6. **Key pair**: devops-demo-key
7. **Network settings**:
   - Allow SSH (port 22) from My IP
   - Allow HTTP (port 5000) from Anywhere
8. **Advanced details** → **IAM instance profile**: Create new role with:
   - AmazonEC2ContainerRegistryReadOnly
   - CloudWatchAgentServerPolicy
9. **User data** (paste this):

```bash
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

10. Click **Launch Instance**
11. **Save the Public IP address**

```powershell
# Save EC2 IP
"YOUR_EC2_PUBLIC_IP" | Out-File ec2-ip.txt
```

**Option 2: AWS CLI (Advanced)**

See `MANUAL_AWS_SETUP_GUIDE.md` for CLI commands.

---

### Step 7: Create Application Load Balancer (5 minutes)

**AWS Console:**

1. Go to: https://console.aws.amazon.com/ec2/v2/home#LoadBalancers
2. Click **Create Load Balancer** → **Application Load Balancer**
3. **Name**: `devops-demo-alb`
4. **Scheme**: Internet-facing
5. **Network mapping**: Select all availability zones
6. **Security groups**: Create new:
   - Allow HTTP (80) from Anywhere
   - Allow HTTPS (443) from Anywhere
7. **Listeners**: HTTP:80
8. **Target group**: Create new
   - **Name**: `devops-demo-tg`
   - **Protocol**: HTTP
   - **Port**: 5000
   - **Health check path**: `/api/health`
   - **Register targets**: Select your EC2 instance
9. Click **Create**
10. **Save the ALB DNS name**

```powershell
# Save ALB DNS
"YOUR_ALB_DNS_NAME" | Out-File alb-dns.txt
```

---

### Step 8: Deploy Frontend to S3 (3 minutes)

```powershell
# Navigate to frontend
cd frontend

# Install dependencies (if not already)
npm install

# Build for production
npm run build

# Get bucket name
$BUCKET_NAME = Get-Content ../bucket-name.txt

# Upload to S3
aws s3 sync dist/ s3://$BUCKET_NAME --delete

Write-Host "✅ Frontend deployed to S3"

# Invalidate CloudFront cache
$DIST_ID = Get-Content ../cloudfront-id.txt
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"

Write-Host "✅ CloudFront cache invalidated"
```

---

### Step 9: Deploy Backend to EC2 (5 minutes)

```powershell
cd ../backend

# Get ECR URI
$ECR_URI = Get-Content ../ecr-uri.txt
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# Build Docker image
docker build -t devdemo-backend .

# Tag image
docker tag devdemo-backend:latest "$ECR_URI:latest"

# Push to ECR
docker push "$ECR_URI:latest"

Write-Host "✅ Backend image pushed to ECR"

# Get EC2 IP
$EC2_IP = Get-Content ../ec2-ip.txt

Write-Host "Now SSH to EC2 and run the container..."
Write-Host "Command: ssh -i devops-demo-key.pem ec2-user@$EC2_IP"
```

**On EC2 (after SSH):**

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# Get ECR URI
ECR_URI=$(aws ecr describe-repositories --repository-names devdemo-backend --query 'repositories[0].repositoryUri' --output text)

# Pull image
docker pull $ECR_URI:latest

# Run container
docker run -d --name devops-backend -p 5000:5000 --restart unless-stopped -e NODE_ENV=production -e PORT=5000 $ECR_URI:latest

# Check status
docker ps
docker logs devops-backend

# Test locally
curl http://localhost:5000/api/health

# Exit
exit
```

---

### Step 10: Setup GitHub Actions (10 minutes)

#### 10.1: Collect All Information

```powershell
# Create deployment info file
@"
=== GitHub Secrets Configuration ===

AWS_ACCESS_KEY_ID: (Get from AWS IAM Console)
AWS_SECRET_ACCESS_KEY: (Get from AWS IAM Console)
AWS_REGION: us-east-1
ECR_REPOSITORY: devdemo-backend
S3_BUCKET: $(Get-Content bucket-name.txt)
CLOUDFRONT_DISTRIBUTION_ID: $(Get-Content cloudfront-id.txt)
EC2_HOST: $(Get-Content ec2-ip.txt)
EC2_USER: ec2-user
EC2_SSH_KEY: (Content of devops-demo-key.pem - see below)
BACKEND_API_URL: $(Get-Content alb-dns.txt)
"@ | Out-File deployment-info.txt

notepad deployment-info.txt
```

#### 10.2: Get EC2 SSH Key Content

```powershell
# Display key content
Get-Content devops-demo-key.pem

# Copy the ENTIRE output including:
# -----BEGIN RSA PRIVATE KEY-----
# ...all the lines...
# -----END RSA PRIVATE KEY-----
```

#### 10.3: Add Secrets to GitHub

1. Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/settings/secrets/actions
2. Click **New repository secret**
3. Add each secret from `deployment-info.txt`:

**Required Secrets:**

| Secret Name | Value | Where to Get |
|-------------|-------|--------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS Console → IAM → Users → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS Console → IAM → Users → Security credentials |
| `AWS_REGION` | `us-east-1` | Your AWS region |
| `ECR_REPOSITORY` | `devdemo-backend` | ECR repository name |
| `S3_BUCKET` | From `bucket-name.txt` | S3 bucket name |
| `CLOUDFRONT_DISTRIBUTION_ID` | From `cloudfront-id.txt` | CloudFront distribution ID |
| `EC2_HOST` | From `ec2-ip.txt` | EC2 public IP |
| `EC2_USER` | `ec2-user` | Default for Amazon Linux |
| `EC2_SSH_KEY` | Content of `devops-demo-key.pem` | Entire key file content |
| `BACKEND_API_URL` | From `alb-dns.txt` | ALB DNS name |

#### 10.4: Update Frontend API URL

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
$DIST_ID = Get-Content ../cloudfront-id.txt
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"

Write-Host "✅ Frontend updated with backend URL"
```

---

### Step 11: Test Everything (2 minutes)

```powershell
# Test frontend
$CF_URL = Get-Content cloudfront-url.txt
Start-Process "https://$CF_URL"

# Test backend
$ALB_DNS = Get-Content alb-dns.txt
curl "http://$ALB_DNS/api/health"
curl "http://$ALB_DNS/api/messages"
```

**Expected Results:**
- ✅ Frontend loads in browser
- ✅ Backend health check returns "healthy"
- ✅ Messages are displayed on frontend
- ✅ Responsive design works (test with F12 → Ctrl+Shift+M)

---

### Step 12: Test GitHub Actions (2 minutes)

```powershell
# Make a small change
"# Test deployment" | Out-File -Append README.md

# Commit and push
git add .
git commit -m "Test GitHub Actions deployment"
git push origin main
```

**Monitor deployment:**
1. Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/actions
2. Watch the workflow run
3. Check both jobs complete successfully

---

## 🎉 Congratulations!

You've successfully deployed your DevOps Demo to AWS!

### ✅ What You Have Now:

- **Frontend**: https://[your-cloudfront-url]
- **Backend**: http://[your-alb-dns]
- **GitHub Actions**: Automatic deployment on push
- **Responsive Design**: Works on all devices
- **No Nginx**: Simple architecture

### 💰 Monthly Cost: ~$31-37

### 📚 Saved Files:

- `bucket-name.txt` - S3 bucket name
- `cloudfront-id.txt` - CloudFront distribution ID
- `cloudfront-url.txt` - CloudFront URL
- `ecr-uri.txt` - ECR repository URI
- `ec2-ip.txt` - EC2 public IP
- `alb-dns.txt` - ALB DNS name
- `devops-demo-key.pem` - EC2 SSH key (keep secure!)
- `deployment-info.txt` - All deployment info

---

## 🔄 Future Deployments

After initial setup, deployments are automatic:

```powershell
# Make changes to your code
git add .
git commit -m "Your changes"
git push origin main

# GitHub Actions automatically:
# 1. Builds frontend → Deploys to S3
# 2. Builds backend → Pushes to ECR → Deploys to EC2
```

---

## 📖 Need Help?

- **Detailed Guide**: `MANUAL_AWS_SETUP_GUIDE.md`
- **Quick Reference**: `QUICK_START_MANUAL_DEPLOYMENT.md`
- **GitHub Setup**: `GITHUB_SETUP.md`
- **Checklist**: `DEPLOYMENT_CHECKLIST.md`

---

## 🆘 Troubleshooting

**Frontend not loading?**
- Check CloudFront distribution is deployed (takes 15-20 min)
- Verify S3 bucket has files: `aws s3 ls s3://YOUR_BUCKET`

**Backend not responding?**
- SSH to EC2: `ssh -i devops-demo-key.pem ec2-user@EC2_IP`
- Check container: `docker ps` and `docker logs devops-backend`
- Verify security group allows port 5000

**GitHub Actions failing?**
- Check all secrets are added correctly
- Verify EC2_SSH_KEY includes BEGIN/END lines
- Review workflow logs for specific errors

---

## 🎯 Next Steps (Optional)

1. **Custom Domain**: Add your own domain name
2. **HTTPS for Backend**: Add SSL certificate to ALB
3. **Monitoring**: Set up CloudWatch alarms
4. **Auto Scaling**: Add auto-scaling group
5. **Database**: Add RDS for persistent data

---

**Ready to start? Begin with Step 1: Configure AWS CLI!** 🚀
