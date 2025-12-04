# Deployment Checklist

Use this checklist to ensure all steps are completed for deployment.

---

## ☑️ Pre-Deployment Checklist

### Local Testing
- [ ] Docker Desktop is installed and running
- [ ] Containers build successfully (`docker-compose build`)
- [ ] Containers run successfully (`docker-compose up -d`)
- [ ] Backend health check passes (`http://localhost:5000/api/health`)
- [ ] Frontend loads correctly (`http://localhost`)
- [ ] Responsive design works (test with DevTools)

### AWS Prerequisites
- [ ] AWS account created
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS credentials configured (`aws configure`)
- [ ] AWS credentials verified (`aws sts get-caller-identity`)
- [ ] Terraform installed (`terraform --version`)
- [ ] EC2 key pair created (`devops-demo-key.pem`)
- [ ] Key pair saved securely

### GitHub Prerequisites
- [ ] GitHub account created
- [ ] Repository created on GitHub
- [ ] Local git initialized (`git init`)
- [ ] Remote added (`git remote add origin ...`)
- [ ] Code pushed to GitHub (`git push origin main`)

---

## ☑️ Infrastructure Deployment

### Terraform Configuration
- [ ] Navigate to `infrastructure/` directory
- [ ] Copy `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Update `terraform.tfvars` with your values:
  - [ ] `aws_region`
  - [ ] `project_name`
  - [ ] `environment`
  - [ ] `ec2_instance_type`
  - [ ] `ec2_key_name`

### Terraform Deployment
- [ ] Run `terraform init`
- [ ] Run `terraform plan` (review changes)
- [ ] Run `terraform apply` (type 'yes')
- [ ] Wait for deployment to complete (5-10 minutes)
- [ ] Save outputs to file (`terraform output > ../deployment-outputs.txt`)

### Verify Infrastructure
- [ ] S3 bucket created
- [ ] CloudFront distribution created
- [ ] EC2 instance running
- [ ] ECR repository created
- [ ] ALB created
- [ ] Security groups configured
- [ ] IAM roles created

---

## ☑️ Frontend Deployment

### Build Frontend
- [ ] Navigate to `frontend/` directory
- [ ] Run `npm install`
- [ ] Run `npm run build`
- [ ] Verify `dist/` folder created

### Deploy to S3
- [ ] Get S3 bucket name (`terraform output s3_bucket_name`)
- [ ] Upload files (`aws s3 sync dist/ s3://BUCKET_NAME --delete`)
- [ ] Verify upload (`aws s3 ls s3://BUCKET_NAME/`)

### CloudFront
- [ ] Get CloudFront distribution ID
- [ ] Invalidate cache (`aws cloudfront create-invalidation ...`)
- [ ] Wait for invalidation to complete

### Test Frontend
- [ ] Get CloudFront URL (`terraform output cloudfront_url`)
- [ ] Open URL in browser
- [ ] Verify page loads
- [ ] Check for console errors (F12)

---

## ☑️ Backend Deployment

### Build Docker Image
- [ ] Navigate to `backend/` directory
- [ ] Run `docker build -t devops-demo-backend .`
- [ ] Verify image built successfully

### Push to ECR
- [ ] Get ECR repository URL (`terraform output ecr_repository_url`)
- [ ] Login to ECR (`aws ecr get-login-password ...`)
- [ ] Tag image (`docker tag ...`)
- [ ] Push image (`docker push ...`)
- [ ] Verify image in ECR (`aws ecr describe-images ...`)

### Deploy to EC2
- [ ] Get EC2 public IP (`terraform output ec2_public_ip`)
- [ ] SSH to EC2 (`ssh -i devops-demo-key.pem ec2-user@EC2_IP`)
- [ ] Login to ECR on EC2
- [ ] Pull Docker image
- [ ] Stop old container (if exists)
- [ ] Run new container
- [ ] Verify container running (`docker ps`)
- [ ] Test locally on EC2 (`curl http://localhost:5000/api/health`)
- [ ] Exit EC2

### Test Backend via ALB
- [ ] Get ALB DNS name (`terraform output alb_dns_name`)
- [ ] Test health endpoint (`curl http://ALB_DNS/api/health`)
- [ ] Test messages endpoint (`curl http://ALB_DNS/api/messages`)
- [ ] Verify responses are correct

---

## ☑️ Connect Frontend to Backend

### Update Frontend Configuration
- [ ] Get ALB DNS name
- [ ] Update `frontend/.env` with `VITE_API_URL=http://ALB_DNS`
- [ ] Rebuild frontend (`npm run build`)
- [ ] Redeploy to S3 (`aws s3 sync dist/ s3://BUCKET_NAME --delete`)
- [ ] Invalidate CloudFront cache

### Test Integration
- [ ] Open CloudFront URL in browser
- [ ] Verify backend health status shows "healthy"
- [ ] Verify messages are displayed
- [ ] Check browser console for errors
- [ ] Test API calls in Network tab (F12)

---

## ☑️ GitHub Actions Setup

### Configure GitHub Secrets
Go to GitHub → Settings → Secrets and variables → Actions

- [ ] `AWS_ACCESS_KEY_ID`
- [ ] `AWS_SECRET_ACCESS_KEY`
- [ ] `AWS_REGION`
- [ ] `ECR_REPOSITORY`
- [ ] `S3_BUCKET`
- [ ] `CLOUDFRONT_DISTRIBUTION_ID`
- [ ] `EC2_HOST`
- [ ] `EC2_USER`
- [ ] `EC2_SSH_KEY` (entire .pem file content)
- [ ] `BACKEND_API_URL`

