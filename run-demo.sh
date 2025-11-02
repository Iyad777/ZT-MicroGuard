#!/bin/bash

# --- PRE-REQUISITES CHECK ---
if ! command -v minikube &> /dev/null || ! command -v kubectl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "---------------------------------------------------------"
    echo "🚨 Missing prerequisites!"
    echo "Please ensure you have minikube, kubectl, and jq installed."
    echo "---------------------------------------------------------"
    exit 1
fi
chmod +x scripts/*.sh # Ensure all internal scripts are executable

echo "🎬 ZT-MicroGuard Single PC Demo"
echo "==============================="

# Step 1: Setup cluster
echo "🔄 Step 1: Setting up cluster..."
./scripts/setup-single-pc.sh
if [ $? -ne 0 ]; then echo "Setup failed. Aborting."; exit 1; fi


# Step 2: Build services
echo "🔨 Step 2: Building services..."
./scripts/build-services.sh
if [ $? -ne 0 ]; then echo "Build failed. Aborting."; exit 1; fi

# Step 3: Deploy everything
echo "🚀 Step 3: Deploying ZT-MicroGuard..."
./scripts/deploy-single-pc.sh
if [ $? -ne 0 ]; then echo "Deployment failed. Aborting."; exit 1; fi

# Step 4: Run tests
echo "🧪 Step 4: Running security tests..."
./scripts/test-single-pc.sh

echo ""
echo "🎉 Demo Setup Complete! Check the test results above."
echo ""
echo "📊 Next steps:"
echo "  • Monitor system: ./scripts/dashboard.sh"
echo "  • View decisions: ./scripts/view-history.sh"
echo "  • Run tests again: ./scripts/test-single-pc.sh"
echo ""
echo "🧹 To clean up everything: minikube delete"