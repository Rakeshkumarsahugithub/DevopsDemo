# Quick Start Guide

## Local Development (Without Docker)

### 1. Start Backend
```bash
cd backend
npm install
npm start
```

Backend will run on `http://localhost:5000`

### 2. Start Frontend (in a new terminal)
```bash
cd frontend
npm install
npm run dev
```

Frontend will run on `http://localhost:5173`

---

## Docker Development

### Option 1: PowerShell Script (Windows)
```powershell
.\start.ps1
```

### Option 2: Bash Script (Linux/Mac)
```bash
chmod +x start.sh
./start.sh
```

### Option 3: Manual Docker Compose
```bash
docker-compose build
docker-compose up -d
docker-compose logs -f
```

Access:
- Frontend: `http://localhost`
- Backend: `http://localhost:5000`

Stop services:
```bash
docker-compose down
```

---

## Deployment to AWS

See the main [README.md](README.md) for complete deployment instructions.

### Quick Steps:
1. Configure AWS CLI
2. Deploy infrastructure with Terraform
3. Build and push Docker images to ECR
4. Deploy frontend to S3
5. Deploy backend to EC2
6. Configure GitHub Actions for CI/CD

---

## Troubleshooting

### Backend won't start
- Check if port 5000 is already in use
- Verify Node.js is installed (v20+)
- Check `.env` file exists

### Frontend won't start
- Ensure backend is running first
- Check `VITE_API_URL` in `.env`
- Verify Node.js version (v20+)

### Docker issues
- Ensure Docker Desktop is running
- Try `docker-compose down` then `docker-compose up --build`
- Check Docker logs: `docker-compose logs`

---

For detailed documentation, see [README.md](README.md)
