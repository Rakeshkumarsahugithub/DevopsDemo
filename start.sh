#!/bin/bash

echo "🚀 Starting DevOps Demo Application..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Build and start services
echo "📦 Building Docker images..."
docker-compose build

echo ""
echo "🎬 Starting services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check service health
echo ""
echo "🔍 Checking service health..."

BACKEND_HEALTH=$(curl -s http://localhost:5000/api/health | grep -o "healthy" || echo "unhealthy")
if [ "$BACKEND_HEALTH" = "healthy" ]; then
    echo "✅ Backend is healthy"
else
    echo "⚠️  Backend health check failed"
fi

FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✅ Frontend is accessible"
else
    echo "⚠️  Frontend is not accessible"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Application is running!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Frontend:  http://localhost"
echo "🔌 Backend:   http://localhost:5000"
echo "💚 Health:    http://localhost:5000/api/health"
echo "📨 Messages:  http://localhost:5000/api/messages"
echo ""
echo "📋 View logs:     docker-compose logs -f"
echo "🛑 Stop services: docker-compose down"
echo ""
