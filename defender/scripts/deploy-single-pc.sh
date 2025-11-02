#!/bin/bash

echo "🚀 Deploying ZT-MicroGuard on Single PC"
echo "======================================="

# Create namespaces
kubectl create namespace spire-system 2>/dev/null || true
kubectl create namespace zero-trust-demo 2>/dev/null || true

echo "📁 Deploying SPIRE (Identity Provider)..."
kubectl apply -f k8s/spire/server.yaml
kubectl apply -f k8s/spire/agent.yaml

# Give pods time to be created
echo "⏳ Waiting for SPIRE pods to be created..."
sleep 10

# Wait for SPIRE server
echo "⏳ Waiting for SPIRE server to be ready..."
kubectl wait --for=condition=ready pod -l app=spire-server -n spire-system --timeout=300s

# Wait for SPIRE agent
echo "⏳ Waiting for SPIRE agent to be ready..."
kubectl wait --for=condition=ready pod -l app=spire-agent -n spire-system --timeout=300s

echo "🔐 Registering services with SPIRE..."
kubectl apply -f k8s/spire/entries.yaml

# Wait for registration job to complete
echo "⏳ Waiting for registration to complete..."
sleep 5
kubectl wait --for=condition=complete job/spire-registration -n spire-system --timeout=120s

echo "⚖️ Deploying OPA (Policy Engine)..."
kubectl apply -f k8s/opa/configmap.yaml
kubectl apply -f k8s/opa/deployment.yaml

echo "🌐 Deploying Envoy (Sidecar/Proxy)..."
kubectl apply -f k8s/envoy/configmap.yaml
kubectl apply -f k8s/envoy/deployment.yaml

echo "🛠️ Deploying Microservices..."
kubectl apply -f k8s/microservices/deployments.yaml
kubectl apply -f k8s/microservices/services.yaml

# Wait for critical deployments
echo "⏳ Waiting for services to be ready..."
sleep 10
kubectl wait --for=condition=ready pod -l app=envoy -n zero-trust-demo --timeout=120s
kubectl wait --for=condition=ready pod -l app=opa -n zero-trust-demo --timeout=120s
kubectl wait --for=condition=ready pod -l app=user-service -n zero-trust-demo --timeout=120s

echo ""
echo "✅ Deployment Complete!"
echo "📊 Pod Status:"
kubectl get pods -n zero-trust-demo
kubectl get pods -n spire-system

echo ""
#echo "🌐 Envoy Gateway URL (Wait for external IP if not using Minikube):"
#minikube service envoy -n zero-trust-demo --url

