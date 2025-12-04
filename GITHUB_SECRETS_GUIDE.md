# GitHub Secrets Setup Guide

Complete guide to adding secrets for GitHub Actions deployment.

---

## 🔗 Quick Access

**Direct Link to Add Secrets:**
https://github.com/Rakeshkumarsahugithub/DevopsDemo/settings/secrets/actions

---

## 📋 How to Add Secrets

### Step 1: Navigate to Secrets Page

1. Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo
2. Click **Settings** tab (top right)
3. In left sidebar: **Secrets and variables** → **Actions**
4. Click **New repository secret** button

### Step 2: Add Each Secret

For each secret below:
1. Click **New repository secret**
2. **Name**: Enter the exact name (case-sensitive!)
3. **Secret**: Paste the value
4. Click **Add secret**

---

## 🔐 Required Secrets (8 Total)

### 1. AWS_ACCESS_KEY_ID

**What it is:** Your AWS access key for API access

**Where to get it:**
1. Go to: https://console.aws.amazon.com/iam/
2. Click **Users** in left sidebar
3. Click your username
4. Click **Security credentials** tab
5. Scroll to **Access keys** section
6. Click **Create access key**
7. Select **Command Line Interface (CLI)**
8. Click **Next** → **Create access key**
9. **Copy the Access Key ID**

**Example:** `AKIAIOSFODNN7EXAMPLE`

---

### 2. AWS_SECRET_ACCESS_KEY

**What it is:** Your AWS secret key (shown only once!)

**Where to get it:**
- Same place as Access Key ID (step 1 above)
- **IMPORTANT**: Save this immediately! It's only shown once.
- If you lose it, create a new access key

**Example:** `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

---

### 3. S3_BUCKET

**What it is:** Your S3 bucket name for frontend

**Where to get it:**

**Option A: From your saved file**
```powershell
Get-Content bucket-name.txt
```

**Option B: List all buckets**
```powershell
aws s3 ls
```

**Option C: AWS Console**
1. Go to: https://s3.console.aws.amazon.com/s3/buckets
2. Find bucket starting with `devdem-`
3. Copy the bucket name

**Example:** `devdem-1234`

---

### 4. CLOUDFRONT_DISTRIBUTION_ID

**What it is:** CloudFront distribution ID

**Where to get it:**

**Option A: From your saved file**
```powershell
Get-Content cloudfront-id.txt
```

**Option B: AWS Console**
1. Go to: https://console.aws.amazon.com/cloudfront
2. Find your distribution
3. Copy the **ID** (starts with E...)

**Option C: AWS CLI**
```powershell
aws cloudfront list-distributions --query 'DistributionList.Items[0].Id' --output text
```

**Example:** `E1234ABCDEFGHI`

---

### 5. EC2_HOST

**What it is:** Your EC2 instance public IP address

**Where to get it:**

**Option A: From your saved file**
```powershell
Get-Content ec2-ip.txt
```

**Option B: AWS Console**
1. Go to: https://console.aws.amazon.com/ec2/v2/home#Instances
2. Find instance named `devdemo`
3. Copy **Public IPv4 address**

**Option C: AWS CLI**
```powershell
aws ec2 describe-instances --filters "Name=tag:Name,Values=devdemo" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

**Example:** `54.123.45.67`

---

### 6. EC2_USER

**What it is:** SSH username for EC2

**Value:** `ec2-user`

**Note:** This is the default username for Amazon Linux 2023. Just type `ec2-user` as the value.

---

### 7. EC2_SSH_KEY

**What it is:** Private SSH key to access EC2

**Where to get it:**

**From your saved file:**
```powershell
Get-Content devops-demo-key.pem
```

**IMPORTANT:** 
- Copy the **ENTIRE** content
- Include the `-----BEGIN RSA PRIVATE KEY-----` line
- Include the `-----END RSA PRIVATE KEY-----` line
- Include ALL lines in between

