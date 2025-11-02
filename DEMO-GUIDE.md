# 🎯 Zero Trust Multi-Device Attack Demo

## Two-Device Live Demonstration Setup

This demo shows **real lateral movement prevention** using Zero Trust architecture across two physical devices.

---

## 🎬 Quick Start (15 Minutes)

### Device 2 (Defender) - Setup First

```bash
# 1. Navigate to project
cd zt-microguard-single-pc

# 2. Make scripts executable
chmod +x setup-device2-defender.sh

# 3. Run defender setup
./setup-device2-defender.sh

# 4. Note the IP address shown - give this to Device 1!
```

**Expected output:**
```
✅ Cluster accessible!
🛡️  Starting Defense Dashboard Server...
   📍 Local: http://localhost:3000
   🌐 Network: http://192.168.1.100:3000
   
   ⚠️  Use this URL on Device 1 (Attacker) to view defense
```

**Keep this terminal running!**

---

### Device 1 (Attacker) - Setup Second

```bash
# 1. Create attacker directory
mkdir zt-attacker
cd zt-attacker

# 2. Copy attack files (from artifacts above)
# - attacker-dashboard.html
# - attack-server.js
# - setup-device1-attacker.sh

# 3. Make script executable
chmod +x setup-device1-attacker.sh

# 4. Run attacker setup
./setup-device1-attacker.sh

# 5. Enter Device 2's IP when prompted
```

**Expected output:**
```
Enter Device 2 IP: 192.168.1.100
Enter port: 30080
✅ Target is reachable!
🚀 Starting Attack Dashboard...
   Dashboard: http://localhost:3001
```

**Your attack dashboard will open automatically!**

---

## 📁 File Structure

### Device 2 (Defender)
```
zt-microguard-single-pc/
├── k8s/                           # Existing Kubernetes configs
├── scripts/                       # Existing scripts
├── src/                           # Existing microservices
├── run-demo.sh                    # Existing cluster setup
├── defense-dashboard.html         # NEW: Defense UI
├── defense-server.js             # NEW: Real-time log server
└── setup-device2-defender.sh     # NEW: Automated setup
```

### Device 1 (Attacker)
```
zt-attacker/
├── attacker-dashboard.html        # Attack control panel
├── attack-server.js              # Attack proxy server
└── setup-device1-attacker.sh     # Automated setup
```

---

## 🎭 Running the Demo

### Part 1: Introduction (2 minutes)

**Show Both Screens:**
- **Left Screen (Device 2):** Defense Dashboard - All green, systems healthy
- **Right Screen (Device 1):** Attack Dashboard - Ready to launch

**Explain:**
> "We have a Kubernetes cluster running microservices. One service 
> (malicious-service) has been compromised by an attacker. Let's see 
> if they can steal user data through lateral movement."

---

### Part 2: Attack #1 - Lateral Movement (3 minutes)

**On Device 1 (Attack Dashboard):**
1. Point to "Compromised Service: malicious-service"
2. Click **"Lateral Movement Attack"**

**What Happens:**

**Attack Screen Shows:**
```
[18:45:23] → Initiating lateral movement attack...
[18:45:23] → Target: http://192.168.1.100:30080/user-data
[18:45:23] → Spoofed Identity: spiffe://example.org/malicious-service
[18:45:23] ✗ BLOCKED by Zero Trust! (HTTP 403)
[18:45:23] → Defense: OPA policy denied malicious-service → /user-data
```

**Defense Screen Shows:**
```
🚨 ATTACK DETECTED

[18:45:23] ❌ BLOCKED
   malicious-service → GET /user-data
   🛡️ Lateral movement blocked by Zero Trust policy
   
Stats Updated:
   Blocked Attacks: 1 ↑
   Block Rate: 100%
```

**Explain:**
> "Even though malicious-service is running INSIDE the cluster with 
> a valid identity, Zero Trust blocks it. There's no policy allowing 
> this service to access user data. Attack prevented!"

