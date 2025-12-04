# Run Containers Script
# This script starts the DevOps Demo application using Docker Compose

Write-Host "🚀 Starting DevOps Demo with Docker..." -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Host "Waiting for Docker to start (30 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    try {
        docker info | Out-Null
        Write-Host "✅ Docker is now running" -ForegroundColor Green
    } catch {
        Write-Host "❌ Docker failed to start" -ForegroundColor Red
        Write-Host "Please start Docker Desktop manually and run this script again" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""

# Stop any existing containers
Write-Host "🛑 Stopping existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null

Write-Host ""

# Build images
Write-Host "📦 Building Docker images..." -ForegroundColor Yellow
docker-compose build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Start containers
Write-Host "🎬 Starting containers..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start containers" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Wait for services to be ready
Write-Host "⏳ Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""

# Check container status
Write-Host "🔍 Checking container status..." -ForegroundColor Yellow
docker-compose ps

Write-Host ""

# Test backend
Write-Host "🧪 Testing backend..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/health" -ErrorAction Stop
    if ($response.status -eq "healthy") {
        Write-Host "✅ Backend is healthy" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Backend health check returned: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Backend is not responding yet (may need more time)" -ForegroundColor Yellow
}

Write-Host ""

# Test frontend
Write-Host "🧪 Testing frontend..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Frontend is accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Frontend is not responding yet (may need more time)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🎉 Containers are running!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Frontend:  http://localhost" -ForegroundColor White
Write-Host "🔌 Backend:   http://localhost:5000" -ForegroundColor White
Write-Host "💚 Health:    http://localhost:5000/api/health" -ForegroundColor White
Write-Host "📨 Messages:  http://localhost:5000/api/messages" -ForegroundColor White
Write-Host ""
Write-Host "📋 Useful commands:" -ForegroundColor Gray
Write-Host "  View logs:     docker-compose logs -f" -ForegroundColor Gray
Write-Host "  Stop services: docker-compose down" -ForegroundColor Gray
Write-Host "  Restart:       docker-compose restart" -ForegroundColor Gray
Write-Host ""
Write-Host "📱 Test responsive design:" -ForegroundColor Cyan
Write-Host "  1. Open http://localhost in browser" -ForegroundColor Gray
Write-Host "  2. Press F12 (DevTools)" -ForegroundColor Gray
Write-Host "  3. Press Ctrl+Shift+M (Device Toolbar)" -ForegroundColor Gray
Write-Host "  4. Test different screen sizes" -ForegroundColor Gray
Write-Host ""
