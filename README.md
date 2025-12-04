# DevOps Demo Project

A full-stack microservices application demonstrating modern DevOps practices with React frontend, Express backend, Docker containerization, and AWS deployment.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Users                                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Route 53 (DNS)                            │
│                    + SSL/TLS (ACM)                           │
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
│  (Static Site)  │            │  (Docker + App)  │
└─────────────────┘            └──────────────────┘
         │                              │
         └──────────────┬───────────────┘
                        ▼
              ┌──────────────────┐
              │   CloudWatch     │
              │  (Monitoring)    │
              └──────────────────┘
```

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Docker Setup](#docker-setup)
- [AWS Infrastructure](#aws-infrastructure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Security](#security)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)

## ✨ Features

- **Microservices Architecture**: Separate frontend and backend services
- **Containerization**: Docker containers for both services
- **Infrastructure as Code**: Terraform for AWS infrastructure
- **CI/CD**: Automated deployment with GitHub Actions
- **Monitoring**: CloudWatch logs and metrics
- **Security**: IAM roles, security groups, HTTPS enforcement
- **Scalability**: Load balancer ready for auto-scaling

## 🛠️ Tech Stack

### Frontend
- React 18
- Vite
- Modern CSS with gradients and animations
- Nginx (production)

### Backend
- Node.js 20
- Express.js
- CORS enabled
- RESTful API

### DevOps
- Docker & Docker Compose
- AWS (S3, EC2, ECR, ALB, CloudFront, Route 53, ACM, CloudWatch)
- Terraform
- GitHub Actions
- AWS Parameter Store (secrets management)

## 📦 Prerequisites

- Node.js 20+ and npm
- Docker and Docker Compose
- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform 1.0+
- Git
- (Optional) Domain name for production deployment

## 🚀 Local Development

### 1. Clone the Repository

\`\`\`bash
git clone <your-repo-url>
cd devops-demo
\`\`\`

### 2. Backend Setup

\`\`\`bash
cd backend
npm install
npm run dev
\`\`\`

The backend will start on `http://localhost:5000`

**Available Endpoints:**
- `GET /` - API status
- `GET /api/messages` - Get sample messages
- `GET /api/health` - Health check endpoint

### 3. Frontend Setup

\`\`\`bash
cd frontend
npm install
npm run dev
\`\`\`

The frontend will start on `http://localhost:5173`

### 4. Environment Variables

**Backend (.env):**
\`\`\`env
PORT=5000
NODE_ENV=development
\`\`\`

**Frontend (.env):**
\`\`\`env
VITE_API_URL=http://localhost:5000
\`\`\`

## 🐳 Docker Setup

### Build and Run with Docker Compose

\`\`\`bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
\`\`\`

Access the application:
- Frontend: `http://localhost`
- Backend: `http://localhost:5000`

### Individual Docker Commands