---

### Part 3: Attack #2 - Legitimate Access (2 minutes)

**On Device 1:**
1. Change dropdown to **"payment-service (legitimate)"**
2. Click **"Lateral Movement Attack"** again

**Attack Screen Shows:**
```
[18:46:15] ✓ Attack succeeded! Data accessed (HTTP 200)
[18:46:15] → Exfiltrated: {
    "id": "user-123",
    "username": "demo_user",
    "balance": 1500.75,
    "caller_spiffe_id": "spiffe://example.org/payment-service"
}
```

**Defense Screen Shows:**
```
[18:46:15] ✅ ALLOWED
   payment-service → GET /user-data
   Policy match: payment-service authorized
```

**Explain:**
> "Same endpoint, but payment-service HAS explicit permission. 
> This is 'least privilege' - each service gets exactly what it 
> needs, nothing more."

---

### Part 4: Automated Attack Sequence (4 minutes)

**On Device 1:**
1. Change back to **"malicious-service"**
2. Click **"Launch Full Automated Attack Sequence"**

**Watch both screens:**
- Attack screen rapidly shows multiple attempts
- Defense screen shows real-time blocking
- Stats increase: Total requests rising, blocks increasing

**Attack Types Shown:**
```
1. Lateral Movement    → BLOCKED ❌
2. Data Exfiltration   → BLOCKED ❌
3. Service Enumeration → ALLOWED (health endpoint) ✅
4. Privilege Escalation → BLOCKED ❌
```

**Explain:**
> "The attacker tries everything: accessing data, privilege 
> escalation, service scanning. Zero Trust blocks unauthorized 
> attempts while allowing legitimate health checks. Every attempt 
> is logged for forensic analysis."

---

### Part 5: Policy Demonstration (Optional, 3 minutes)

**On Device 2 Terminal:**

```bash
# Show current policy
kubectl get configmap opa-policy -n zero-trust-demo -o yaml

# Temporarily allow malicious-service (simulate policy update)
kubectl edit configmap opa-policy -n zero-trust-demo

# Add this rule:
allow if {
    input.attributes.request.http.path == "/user-data"
    input.attributes.request.http.headers["x-spiffe-id"] == 
      "spiffe://example.org/malicious-service"
}

# Restart OPA
kubectl rollout restart deployment/opa -n zero-trust-demo
```

**On Device 1:**
- Launch same attack
- **Now it succeeds!**

**On Device 2:**
- Shows ALLOWED event

**Explain:**
> "Policies are dynamic. We can update them as business needs change. 
> But every change is tracked and auditable. Now let's revert..."

```bash
# Revert policy
kubectl rollout undo deployment/opa -n zero-trust-demo
```

**Attack blocked again!**

---

## 📊 Key Points to Emphasize

### 1. Identity Verification
> "Every service has a cryptographic identity (SPIFFE). Can't be faked or spoofed."

### 2. Zero Trust in Action
> "Never trust, always verify. Even internal services are checked on every request."

### 3. Lateral Movement Prevention
> "Attacker compromised a service but can't move laterally. Breach is contained."

### 4. Least Privilege
> "Payment-service gets exactly what it needs. Malicious-service gets nothing."

### 5. Complete Visibility
> "Every access attempt is logged. Security team can see everything in real-time."

---

## 🔧 Troubleshooting

### Device 1 Can't Connect to Device 2

**Problem:** "Connection error: ECONNREFUSED"

**Solutions:**

```bash
# On Device 2: Check if Envoy is accessible
kubectl get svc envoy -n zero-trust-demo

# Test locally first
curl http://localhost:30080/health

# Check firewall
# macOS:
sudo pfctl -d

# Linux:
sudo ufw allow 30080

# Windows: Add firewall rule for inbound port 30080
```

**Alternative:** Use port forwarding

