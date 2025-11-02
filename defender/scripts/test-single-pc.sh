#!/bin/bash

echo "🧪 ZT-MicroGuard Single PC Testing"
echo "=================================="
echo ""

# Get the Envoy service URL from minikube
echo "🔍 Getting Envoy URL..."
ENVOY_URL=$(kubectl get svc envoy -n zero-trust-demo -o jsonpath='{.spec.clusterIP}')

if [ -z "$ENVOY_URL" ]; then
    echo "❌ ERROR: Could not get Envoy service. Is it running?"
    echo "Run: kubectl get svc -n zero-trust-demo"
    exit 1
fi

ENVOY_URL="http://${ENVOY_URL}"
echo "✅ Using Envoy at: $ENVOY_URL"
echo ""

# Run from inside the cluster using a test pod
echo "🚀 Running tests from inside the cluster..."
echo ""

# Use a minimal 'alpine' image and install what we need (curl + jq).
# Pass ENVOY_URL as an environment variable to the pod.
# Use single quotes for 'sh -c' to prevent the local shell from expanding variables like $CODE.
kubectl run test-client \
    --rm \
    -i \
    --tty \
    --image=alpine:latest \
    -n zero-trust-demo \
    --env="ENVOY_URL=$ENVOY_URL" \
    -- sh -c '
# Install tools
echo "🔧 Installing curl and jq in test pod..."
apk add --no-cache curl jq
echo ""

# --- Test 1 ---
echo "---"
echo "🧪 Test 1: Legitimate Access (Payment Service -> /user-data)"
# Get HTTP status code, write body to /dev/null
CODE=$(curl -s -w "%{http_code}" -H "x-spiffe-id: spiffe://example.org/payment-service" -o /dev/null $ENVOY_URL/user-data)
if [ "$CODE" = "200" ]; then
    echo "  ✅ PASSED (Code: $CODE)"
    echo "  Response:"
    # Now we print the actual body, formatted with jq
    curl -s -H "x-spiffe-id: spiffe://example.org/payment-service" $ENVOY_URL/user-data | jq "."
else
    echo "  ❌ FAILED (Expected 200, Got: $CODE)"
fi
echo "---"


# --- Test 2 ---
echo "🧪 Test 2: Blocked Access (Malicious Service -> /user-data)"
CODE=$(curl -s -w "%{http_code}" -H "x-spiffe-id: spiffe://example.org/malicious-service" -o /dev/null $ENVOY_URL/user-data)
if [ "$CODE" = "403" ]; then
    echo "(Code: $CODE - Access Denied ❌)"
else
    echo "  ❌ FAILED (Expected 403, Got: $CODE)"
fi
echo "---"


# --- Test 3 ---
echo "🧪 Test 3: Blocked Access (Auth Service -> /user-data)"
CODE=$(curl -s -w "%{http_code}" -H "x-spiffe-id: spiffe://example.org/auth-service" -o /dev/null $ENVOY_URL/user-data)
if [ "$CODE" = "403" ]; then
    echo "(Code: $CODE - Access Denied ❌)"
else
    echo "  ❌ FAILED (Expected 403, Got: $CODE)"
fi
echo "---"


# --- Test 4 ---
echo "🧪 Test 4: Health Check (No ID)"
# The policy allows /health for anyone, so no ID is needed.
CODE=$(curl -s -w "%{http_code}" -o /dev/null $ENVOY_URL/health)
if [ "$CODE" = "200" ]; then
    echo "  ✅ PASSED (Code: $CODE)"
    echo "  Response:"
    curl -s $ENVOY_URL/health | jq "."
else
    echo "  ❌ FAILED (Expected 200, Got: $CODE)"
fi
echo "---"
'

echo ""
echo "✅ Testing Complete!"