**Backend:**
\`\`\`bash
cd backend
docker build -t devops-demo-backend .
docker run -p 5000:5000 devops-demo-backend
\`\`\`

**Frontend:**
\`\`\`bash
cd frontend
docker build -t devops-demo-frontend .
docker run -p 80:80 devops-demo-frontend
\`\`\`

## ☁️ AWS Infrastructure

### Infrastructure Components

1. **VPC & Networking**: Custom VPC with public subnets across 2 AZs
2. **S3 + CloudFront**: Static website hosting for frontend
3. **EC2**: Backend application server with Docker
4. **ECR**: Docker image registry
5. **ALB**: Application Load Balancer for backend
6. **Route 53**: DNS management
7. **ACM**: SSL/TLS certificates
8. **CloudWatch**: Logging and monitoring
9. **IAM**: Roles and policies for secure access

### Terraform Deployment

1. **Configure Variables**

\`\`\`bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
\`\`\`

Edit `terraform.tfvars`:
\`\`\`hcl
aws_region       = "us-east-1"
project_name     = "devops-demo"
environment      = "prod"
domain_name      = "yourdomain.com"
ec2_instance_type = "t3.micro"
ec2_key_name     = "your-key-pair-name"
\`\`\`

2. **Create EC2 Key Pair** (if you don't have one)

\`\`\`bash
aws ec2 create-key-pair --key-name devops-demo-key --query 'KeyMaterial' --output text > devops-demo-key.pem
chmod 400 devops-demo-key.pem
\`\`\`

3. **Initialize Terraform**

\`\`\`bash
terraform init
\`\`\`

4. **Plan Infrastructure**

\`\`\`bash
terraform plan
\`\`\`

5. **Apply Infrastructure**

\`\`\`bash
terraform apply
\`\`\`

6. **Get Outputs**

\`\`\`bash
terraform output
\`\`\`

Save these outputs - you'll need them for GitHub Actions secrets.

### Manual AWS Setup (Alternative)

If you prefer manual setup:

1. **Create ECR Repositories**
2. **Create S3 Bucket** with static website hosting
3. **Launch EC2 Instance** with Docker installed
4. **Configure ALB** with target groups
5. **Set up Route 53** and ACM certificate
6. **Configure CloudWatch** alarms

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The pipeline automatically:
1. Lints and tests code
2. Builds Docker images
3. Pushes images to ECR
4. Deploys frontend to S3
5. Deploys backend to EC2
6. Invalidates CloudFront cache

### Required GitHub Secrets

Add these secrets in GitHub repository settings:

\`\`\`
AWS_ACCESS_KEY_ID          # AWS access key
AWS_SECRET_ACCESS_KEY      # AWS secret key
ECR_REGISTRY               # ECR registry URL (from Terraform output)
BACKEND_API_URL            # Backend API URL for frontend
CLOUDFRONT_DISTRIBUTION_ID # CloudFront distribution ID
EC2_HOST                   # EC2 public IP
EC2_USER                   # EC2 username (usually ec2-user)
EC2_SSH_KEY                # EC2 private key content
\`\`\`

### Trigger Deployment

\`\`\`bash
git add .
git commit -m "Deploy to production"
git push origin main
\`\`\`

## 📤 Deployment

### Initial Deployment

1. **Deploy Infrastructure**
   \`\`\`bash
   cd infrastructure
   terraform apply
   \`\`\`

2. **Build and Push Docker Images**
   \`\`\`bash
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REGISTRY>
   
   # Build and push backend
   cd backend
   docker build -t <ECR_REGISTRY>/devops-demo-backend:latest .
   docker push <ECR_REGISTRY>/devops-demo-backend:latest
   
   # Build and push frontend
   cd ../frontend
   docker build -t <ECR_REGISTRY>/devops-demo-frontend:latest .
   docker push <ECR_REGISTRY>/devops-demo-frontend:latest
   \`\`\`

3. **Deploy Frontend to S3**
   \`\`\`bash
   cd frontend
   npm run build
   aws s3 sync dist/ s3://<S3_BUCKET_NAME> --delete
   \`\`\`

4. **Deploy Backend to EC2**
   \`\`\`bash
   ssh -i devops-demo-key.pem ec2-user@<EC2_PUBLIC_IP>
   
   # On EC2
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REGISTRY>
   docker pull <ECR_REGISTRY>/devops-demo-backend:latest
   docker run -d --name devops-backend -p 5000:5000 --restart unless-stopped <ECR_REGISTRY>/devops-demo-backend:latest
   \`\`\`

### Subsequent Deployments

Just push to main branch - GitHub Actions handles everything!

## 📊 Monitoring

### CloudWatch Dashboard

Access at: AWS Console → CloudWatch → Dashboards → `devops-demo-dashboard`

**Metrics Monitored:**
- EC2 CPU utilization
- ALB response time
- Request count
- Unhealthy host count

### CloudWatch Alarms

- **High CPU**: Alerts when EC2 CPU > 80%
- **Unhealthy Hosts**: Alerts when targets are unhealthy

### Logs

\`\`\`bash
# View EC2 logs
aws logs tail /aws/ec2/devops-demo-backend --follow

# View application logs on EC2
ssh -i devops-demo-key.pem ec2-user@<EC2_PUBLIC_IP>
docker logs -f devops-backend
\`\`\`

## 🔒 Security

### Implemented Security Measures

1. **Network Security**
   - VPC with security groups
   - ALB only accepts HTTPS
   - EC2 only accessible from ALB

2. **IAM**
   - Least privilege IAM roles
   - EC2 instance profile for ECR access
   - No hardcoded credentials

3. **Secrets Management**
   - AWS Parameter Store for secrets
   - Environment variables for configuration
   - GitHub Secrets for CI/CD

4. **Container Security**
   - Non-root user in Docker containers
   - ECR image scanning enabled
   - Regular image updates

5. **SSL/TLS**
   - HTTPS enforced via ACM certificates
   - HTTP to HTTPS redirect

### Best Practices

- Rotate AWS credentials regularly
- Use AWS Systems Manager Session Manager instead of SSH
- Enable MFA for AWS account
- Regular security audits with AWS Security Hub
- Keep dependencies updated

## 📈 Scaling

### Horizontal Scaling

1. **Auto Scaling Group** (Add to Terraform)

\`\`\`hcl
resource "aws_autoscaling_group" "backend" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns   = [aws_lb_target_group.backend.arn]
  health_check_type   = "ELB"
  min_size            = 2
  max_size            = 10
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
}
\`\`\`

2. **Scaling Policies**

\`\`\`hcl
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}
\`\`\`

### Vertical Scaling

Change instance type in `terraform.tfvars`:
\`\`\`hcl
ec2_instance_type = "t3.medium"  # or t3.large, etc.
\`\`\`

Then apply:
\`\`\`bash
terraform apply
\`\`\`

### Database Scaling (Future Enhancement)

- Add RDS for persistent data
- Use ElastiCache for caching
- Implement read replicas

## 🐛 Troubleshooting

### Frontend Issues

**Problem**: Frontend can't connect to backend
- Check `VITE_API_URL` in `.env`
- Verify backend is running
- Check CORS configuration in backend

**Problem**: Build fails
\`\`\`bash
rm -rf node_modules package-lock.json
npm install
npm run build
\`\`\`

### Backend Issues

**Problem**: Port already in use
\`\`\`bash
# Find process using port 5000
netstat -ano | findstr :5000
# Kill the process
taskkill /PID <PID> /F
\`\`\`

**Problem**: Docker container won't start
\`\`\`bash
docker logs devops-backend
docker inspect devops-backend
\`\`\`

### AWS Issues

**Problem**: EC2 instance unhealthy
- Check security group rules
- Verify health check endpoint `/api/health`
- Check CloudWatch logs

**Problem**: S3 deployment fails
- Verify bucket permissions
- Check AWS credentials
- Ensure bucket exists

**Problem**: Terraform errors
\`\`\`bash
terraform refresh
terraform plan
\`\`\`

### CI/CD Issues

**Problem**: GitHub Actions failing
- Check GitHub Secrets are set correctly
- Verify AWS credentials have proper permissions
- Review workflow logs

## 📝 Additional Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

MIT License - feel free to use this project for learning and development.

## 👥 Support

For issues and questions:
- Open a GitHub issue
- Check existing documentation
- Review CloudWatch logs

---

**Built with ❤️ for DevOps learning and demonstration**
