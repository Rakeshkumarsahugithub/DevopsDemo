# GitHub Setup Guide

Your code is now on GitHub! Follow these steps to complete the setup.

---

## 🔗 Repository URL

https://github.com/Rakeshkumarsahugithub/DevopsDemo

---

## ✅ What's Already Done

- ✅ Code pushed to GitHub
- ✅ Main branch created
- ✅ GitHub Actions workflow included (`.github/workflows/ci-cd.yml`)
- ✅ Complete documentation included
- ✅ Docker configuration ready
- ✅ Terraform infrastructure ready

---

## 🔐 Setup GitHub Actions Secrets

To enable automatic deployment via GitHub Actions, you need to add secrets.

### Step 1: Go to Repository Settings

1. Open: https://github.com/Rakeshkumarsahugithub/DevopsDemo
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Step 2: Add Required Secrets

Add these secrets one by one:

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS IAM Console → Users → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS IAM Console → Users → Security credentials |
| `AWS_REGION` | AWS region | `us-east-1` (or your preferred region) |
| `ECR_REPOSITORY` | ECR repository name | `devdemo-backend` |
| `S3_BUCKET` | S3 bucket name | From Terraform output: `terraform output s3_bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID | From Terraform output: `terraform output cloudfront_distribution_id` |
| `EC2_HOST` | EC2 public IP | From Terraform output: `terraform output ec2_public_ip` |
| `EC2_USER` | EC2 username | `ec2-user` (default for Amazon Linux) |
| `EC2_SSH_KEY` | EC2 private key | Content of `devops-demo-key.pem` file |
| `BACKEND_API_URL` | Backend ALB DNS | From Terraform output: `terraform output alb_dns_name` |

### Step 3: Get EC2 SSH Key Content

**PowerShell:**
```powershell
Get-Content devops-demo-key.pem | Out-String
```

Copy the entire output including:
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
```

Paste this as the value for `EC2_SSH_KEY` secret.

---

## 🚀 Trigger Deployment

Once secrets are configured, deployment happens automatically:

### Automatic Deployment

Every time you push to the `main` branch:
```powershell
git add .
git commit -m "Your commit message"
git push origin main
```

GitHub Actions will automatically:
1. Build frontend
2. Deploy to S3
3. Invalidate CloudFront cache
4. Build backend Docker image
5. Push to ECR
6. Deploy to EC2

### Manual Deployment

You can also trigger deployment manually:

1. Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/actions
2. Click **Deploy to AWS** workflow
3. Click **Run workflow**
4. Select branch: `main`
5. Click **Run workflow**

---

## 📊 Monitor Deployment

### View Workflow Status

1. Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/actions
2. Click on the latest workflow run
3. Monitor each job:
   - `deploy-frontend` - Frontend deployment
   - `deploy-backend` - Backend deployment

### Check Logs

Click on each job to see detailed logs:
- Build output
- Deployment steps
- Any errors or warnings

---

## 🔍 Verify Deployment

After deployment completes:

### Frontend
```powershell
# Get CloudFront URL from Terraform
cd infrastructure
terraform output cloudfront_url

# Open in browser
Start-Process "https://YOUR_CLOUDFRONT_URL"
```

### Backend
```powershell
# Get ALB DNS from Terraform
terraform output alb_dns_name

# Test health endpoint
curl "http://YOUR_ALB_DNS/api/health"
```

---

## 🛠️ Troubleshooting

### Workflow Fails

**Check these:**
1. All secrets are added correctly
2. AWS credentials have proper permissions
3. EC2 instance is running
4. Security groups allow necessary traffic

**View detailed logs:**
1. Go to Actions tab
2. Click on failed workflow
3. Click on failed job
4. Expand failed step to see error

### Common Issues

**Issue: "Permission denied" on EC2**
- Check `EC2_SSH_KEY` secret includes BEGIN/END lines
- Verify EC2 security group allows SSH (port 22)

**Issue: "Access denied" to ECR**
- Verify AWS credentials have ECR permissions
- Check IAM policy includes `ecr:*` actions

**Issue: "S3 bucket not found"**
- Verify `S3_BUCKET` secret matches actual bucket name
- Check bucket exists: `aws s3 ls s3://BUCKET_NAME`

**Issue: "CloudFront invalidation failed"**
- Verify `CLOUDFRONT_DISTRIBUTION_ID` is correct
- Check distribution exists: `aws cloudfront list-distributions`

---

## 📝 Update Workflow (Optional)

The workflow file is at: `.github/workflows/ci-cd.yml`

To modify:
1. Edit the file locally
2. Commit and push:
   ```powershell
   git add .github/workflows/ci-cd.yml
   git commit -m "Update CI/CD workflow"
   git push origin main
   ```

---

## 🔄 Workflow Triggers

The workflow runs on:
- **Push to main branch** - Automatic deployment
- **Manual trigger** - Via GitHub Actions UI
- **Pull request** - Can be configured (optional)

---

## 📚 Additional Resources

### GitHub Actions Documentation
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)

### AWS Documentation
- [ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [S3 Documentation](https://docs.aws.amazon.com/s3/)
- [EC2 Documentation](https://docs.aws.amazon.com/ec2/)

### Project Documentation
- `COMPLETE_DEPLOYMENT_GUIDE.md` - Full deployment guide
- `DEPLOYMENT_CHECKLIST.md` - Step-by-step checklist
- `README.md` - Project overview

---

## ✅ Setup Checklist

- [ ] Repository cloned/forked
- [ ] All GitHub secrets added
- [ ] AWS infrastructure deployed (Terraform)
- [ ] EC2 key pair created and saved
- [ ] First deployment triggered
- [ ] Frontend accessible via CloudFront
- [ ] Backend accessible via ALB
- [ ] Responsive design tested
- [ ] Documentation reviewed

---

## 🎉 You're All Set!

Your DevOps Demo is now:
- ✅ On GitHub
- ✅ Ready for CI/CD
- ✅ Configured for AWS deployment
- ✅ Fully documented

**Next Steps:**
1. Add GitHub secrets
2. Deploy infrastructure with Terraform
3. Push code to trigger first deployment
4. Monitor deployment in Actions tab

**Repository:** https://github.com/Rakeshkumarsahugithub/DevopsDemo

---

**Happy Deploying! 🚀**
