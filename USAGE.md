# ZT-MicroGuard Usage Guide

## 🚀 Quick Start

### Start Everything
```bash
./run-demo.sh
```

### Run Security Tests
```bash
./scripts/test-single-pc.sh
```

### View Dashboard
```bash
./scripts/dashboard.sh
```

---

## 📊 Monitoring Commands

| Command | Description |
|---------|-------------|
| `./scripts/dashboard.sh` | One-time security dashboard |
| `./scripts/view-history.sh` | Full authorization history |
| `./scripts/monitor-single-pc.sh` | Live monitoring (auto-refresh) |
| `./scripts/monitor-simple.sh` | Simple decision log viewer |

---

## 🔧 Management Commands

### Check Status
```bash
kubectl get pods -n zero-trust-demo
kubectl get pods -n spire-system
```

### View Logs
```bash
# Envoy logs
kubectl logs -l app=envoy -n zero-trust-demo

# OPA logs  
kubectl logs -l app=opa -n zero-trust-demo

# Service logs
kubectl logs -l app=user-service -n zero-trust-demo
```

### Restart Components
```bash
# Restart OPA (e.g., after policy change)
kubectl rollout restart deployment/opa -n zero-trust-demo

# Restart Envoy
kubectl rollout restart deployment/envoy -n zero-trust-demo

# Restart a specific service
kubectl rollout restart deployment/user-service -n zero-trust-demo
```

---

## 🧪 Manual Testing

Get the Envoy URL:
```bash
kubectl get svc envoy -n zero-trust-demo
```

Run manual tests:
```bash
ENVOY_IP=$(kubectl get svc envoy -n zero-trust-demo -o jsonpath='{.spec.clusterIP}')

# Test legitimate access
curl -H "x-spiffe-id: spiffe://example.org/payment-service" \
  http://$ENVOY_IP/user-data

# Test blocked access
curl -H "x-spiffe-id: spiffe://example.org/malicious-service" \
  http://$ENVOY_IP/user-data

# Health check
curl http://$ENVOY_IP/health
```

---

## 🔐 Security Policy

Current policy (`k8s/opa/configmap.yaml`):
- ✅ `payment-service` → `/user-data` (ALLOWED)
- ❌ `malicious-service` → `/user-data` (DENIED)
- ❌ `auth-service` → `/user-data` (DENIED)
- ✅ Anyone → `/health` (ALLOWED)

### Modify Policy
```bash
# Edit policy
nano k8s/opa/configmap.yaml

# Apply changes
kubectl apply -f k8s/opa/configmap.yaml
kubectl rollout restart deployment/opa -n zero-trust-demo
```

---

## 🧹 Cleanup

### Stop Everything
```bash
minikube delete
```

### Remove Namespaces Only
```bash
kubectl delete namespace zero-trust-demo
kubectl delete namespace spire-system
```

---

## 🆘 Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod <pod-name> -n zero-trust-demo
kubectl logs <pod-name> -n zero-trust-demo
```

### Connection Issues
```bash
# Test cluster connectivity
kubectl get svc -n zero-trust-demo

# Test from inside cluster
kubectl run test --rm -i --image=curlimages/curl -- curl http://envoy.zero-trust-demo/health
```

### Reset Everything
```bash
minikube delete
./run-demo.sh
```

---

## 📈 What's Happening
```
Request → Envoy Proxy → OPA (Policy Check) → Service
                              ↓
                         ✅ Allow / ❌ Deny
```

1. **SPIRE** provides cryptographic identities (SPIFFE IDs)
2. **Envoy** intercepts all requests
3. **OPA** evaluates authorization policies
4. **Services** only receive authorized requests

---

## 🎓 Key Concepts

- **Zero Trust**: Never trust, always verify
- **SPIFFE ID**: Cryptographic service identity
- **Policy-Based Access**: Explicit allow rules
- **Least Privilege**: Only grant necessary access

