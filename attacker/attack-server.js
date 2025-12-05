// attack-server.js - Run on Device 1 (Attacker)
// This creates a local server that makes requests to Device 2

const http = require('http');
const https = require('https');
const url = require('url');

const PORT = 3001;

// CORS enabled HTTP server
const server = http.createServer((req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.url === '/') {
    // Serve the attack dashboard
    const fs = require('fs');
    fs.readFile('attack-dashboard.html', (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Dashboard not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(data);
    });
    return;
  }

  if (req.url.startsWith('/attack?')) {
    // Parse attack parameters
    const params = url.parse(req.url, true).query;
    const targetUrl = params.target;
    const spiffeId = params.spiffeId;
    const path = params.path;

    console.log(`\n🔴 LAUNCHING ATTACK`);
    console.log(`   Target: ${targetUrl}${path}`);
    console.log(`   Spoofed Identity: ${spiffeId}`);

    // Make request to target cluster
    const targetUri = new URL(targetUrl + path);
    const client = targetUri.protocol === 'https:' ? https : http;

    const options = {
      hostname: targetUri.hostname,
      port: targetUri.port,
      path: targetUri.pathname,
      method: 'GET',
      headers: {
        'x-spiffe-id': spiffeId,
        'User-Agent': 'ZT-Attack-Simulator/1.0'
      }
    };

    const proxyReq = client.request(options, (proxyRes) => {
      let body = '';
      proxyRes.on('data', (chunk) => {
        body += chunk;
      });

      proxyRes.on('end', () => {
        console.log(`   Response: HTTP ${proxyRes.statusCode}`);
        
        if (proxyRes.statusCode === 403) {
          console.log(`   ❌ BLOCKED by Zero Trust!`);
        } else if (proxyRes.statusCode === 200) {
          console.log(`   ⚠️  Attack succeeded!`);
        }

        // Return response to dashboard
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          statusCode: proxyRes.statusCode,
          body: body,
          headers: proxyRes.headers
        }));
      });
    });

    proxyReq.on('error', (error) => {
      console.log(`   ❌ Connection failed: ${error.message}`);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: error.message,
        statusCode: 0
      }));
    });

    proxyReq.end();
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, () => {
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║     🔴 ATTACKER SERVER RUNNING                  ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');
  console.log(`   📍 Dashboard: http://localhost:${PORT}`);
  console.log('');
  console.log('   Instructions:');
  console.log('   1. Open dashboard in browser');
  console.log('   2. Configure target (Device 2 IP)');
  console.log('   3. Launch attacks');
  console.log('');
  console.log('   Press Ctrl+C to stop');
  console.log('');
});