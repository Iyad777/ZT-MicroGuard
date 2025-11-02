#!/bin/bash

set -e

echo "╔══════════════════════════════════════════════════╗"
echo "║   Device 2 (Defender) Setup                     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# --- Prerequisites Check ---
echo "🔍 Checking prerequisites..."
MISSING=""

if ! command -v node &> /dev/null; then
    MISSING="${MISSING}node "
fi

if ! command -v npm &> /dev/null; then
    MISSING="${MISSING}npm "
fi

if ! command -v minikube &> /dev/null; then
    MISSING="${MISSING}minikube "
fi

if ! command -v kubectl &> /dev/null; then
    MISSING="${MISSING}kubectl "
fi

if ! command -v jq &> /dev/null; then
    MISSING="${MISSING}jq "
fi

if [ ! -z "$MISSING" ]; then
    echo "❌ Missing prerequisites: $MISSING"
    echo ""
    echo "Please install the missing tools:"
    echo "  • Node.js & npm: https://nodejs.org/"
    echo "  • Minikube: https://minikube.sigs.k8s.io/docs/start/"
    echo "  • kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "  • jq: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

echo "✅ All prerequisites met!"
echo ""

# --- Install Node.js Dependencies ---
echo "📦 Installing Node.js dependencies..."
if [ -f "defense-server.js" ] && [ -f "defense-dashboard.html" ]; then
    # Check if node_modules exists, if not install
    if [ ! -d "node_modules" ]; then
        npm install express cors
    fi
    echo "✅ Dashboard files found"
else
    echo "⚠️  Warning: defense-server.js or defense-dashboard.html not found"
fi
echo ""

# --- Check Docker ---
echo "🐳 Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi
echo "✅ Docker is running"
echo ""

# --- Start Minikube Cluster ---
echo "🚀 Starting Minikube cluster..."
if minikube status | grep -q "Running"; then
    echo "✅ Minikube already running"
else
    minikube start --cpus=4 --memory=4096mb --driver=docker
    minikube addons enable ingress
    minikube addons enable metrics-server
fi
eval $(minikube docker-env)
echo "✅ Minikube cluster ready!"
echo ""

# --- Build Services ---
echo "🔨 Building services..."
SERVICES=("auth-service" "user-service" "payment-service" "malicious-service")

for SERVICE in "${SERVICES[@]}"; do
    echo "📦 Building $SERVICE..."
    if [ -d "src/$SERVICE" ]; then
        (cd src/$SERVICE && docker build -t $SERVICE:latest . > /dev/null 2>&1)
    else
        echo "⚠️  Warning: src/$SERVICE not found, skipping..."
    fi
done

# Build test-tools if it exists
if [ -d "test-tools" ]; then
    echo "📦 Building test-tools..."
    (cd test-tools && docker build -t test-tools:latest . > /dev/null 2>&1)
fi

echo "✅ All services built!"
echo ""

# --- Deploy Everything ---
echo "🚀 Deploying ZT-MicroGuard..."

# Create namespaces
kubectl create namespace spire-system 2>/dev/null || true
kubectl create namespace zero-trust-demo 2>/dev/null || true

# Deploy SPIRE
echo "📁 Deploying SPIRE..."
kubectl apply -f k8s/spire/server.yaml > /dev/null 2>&1
kubectl apply -f k8s/spire/agent.yaml > /dev/null 2>&1

sleep 5

kubectl wait --for=condition=ready pod -l app=spire-server -n spire-system --timeout=180s > /dev/null 2>&1
kubectl wait --for=condition=ready pod -l app=spire-agent -n spire-system --timeout=180s > /dev/null 2>&1

# Register services
echo "🔐 Registering services with SPIRE..."
kubectl apply -f k8s/spire/entries.yaml > /dev/null 2>&1
sleep 5
kubectl wait --for=condition=complete job/spire-registration -n spire-system --timeout=180s > /dev/null 2>&1 || echo "⚠️  Registration may still be completing..."

# Deploy OPA
echo "⚖️  Deploying OPA..."
kubectl apply -f k8s/opa/configmap.yaml > /dev/null 2>&1
kubectl apply -f k8s/opa/deployment.yaml > /dev/null 2>&1

