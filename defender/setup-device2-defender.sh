#!/bin/bash
# setup-device2-defender.sh
# Run this on Device 2 (Defender/Victim machine)

echo "╔══════════════════════════════════════════════════╗"
echo "║   Device 2 (Defender) Setup                     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not found. Install Docker Desktop first."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found. Install kubectl first."; exit 1; }
command -v minikube >/dev/null 2>&1 || { echo "❌ minikube not found. Install minikube first."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js not found. Install Node.js first."; exit 1; }

echo "✅ All prerequisites met!"
echo ""

# Setup Node.js server dependencies
echo "📦 Installing Node.js dependencies..."
npm install express cors

echo ""
echo "🚀 Starting Kubernetes cluster..."
../run-demo.sh

echo ""
echo "⏳ Waiting for all pods to be ready..."
sleep 30

kubectl wait --for=condition=ready pod -l app=envoy -n zero-trust-demo --timeout=120s
kubectl wait --for=condition=ready pod -l app=opa -n zero-trust-demo --timeout=120s

echo ""
echo "🌐 Exposing Envoy service..."
# Start minikube tunnel in background
minikube tunnel >/dev/null 2>&1 &
TUNNEL_PID=$!
echo "Tunnel PID: $TUNNEL_PID (save this to kill later)"

# Wait a bit for tunnel
sleep 5

# Get service details
ENVOY_IP=$(kubectl get svc envoy -n zero-trust-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
ENVOY_PORT=$(kubectl get svc envoy -n zero-trust-demo -o jsonpath='{.spec.ports[0].port}')

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Device 2 Ready!                               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "📊 Cluster Information:"
echo "   Envoy Gateway: http://${ENVOY_IP}:${ENVOY_PORT}"
echo ""

# Get local IP
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
echo "🌐 Network Information:"
echo "   Device 2 Local IP: ${LOCAL_IP}"
echo ""
echo "⚠️  IMPORTANT: Give this IP to Device 1 (Attacker)"
echo "   Target URL: http://${ENVOY_IP}:${ENVOY_PORT}"
echo ""

# Test the setup
echo "🧪 Testing setup..."
curl -s http://${ENVOY_IP}:${ENVOY_PORT}/health > /dev/null && echo "✅ Cluster accessible!" || echo "❌ Cluster not accessible"

echo ""
echo "🛡️  Starting Defense Dashboard Server..."
echo "   This will show real-time attack blocking"
echo ""

# Start defense server
node defense-server.js

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up..."
    kill $TUNNEL_PID 2>/dev/null
    echo "Stopped minikube tunnel"
}

trap cleanup EXIT