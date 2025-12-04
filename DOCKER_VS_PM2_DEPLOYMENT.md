# Docker vs PM2 Deployment Options

Your GitHub Actions workflow supports BOTH deployment methods automatically!

---

## 🎯 Two Deployment Options

### Option 1: PM2 (Node.js directly) - DEFAULT ✅
**Simpler, faster, no Docker needed**

### Option 2: Docker (Containerized)
**More isolated, production-ready**

---

## 📊 Comparison

| Feature | PM2 | Docker |
|---------|-----|--------|
| **Setup Complexity** | ✅ Simple | ⚠️ Medium |
| **Deployment Speed** | ✅ Fast | ⚠️ Slower |
| **Resource Usage** | ✅ Low | ⚠️ Higher |
| **Isolation** | ⚠️ Process-level | ✅ Container-level |
| **Production Ready** | ✅ Yes | ✅ Yes |
| **GitHub Secrets** | 8 secrets | 8 secrets (same!) |
| **ECR Required** | ❌ No | ❌ No (builds on EC2) |

---

## 🚀 Option 1: PM2 Deployment (Current Default)

### How It Works

```
GitHub Actions → Copy code to EC2 → npm install → PM2 start
```

### GitHub Secrets Needed (8)

1. `AWS_ACCESS_KEY_ID`
2. `AWS_SECRET_ACCESS_KEY`
3. `S3_BUCKET`
4. `CLOUDFRONT_DISTRIBUTION_ID`
5. `EC2_HOST`
6. `EC2_USER`
7. `EC2_SSH_KEY`
8. `BACKEND_API_URL`

**No additional secrets needed!**

### EC2 Setup

```bash
# On EC2, install PM2
sudo npm install -g pm2

# PM2 will auto-start on reboot
pm2 startup
pm2 save
```

### Advantages

- ✅ Faster deployments
- ✅ Lower resource usage
- ✅ Simpler setup
- ✅ No Docker complexity

### When to Use

- Development/staging environments
- Small to medium applications
- When you want simplicity

---

## 🐳 Option 2: Docker Deployment

### How It Works

```
GitHub Actions → Copy code to EC2 → Build Docker image → Run container
```

### GitHub Secrets Needed (8 - Same as PM2!)

1. `AWS_ACCESS_KEY_ID`
2. `AWS_SECRET_ACCESS_KEY`
3. `S3_BUCKET`
4. `CLOUDFRONT_DISTRIBUTION_ID`
5. `EC2_HOST`
6. `EC2_USER`
7. `EC2_SSH_KEY`
8. `BACKEND_API_URL`

**No additional secrets needed!** Docker builds on EC2, not in GitHub Actions.

### EC2 Setup

```bash
# On EC2, Docker is already installed from user-data script
# Verify:
docker --version
```

### Advantages

- ✅ Better isolation
- ✅ Consistent environments
- ✅ Easier to scale
- ✅ Production best practice

### When to Use

- Production environments
- When you need isolation
- When you want consistency

---

## 🔄 How the Workflow Decides

The GitHub Actions workflow **automatically detects** which method to use:

```yaml
# If Dockerfile exists AND Docker is installed → Use Docker
# Otherwise → Use PM2
```

**Current behavior:**
- Your backend has a `Dockerfile` ✅
- EC2 has Docker installed ✅
- **Result: Will use Docker automatically!**

---

## 🎯 What You Need to Do

### For PM2 Deployment (Simpler)

**1. Remove Dockerfile from backend:**
```powershell
Remove-Item backend/Dockerfile
```

**2. Add 8 GitHub secrets** (see GITHUB_SECRETS_GUIDE.md)

**3. Push to GitHub:**
```powershell
git add .
git commit -m "Use PM2 deployment"
git push origin main
```

**Done!** No Docker, no ECR, just Node.js with PM2.

---

### For Docker Deployment (Current Setup)

**1. Keep Dockerfile in backend** ✅ (already there)

**2. Add 8 GitHub secrets** (see GITHUB_SECRETS_GUIDE.md)

**3. Push to GitHub:**
```powershell
git add .
git commit -m "Deploy with Docker"
git push origin main
```

**Done!** Docker builds on EC2, no ECR needed.

---

## 🔐 GitHub Secrets Summary

**Good news:** Both options use the **SAME 8 secrets!**

No ECR secrets needed because:
- PM2: No Docker at all
- Docker: Builds on EC2 (not in GitHub Actions)

**The 8 secrets:**
1. AWS_ACCESS_KEY_ID
2. AWS_SECRET_ACCESS_KEY
3. S3_BUCKET
4. CLOUDFRONT_DISTRIBUTION_ID
5. EC2_HOST
6. EC2_USER
7. EC2_SSH_KEY
8. BACKEND_API_URL

**Add them here:**
https://github.com/Rakeshkumarsahugithub/DevopsDemo/settings/secrets/actions

---

## 💡 Recommendation

### For Your Case:

**Use Docker** (current setup) because:
- ✅ You already have Dockerfile
- ✅ Docker is installed on EC2
- ✅ Better for production
- ✅ Consistent with local development
- ✅ No extra secrets needed!

**Just add the 8 secrets and push to GitHub!**

---

## 🧪 Test Both Methods

### Test PM2:
```powershell
# Remove Dockerfile temporarily
Move-Item backend/Dockerfile backend/Dockerfile.bak
git add .
git commit -m "Test PM2 deployment"
git push origin main
```

### Test Docker:
```powershell
# Restore Dockerfile
Move-Item backend/Dockerfile.bak backend/Dockerfile
git add .
git commit -m "Test Docker deployment"
git push origin main
```

---

## 📋 Quick Answer

**Q: Do I need ECR for Docker images?**  
**A:** No! Docker builds on EC2, not in GitHub Actions.

**Q: What secrets do I need for Docker?**  
**A:** Same 8 secrets as PM2. No additional secrets!

**Q: Which should I use?**  
**A:** Docker (current setup) - it's already configured and production-ready.

---

## ✅ Summary

- **Current setup**: Docker on EC2 (no ECR)
- **Secrets needed**: 8 (same for both PM2 and Docker)
- **ECR**: Not required!
- **Recommendation**: Keep Docker (current setup)

**Just add the 8 secrets and you're ready to deploy!**

See: `GITHUB_SECRETS_GUIDE.md` for how to add secrets.
