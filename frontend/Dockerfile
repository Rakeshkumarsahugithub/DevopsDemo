# Multi-stage build for frontend
# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
ARG VITE_API_URL=http://localhost:5000
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# Stage 2: Serve with simple Node.js server (No Nginx!)
FROM node:20-alpine

WORKDIR /app

# Install serve package to serve static files
RUN npm install -g serve

# Copy built files from builder
COPY --from=builder /app/dist ./dist

# Expose port 80
EXPOSE 80

# Serve the static files
CMD ["serve", "-s", "dist", "-l", "80"]
