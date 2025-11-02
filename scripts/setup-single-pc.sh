#!/bin/bash
set -e

echo "🚀 ZT-MicroGuard Single PC Setup"
echo "================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "❌ Minikube not found. Please install Minikube."
    exit 1
fi

# Start single-node Minikube cluster
echo "🔄 Starting Minikube cluster..."
# FIX: Reduced memory allocation to meet system limits.
minikube start --cpus=4 --memory=4096mb --driver=docker

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

# Set up Docker environment to build images directly into Minikube's context
eval $(minikube docker-env)

echo "✅ Minikube cluster ready!"