```bash
# On Device 2:
kubectl port-forward -n zero-trust-demo svc/envoy 8080:80 --address 0.0.0.0

# On Device 1: Target http://DEVICE2_IP:8080
```

---

### No Events on Defense Dashboard

**Problem:** Dashboard shows "Monitoring..." but no events appear

**Solution:**

```bash
# Check OPA is logging
kubectl logs -l app=opa -n zero-trust-demo | grep "Decision Log"

# Restart defense server
# Press Ctrl+C and rerun:
node defense-server.js
```

---

### Pods Not Running

**Problem:** Some pods show "CrashLoopBackOff"

**Solution:**

```bash
# Check pod status
kubectl get pods -n zero-trust-demo

# Check specific pod logs
kubectl describe pod <pod-name> -n zero-trust-demo
kubectl logs <pod-name> -n zero-trust-demo

# Restart everything
kubectl delete namespace zero-trust-demo
./run-demo.sh
```

---

## 🎓 Demo Variations

### Variation 1: Show Policy Editing Live
1. Show attack being blocked
2. Edit policy to allow
3. Attack succeeds
4. Revert policy
5. Attack blocked again

### Variation 2: Multiple Services
1. Test payment-service → Allowed
2. Test auth-service → Blocked
3. Test malicious-service → Blocked
4. Show each has different permissions

### Variation 3: Real-World Scenario
1. Explain: "Payment processing needs user balance"
2. Attack: "But what if payment service is compromised?"
3. Show: "Even then, it can ONLY access user-service, nothing else"

---

## 📸 Screenshots for Backup

If live demo fails, have these ready:

1. **Architecture Diagram** - Show components
2. **Policy File** - Show OPA rules
3. **Successful Block** - Screenshot of denied access
4. **Allowed Access** - Screenshot of payment-service success
5. **Dashboard** - Both attack and defense screens

---

## ⏱️ Timeline

Total demo: **15-20 minutes**

| Section | Duration |
|---------|----------|
| Introduction | 2 min |
| Setup explanation | 2 min |
| Attack #1 (Blocked) | 3 min |
| Attack #2 (Allowed) | 2 min |
| Automated attacks | 4 min |
| Policy demonstration | 3 min |
| Q&A / Conclusion | 4 min |

---

## 📋 Pre-Demo Checklist

**1 Day Before:**
- [ ] Test full demo end-to-end
- [ ] Verify both devices can connect
- [ ] Record backup video
- [ ] Prepare slides

**1 Hour Before:**
- [ ] Device 2: Start cluster (`./setup-device2-defender.sh`)
- [ ] Device 2: Verify all pods running
- [ ] Device 2: Note IP address
- [ ] Device 1: Configure target IP
- [ ] Device 1: Test connection
- [ ] Test one attack successfully

**5 Minutes Before:**
- [ ] Both dashboards visible on screen
- [ ] Defense dashboard showing system healthy
- [ ] Attack dashboard ready to launch
- [ ] Backup slides loaded

---

## 🎯 Success Criteria

Your demo is successful when audience sees:

✅ Compromised service attempting access  
✅ Zero Trust immediately blocking attempt  
✅ Legitimate service getting access  
✅ Real-time logging of all attempts  
✅ Clear visualization of prevention  

**Key Takeaway for Audience:**
> "Zero Trust prevents lateral movement even when attackers 
> compromise internal services. Every request is verified 
> against explicit policies."

---

## 📞 Emergency Contacts

If demo fails during presentation:

1. **Switch to backup video** (recorded earlier)
2. **Use screenshots** with verbal explanation
3. **Show architecture** and explain conceptually
4. **Live log review** - Show kubectl logs of past attacks

**Remember:** Even if live demo fails, the architecture and 
concepts are what matter. You can explain using diagrams!

---

## 🚀 After Demo

```bash
# Device 2: Clean up
kubectl delete namespace zero-trust-demo
minikube stop

# Device 1: Clean up
# Just Ctrl+C the attack server
```

---

**Good luck! You've got this! 🎉**