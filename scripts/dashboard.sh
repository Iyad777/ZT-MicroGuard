#!/bin/bash

clear
echo "╔════════════════════════════════════════════════════════╗"
echo "║        ZT-MicroGuard Security Dashboard               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# System Status
echo "📊 SYSTEM STATUS"
echo "─────────────────────────────────────────────────────────"
RUNNING=$(kubectl get pods -n zero-trust-demo --no-headers 2>/dev/null | grep -c "Running")
TOTAL=$(kubectl get pods -n zero-trust-demo --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "Pods Running: $RUNNING/$TOTAL"

SPIRE_RUNNING=$(kubectl get pods -n spire-system --no-headers 2>/dev/null | grep -c "Running")
SPIRE_TOTAL=$(kubectl get pods -n spire-system --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "SPIRE Running: $SPIRE_RUNNING/$SPIRE_TOTAL"
echo ""

# Security Stats
echo "🔐 SECURITY STATISTICS"
echo "─────────────────────────────────────────────────────────"
TOTAL_REQUESTS=$(kubectl logs -l app=opa -n zero-trust-demo 2>/dev/null | grep -c "Decision Log")
ALLOWED=$(kubectl logs -l app=opa -n zero-trust-demo 2>/dev/null | grep "Decision Log" | grep -c '"result":true')
DENIED=$(kubectl logs -l app=opa -n zero-trust-demo 2>/dev/null | grep "Decision Log" | grep -c '"result":false')

echo "Total Requests: $TOTAL_REQUESTS"
echo "✅ Allowed:     $ALLOWED"
echo "❌ Denied:      $DENIED"

if [ $TOTAL_REQUESTS -gt 0 ]; then
    BLOCK_RATE=$((DENIED * 100 / TOTAL_REQUESTS))
    echo "🛡️  Block Rate:   $BLOCK_RATE%"
fi
echo ""

# Recent Activity
echo "📋 RECENT DECISIONS (Last 5)"
echo "─────────────────────────────────────────────────────────"
kubectl logs -l app=opa -n zero-trust-demo --tail=20 2>/dev/null | \
    grep "Decision Log" | \
    jq -r '
        (if .result then "✅" else "❌" end) + 
        " " +
        (.time | split("T")[1] | split(".")[0]) +
        " | " + 
        ((.input.attributes.request.http.headers["x-spiffe-id"] // "none") | 
         if . == "none" then . else (split("/") | .[-1] | .[0:18]) end) + 
        " → " + 
        .input.attributes.request.http.path
    ' 2>/dev/null | tail -5 || echo "No activity yet"

echo ""
echo "─────────────────────────────────────────────────────────"
echo "💡 Quick Commands:"
echo "   ./scripts/test-single-pc.sh     - Run tests"
echo "   ./scripts/view-history.sh       - Full history"
echo "   ./scripts/dashboard.sh          - Refresh dashboard"
echo ""
