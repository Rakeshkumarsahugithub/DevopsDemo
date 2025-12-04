# Quick Start: Manual AWS Deployment

Quick reference for deploying without Terraform. For detailed instructions, see `MANUAL_AWS_SETUP_GUIDE.md`.

---

## 🚀 Quick Deployment Steps

### 1. Configure AWS CLI (5 min)

```powershell
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Format (json)

# Verify
aws sts get-caller-identity
```

### 2. Create S3 Bucket (2 min)

```powershell
$BUCKET_NAME = "devops-demo-frontend-$(Get-Random -Maximum 9999)"
aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1
aws s3 website s3://$BUCKET_NAME/ --index-document index.html
$BUCKET_NAME | Out-File bucket-name.txt
```

### 3. Create CloudFront (3 min)

```powershell
# Use AWS Console or see MANUAL_AWS_SETUP_GUIDE.md for CLI commands
# Save Distribution ID to cloudfront-id.txt
```

### 4. Create ECR Repository (1 min)

```powershell
aws ecr create-repository --repository-name devops-demo-backend
$ECR_URI = aws ecr describe-repositories --repository-names devops-demo-backend --query 'repositories[0].repositoryUri' --output text
$ECR_URI | Out-File ecr-uri.txt
```

### 5. Create EC2 Instance (10 min)

```powershell
# Create key pair
aws ec2 create-key-pair --key-name devops-demo-key --query 'KeyMaterial' --output text | Out-File -Encoding ASCII devops-demo-key.pem

# Launch instance (see MANUAL_AWS_SETUP_GUIDE.md for full commands)
# Save Public IP to ec2-ip.txt
```

### 6. Create ALB (5 min)

```powershell
# Create ALB, Target Group, and Listener
# See MANUAL_AWS_SETUP_GUIDE.md for full commands
# Save ALB DNS to alb-dns.txt
```

### 7. Deploy Frontend (3 min)

```powershell
cd frontend
npm install
npm run build
$BUCKET_NAME = Get-Content ../bucket-name.txt
aws s3 sync dist/ s3://$BUCKET_NAME --delete
```

### 8. Deploy Backend (5 min)

```powershell
cd ../backend
$ECR_URI = Get-Content ../ecr-uri.txt
docker build -t devops-demo-backend .
docker tag devops-demo-backend:latest "$ECR_URI:latest"
docker push "$ECR_URI:latest"

# SSH to EC2 and run container (see guide)
```

### 9. Setup GitHub Actions (10 min)

1. Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/settings/secrets/actions
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` = `us-east-1`
   - `ECR_REPOSITORY` = `devops-demo-backend`
   - `S3_BUCKET` = (from bucket-name.txt)
   - `CLOUDFRONT_DISTRIBUTION_ID` = (from cloudfront-id.txt)
   - `EC2_HOST` = (from ec2-ip.txt)
   - `EC2_USER` = `ec2-user`
   - `EC2_SSH_KEY` = (content of devops-demo-key.pem)
   - `BACKEND_API_URL` = (from alb-dns.txt)

### 10. Test (2 min)

```powershell
# Test frontend
$CF_URL = Get-Content cloudfront-url.txt
Start-Process "https://$CF_URL"

# Test backend
$ALB_DNS = Get-Content alb-dns.txt
curl "http://$ALB_DNS/api/health"
```

---

## 📋 Files Created

After setup, you'll have these files with important info:

- `bucket-name.txt` - S3 bucket name
- `cloudfront-id.txt` - CloudFront distribution ID
- `cloudfront-url.txt` - CloudFront URL
- `ecr-uri.txt` - ECR repository URI
- `ec2-ip.txt` - EC2 public IP
- `alb-dns.txt` - ALB DNS name
- `devops-demo-key.pem` - EC2 SSH key (keep secure!)
- `deployment-info.txt` - All deployment info
- `aws-resources.txt` - Summary of all resources

---

## 🔗 Important URLs

After deployment:

- **Frontend**: https://[cloudfront-url]
- **Backend**: http://[alb-dns]
- **Health**: http://[alb-dns]/api/health
- **GitHub**: https://github.com/Rakeshkumarsahugithub/DevopsDemo

---

## ⏱️ Total Time

- **Initial Setup**: ~45 minutes
- **Subsequent Deployments**: ~5 minutes (via GitHub Actions)

---

## 💰 Monthly Cost

- S3 + CloudFront: $2-3
- EC2 t3.micro: $10-12
- ALB: $16-18
- Other: $3-4
- **Total**: ~$31-37/month

---

## 🆘 Need Help?

See detailed guides:
- `MANUAL_AWS_SETUP_GUIDE.md` - Complete step-by-step guide
- `GITHUB_SETUP.md` - GitHub Actions setup
- `DEPLOYMENT_CHECKLIST.md` - Interactive checklist

---

## 🎯 Next Steps After Deployment

1. **Monitor**: Check CloudWatch logs
2. **Test**: Verify responsive design
3. **Optimize**: Review costs and performance
4. **Secure**: Add HTTPS, custom domain
5. **Scale**: Consider auto-scaling

---

**Ready to deploy? Start with `MANUAL_AWS_SETUP_GUIDE.md`!**