**Example:**
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAx7...
(many lines)
...xyz123
-----END RSA PRIVATE KEY-----
```

**Tip:** In PowerShell, you can copy to clipboard:
```powershell
Get-Content devops-demo-key.pem | Set-Clipboard
```

---

### 8. BACKEND_API_URL

**What it is:** URL where your backend API is accessible

**Value depends on your setup:**

**Option A: Using EC2 IP directly**
```
http://YOUR_EC2_IP:5000
```

**Option B: Using ALB (if you created one)**
```
http://YOUR_ALB_DNS
```

**Example:** `http://54.123.45.67:5000` or `http://devops-demo-alb-123456.us-east-1.elb.amazonaws.com`

**To get EC2 IP:**
```powershell
$EC2_IP = Get-Content ec2-ip.txt
Write-Host "http://${EC2_IP}:5000"
```

---

## ✅ Verification Checklist

After adding all secrets, verify:

- [ ] AWS_ACCESS_KEY_ID (starts with AKIA...)
- [ ] AWS_SECRET_ACCESS_KEY (long string)
- [ ] S3_BUCKET (devdem-XXXX)
- [ ] CLOUDFRONT_DISTRIBUTION_ID (starts with E...)
- [ ] EC2_HOST (IP address like 54.x.x.x)
- [ ] EC2_USER (ec2-user)
- [ ] EC2_SSH_KEY (includes BEGIN/END lines)
- [ ] BACKEND_API_URL (http://...)

---

## 🧪 Test GitHub Actions

After adding all secrets:

1. Make a small change:
   ```powershell
   "# Test deployment" | Out-File -Append README.md
   ```

2. Commit and push:
   ```powershell
   git add .
   git commit -m "Test GitHub Actions"
   git push origin main
   ```

3. Watch the workflow:
   - Go to: https://github.com/Rakeshkumarsahugithub/DevopsDemo/actions
   - Click on the latest workflow run
   - Monitor both jobs (deploy-frontend, deploy-backend)

---

## 🔒 Security Notes

**Keep these secrets safe:**
- Never commit secrets to Git
- Never share secrets publicly
- Rotate AWS keys regularly
- Use IAM roles with minimal permissions

**If a secret is compromised:**
1. Delete the AWS access key immediately
2. Create a new access key
3. Update the GitHub secret

---

## 🆘 Troubleshooting

### Can't find Settings tab?
- You must be the repository owner or have admin access
- Make sure you're logged into GitHub

### Secret not working?
- Check for extra spaces or line breaks
- Verify the secret name is exactly correct (case-sensitive)
- For EC2_SSH_KEY, ensure BEGIN/END lines are included

### AWS credentials invalid?
- Verify in AWS Console: IAM → Users → Security credentials
- Test locally: `aws sts get-caller-identity`
- Create new access key if needed

### EC2_SSH_KEY format issues?
```powershell
# Verify key format
Get-Content devops-demo-key.pem | Select-Object -First 1
# Should show: -----BEGIN RSA PRIVATE KEY-----

Get-Content devops-demo-key.pem | Select-Object -Last 1
# Should show: -----END RSA PRIVATE KEY-----
```

---

## 📖 Quick Reference

**Add secrets here:**
https://github.com/Rakeshkumarsahugithub/DevopsDemo/settings/secrets/actions

**View workflow runs:**
https://github.com/Rakeshkumarsahugithub/DevopsDemo/actions

**AWS Console:**
- IAM: https://console.aws.amazon.com/iam/
- S3: https://s3.console.aws.amazon.com/s3/buckets
- CloudFront: https://console.aws.amazon.com/cloudfront
- EC2: https://console.aws.amazon.com/ec2/v2/home#Instances

---

## 🎯 Summary

1. **Go to**: https://github.com/Rakeshkumarsahugithub/DevopsDemo/settings/secrets/actions
2. **Add 8 secrets** (use this guide for values)
3. **Test** by pushing to GitHub
4. **Monitor** at: https://github.com/Rakeshkumarsahugithub/DevopsDemo/actions

**That's it! Your GitHub Actions will automatically deploy on every push to main.** 🚀
