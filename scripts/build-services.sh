#!/bin/bash

# This makes the script exit immediately if any command fails
set -e

echo "🔨 Building Microservices..."
echo "============================"

# Set the Minikube docker environment for this script
eval $(minikube docker-env)

# --- ADDED "test-tools" TO THIS LIST ---
SERVICES=("auth-service" "user-service" "payment-service" "malicious-service" "test-tools")

for SERVICE in "${SERVICES[@]}"; do
    echo "📦 Building $SERVICE..."
    
    # Check if the service is in 'src' or in the root
    if [ -d "src/$SERVICE" ]; then
        (cd src/$SERVICE && docker build -t $SERVICE:latest .)
    else
        # This will handle the 'test-tools' folder in the root
        (cd $SERVICE && docker build -t $SERVICE:latest .)
    fi
done

echo "✅ All services built successfully!"
