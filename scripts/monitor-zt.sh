#!/bin/bash

echo "🔐 ZT-MicroGuard Live Monitor"
echo "=============================="
echo ""

# Function to parse OPA decision logs
parse_opa_decision() {
    local log="$1"
    
    # Extract key fields
    local spiffe_id=$(echo "$log" | jq -r '.input.attributes.request.http.headers["x-spiffe-id"] // "no-identity"')
    local path=$(echo "$log" | jq -r '.input.attributes.request.http.path')
    local method=$(echo "$log" | jq -r '.input.attributes.request.http.method')
    local result=$(echo "$log" | jq -r '.result')
    local timestamp=$(echo "$log" | jq -r '.time')
    
    # Color code the result
    if [ "$result" = "true" ]; then
        result_display="✅ ALLOWED"
    else
        result_display="❌ DENIED"
    fi
    
    echo "[$timestamp]"
    echo "  Identity: $spiffe_id"
    echo "  Request:  $method $path"
    echo "  Decision: $result_display"
    echo ""
}

# Get recent OPA logs
echo "📋 Recent Authorization Decisions:"
echo "-----------------------------------"

kubectl logs -l app=opa -n zero-trust-demo --tail=50 2>/dev/null | \
    grep "Decision Log" | \
    while IFS= read -r line; do
        # Extract JSON part (everything after the timestamp prefix)
        json_part=$(echo "$line" | grep -o '{.*}')
        if [ ! -z "$json_part" ]; then
            parse_opa_decision "$json_part"
        fi
    done

echo ""
echo "🔄 Press Ctrl+C to exit, or run with --follow to watch live:"
echo "   kubectl logs -l app=opa -n zero-trust-demo -f | grep 'Decision Log'"