# Deploy Envoy
echo "🌐 Deploying Envoy..."
kubectl apply -f k8s/envoy/configmap.yaml > /dev/null 2>&1
kubectl apply -f k8s/envoy/deployment.yaml > /dev/null 2>&1

# Deploy Microservices
echo "🛠️  Deploying Microservices..."
kubectl apply -f k8s/microservices/deployments.yaml > /dev/null 2>&1
kubectl apply -f k8s/microservices/services.yaml > /dev/null 2>&1

echo "✅ Deployment complete!"
echo ""

# --- Wait for all pods to be ready ---
echo ""
echo "⏳ Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod -l app=envoy -n zero-trust-demo --timeout=180s
kubectl wait --for=condition=ready pod -l app=opa -n zero-trust-demo --timeout=180s
echo ""

# --- Start Minikube Tunnel ---
echo "🌐 Exposing Envoy service..."

# Kill any existing tunnel processes
pkill -f "minikube tunnel" 2>/dev/null || true
sleep 2

# Start tunnel in background
minikube tunnel > /dev/null 2>&1 &
TUNNEL_PID=$!
echo "Tunnel PID: $TUNNEL_PID (save this to kill later)"

# Give tunnel time to establish
echo "⏳ Waiting for tunnel to establish..."
sleep 8

# --- Get Network Information ---
DEVICE_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
ENVOY_EXTERNAL=$(kubectl get svc envoy -n zero-trust-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "127.0.0.1")
ENVOY_PORT="80"

# --- Display Device Information ---
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Device 2 Ready!                               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "📊 Cluster Information:"
echo "   Envoy Gateway: http://${ENVOY_EXTERNAL}:${ENVOY_PORT}"
echo ""
echo "🌐 Network Information:"
echo "   Device 2 Local IP: $DEVICE_IP"
echo ""
echo "⚠️  IMPORTANT: Give this IP to Device 1 (Attacker)"
echo "   Target URL: http://${ENVOY_EXTERNAL}:${ENVOY_PORT}"
echo ""

# --- Test Cluster Access ---
echo "🧪 Testing setup..."
MAX_ATTEMPTS=6
ATTEMPT=0
ACCESS_OK=false

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    if curl -s --connect-timeout 3 --max-time 5 http://${ENVOY_EXTERNAL}:${ENVOY_PORT}/health > /dev/null 2>&1; then
        echo "✅ Cluster is accessible!"
        ACCESS_OK=true
        break
    fi
    
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo "⏳ Attempt $ATTEMPT/$MAX_ATTEMPTS: Waiting for tunnel (${ATTEMPT}s)..."
        sleep 3
    fi
done

if [ "$ACCESS_OK" = false ]; then
    echo "⚠️  Cluster not immediately accessible from host"
    echo "   This is normal - tunnel may still be starting"
    echo "   Try: curl http://${ENVOY_EXTERNAL}:${ENVOY_PORT}/health"
fi

echo ""

# --- Start Defense Dashboard ---
echo "🛡️  Starting Defense Dashboard Server..."
echo "   This will show real-time attack blocking"
echo ""

if [ ! -d "defense-dashboard" ]; then
    echo "❌ Error: defense-dashboard directory not found!"
    echo "   Please ensure the dashboard files are present"
    exit 1
fi

cd defense-dashboard

echo "╔══════════════════════════════════════════════════╗"
echo "║     🛡️  DEFENSE DASHBOARD RUNNING               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "   📍 Local: http://localhost:3000"
echo "   🌐 Network: http://${DEVICE_IP}:3000"
echo ""
echo "   ⚠️  Use this URL on Device 1 (Attacker) to view defense"
echo ""
echo "   Monitoring:"
echo "   - Real-time OPA decisions"
echo "   - Attack blocking events"
echo "   - System health status"
echo ""
echo "   Press Ctrl+C to stop"
echo ""

# Start the dashboard server
npm start

# Cleanup on exit
trap "echo ''; echo '🧹 Cleaning up...'; kill $TUNNEL_PID 2>/dev/null || true" EXIT