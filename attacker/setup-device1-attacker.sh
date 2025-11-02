#!/bin/bash
# setup-device1-attacker.sh
# Run this on Device 1 (Attacker machine)

echo "╔══════════════════════════════════════════════════╗"
echo "║   Device 1 (Attacker) Setup                     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Check Node.js
command -v node >/dev/null 2>&1 || { 
    echo "❌ Node.js not found. Install Node.js first."
    echo "   Download from: https://nodejs.org"
    exit 1
}

echo "✅ Node.js found!"
echo ""

# Get target information
echo "📍 Target Configuration"
echo "─────────────────────────────────────────────────"
echo ""
echo "Enter Device 2 (Victim) information:"
echo ""
read -p "Device 2 IP address (e.g., 192.168.1.100): " TARGET_IP
read -p "Envoy port (default: 30080): " TARGET_PORT
TARGET_PORT=${TARGET_PORT:-30080}

TARGET_URL="http://${TARGET_IP}:${TARGET_PORT}"

echo ""
echo "🧪 Testing connection to target..."
if curl -s --connect-timeout 5 "${TARGET_URL}/health" > /dev/null 2>&1; then
    echo "✅ Target is reachable!"
else
    echo "⚠️  Warning: Could not reach target"
    echo "   Make sure:"
    echo "   1. Device 2 is running and cluster is up"
    echo "   2. Both devices are on same network"
    echo "   3. Firewall allows connection"
    echo ""
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 1
    fi
fi

echo ""
echo "📦 Installing dependencies..."
npm install express cors

# Update attack dashboard with target
echo ""
echo "🔧 Configuring attack dashboard..."
cat > attacker-config.js << EOF
// Auto-generated configuration
const ATTACK_CONFIG = {
    targetUrl: '${TARGET_URL}',
    targetIp: '${TARGET_IP}',
    targetPort: ${TARGET_PORT}
};
EOF

echo "✅ Configuration saved!"
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Device 1 Ready to Attack!                     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "🎯 Target Configuration:"
echo "   Victim: ${TARGET_URL}"
echo ""
echo "🚀 Starting Attack Dashboard..."
echo ""
echo "   Dashboard will open at: http://localhost:3001"
echo "   Press Ctrl+C to stop"
echo ""

# Start attack server
node attack-server.js

# Open browser automatically
sleep 2
if command -v open >/dev/null 2>&1; then
    open "http://localhost:3001"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:3001"
elif command -v start >/dev/null 2>&1; then
    start "http://localhost:3001"
fi