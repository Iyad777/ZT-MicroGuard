#!/bin/bash

echo "📜 Authorization Decision History"
echo "================================="
echo ""

kubectl logs -l app=opa -n zero-trust-demo --tail=100 2>/dev/null | \
    grep "Decision Log" | \
    jq -r '
        "[" + (.time | split("T")[1] | split(".")[0]) + "] " +
        (if .result then "✅ ALLOWED" else "❌ DENIED " end) + 
        " | " + 
        ((.input.attributes.request.http.headers["x-spiffe-id"] // "no-identity") | 
         if . == "no-identity" then . else (split("/") | .[-1]) end) + 
        " → " + 
        .input.attributes.request.http.method + " " + 
        .input.attributes.request.http.path
    ' 2>/dev/null | \
    awk '!seen[$0]++' | \
    tail -20

echo ""
echo "💡 Showing last 20 unique decisions"