### Create Workflow File
- [ ] Create `.github/workflows/` directory
- [ ] Create `deploy.yml` file
- [ ] Copy workflow content from guide
- [ ] Commit and push to GitHub

### Test Workflow
- [ ] Go to GitHub → Actions tab
- [ ] Verify workflow runs automatically
- [ ] Check deploy-frontend job succeeds
- [ ] Check deploy-backend job succeeds
- [ ] Review logs for any errors

---

## ☑️ Verification

### Frontend Verification
- [ ] Open CloudFront URL
- [ ] Page loads without errors
- [ ] All content displays correctly
- [ ] Images load properly
- [ ] No 404 errors in console

### Backend Verification
- [ ] Health endpoint returns "healthy"
- [ ] Messages endpoint returns data
- [ ] Response times are acceptable
- [ ] No errors in CloudWatch logs

### Responsive Design Verification
- [ ] Open DevTools (F12)
- [ ] Toggle device toolbar (Ctrl+Shift+M)
- [ ] Test iPhone SE (375px)
- [ ] Test iPhone 12 Pro (390px)
- [ ] Test iPad (768px)
- [ ] Test Desktop (1920px)
- [ ] Verify layout adapts correctly
- [ ] Verify touch targets are adequate
- [ ] Verify text is readable

### Integration Verification
- [ ] Frontend can call backend API
- [ ] CORS is configured correctly
- [ ] Data flows from backend to frontend
- [ ] Error handling works
- [ ] Loading states work

---

## ☑️ Monitoring Setup

### CloudWatch
- [ ] CloudWatch logs are being created
- [ ] Can view backend logs
- [ ] Alarms are configured (optional)
- [ ] Dashboard created (optional)

### Health Checks
- [ ] ALB health checks passing
- [ ] Target group shows healthy targets
- [ ] Backend responds to health endpoint
- [ ] Frontend is accessible

---

## ☑️ Security Checklist

### AWS Security
- [ ] Security groups configured correctly
- [ ] IAM roles follow least privilege
- [ ] No hardcoded credentials in code
- [ ] SSH key stored securely
- [ ] S3 bucket has appropriate permissions
- [ ] CloudFront uses HTTPS

### Application Security
- [ ] Environment variables used for config
- [ ] No sensitive data in logs
- [ ] CORS configured appropriately
- [ ] Error messages don't expose internals

---

## ☑️ Documentation

### Project Documentation
- [ ] README.md is up to date
- [ ] Deployment guides are complete
- [ ] Architecture diagrams are accurate
- [ ] API documentation exists

### Deployment Documentation
- [ ] Terraform outputs saved
- [ ] AWS resource IDs documented
- [ ] GitHub secrets documented
- [ ] Troubleshooting guide available

---

## ☑️ Post-Deployment

### Testing
- [ ] Perform end-to-end testing
- [ ] Test all user flows
- [ ] Test error scenarios
- [ ] Test on multiple devices
- [ ] Test on multiple browsers

### Performance
- [ ] Check page load times
- [ ] Check API response times
- [ ] Verify CloudFront caching works
- [ ] Check for any bottlenecks

### Monitoring
- [ ] Set up alerts for errors
- [ ] Monitor CloudWatch logs
- [ ] Check ALB metrics
- [ ] Monitor EC2 CPU/memory usage

---

## ☑️ Optional Enhancements

### Custom Domain
- [ ] Register domain in Route 53
- [ ] Request ACM certificate
- [ ] Update CloudFront distribution
- [ ] Update ALB listener
- [ ] Configure DNS records

### HTTPS for Backend
- [ ] Request ACM certificate for backend
- [ ] Add HTTPS listener to ALB
- [ ] Update security groups
- [ ] Update frontend API URL to HTTPS

### Auto Scaling
- [ ] Create launch template
- [ ] Create auto scaling group
- [ ] Configure scaling policies
- [ ] Test scaling behavior

### Backup & Recovery
- [ ] Set up automated backups
- [ ] Test restore procedures
- [ ] Document recovery process

---

## 🎯 Deployment Status

### Current Status
- [ ] ✅ Local development working
- [ ] ✅ Infrastructure deployed
- [ ] ✅ Frontend deployed
- [ ] ✅ Backend deployed
- [ ] ✅ GitHub Actions configured
- [ ] ✅ Monitoring enabled
- [ ] ✅ Documentation complete

### Deployment Date
- **Date**: _______________
- **Deployed by**: _______________
- **Environment**: Production

### URLs
- **Frontend**: _______________
- **Backend**: _______________
- **GitHub**: _______________

### Credentials Location
- **AWS Credentials**: _______________
- **SSH Key**: _______________
- **GitHub Secrets**: Configured in repository

---

## 📞 Support Contacts

### AWS Support
- Account ID: _______________
- Support Plan: _______________

### Team Contacts
- DevOps Lead: _______________
- Backend Developer: _______________
- Frontend Developer: _______________

---

## 🔄 Regular Maintenance

### Daily
- [ ] Check CloudWatch logs for errors
- [ ] Monitor ALB health checks
- [ ] Verify application is accessible

### Weekly
- [ ] Review CloudWatch metrics
- [ ] Check for security updates
- [ ] Review cost reports
- [ ] Test backup procedures

### Monthly
- [ ] Update dependencies
- [ ] Review and optimize costs
- [ ] Update documentation
- [ ] Security audit

---

## ✅ Deployment Complete!

Once all items are checked, your deployment is complete and production-ready!

**Next Steps:**
1. Monitor application for 24-48 hours
2. Gather user feedback
3. Plan for future enhancements
4. Schedule regular maintenance

**Congratulations! Your DevOps Demo is live! 🎉**
