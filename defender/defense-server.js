// defense-server.js - Run on Device 2 (Defender)
// This serves the defense dashboard and streams real OPA logs

const express = require('express');
const { exec } = require('child_process');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.static('.'));

// Serve defense dashboard
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/defense-dashboard.html');
});

// API endpoint to get real-time events from OPA logs
app.get('/api/events', (req, res) => {
  exec('kubectl logs -l app=opa -n zero-trust-demo --tail=50', (error, stdout, stderr) => {
    if (error) {
      console.error('Error fetching logs:', error);
      return res.json([]);
    }

    try {
      const events = stdout
        .split('\n')
        .filter(line => line.includes('Decision Log'))
        .map(line => {
          try {
            // Extract JSON from log line
            const jsonMatch = line.match(/\{.*\}/);
            if (!jsonMatch) return null;
            
            const json = JSON.parse(jsonMatch[0]);
            
            // Extract service name from SPIFFE ID
            const spiffeId = json.input?.attributes?.request?.http?.headers?.[
              'x-spiffe-id'
            ] || 'unknown';
            const serviceName = spiffeId.split('/').pop() || 'unknown';
            
            return {
              timestamp: new Date(json.time).toLocaleTimeString(),
              service: serviceName,
              path: json.input?.attributes?.request?.http?.path || 'unknown',
              method: json.input?.attributes?.request?.http?.method || 'GET',
              decision: json.result ? 'allowed' : 'blocked',
              spiffeId: spiffeId
            };
          } catch (e) {
            return null;
          }
        })
        .filter(event => event !== null);

      res.json(events);
    } catch (e) {
      console.error('Error parsing logs:', e);
      res.json([]);
    }
  });
});

// API endpoint for stats
app.get('/api/stats', (req, res) => {
  exec('kubectl logs -l app=opa -n zero-trust-demo', (error, stdout) => {
    if (error) {
      return res.json({ total: 0, allowed: 0, denied: 0 });
    }

    const logs = stdout.split('\n').filter(line => line.includes('Decision Log'));
    const total = logs.length;
    const allowed = logs.filter(line => line.includes('"result":true')).length;
    const denied = total - allowed;

    res.json({
      total,
      allowed,
      denied,
      blockRate: total > 0 ? Math.round((denied / total) * 100) : 0
    });
  });
});

// API endpoint for system status
app.get('/api/status', (req, res) => {
  exec('kubectl get pods -n zero-trust-demo -o json', (error, stdout) => {
    if (error) {
      return res.json({ healthy: false, pods: [] });
    }

    try {
      const data = JSON.parse(stdout);
      const pods = data.items.map(pod => ({
        name: pod.metadata.name,
        status: pod.status.phase,
        ready: pod.status.conditions?.find(c => c.type === 'Ready')?.status === 'True'
      }));

      const allHealthy = pods.every(p => p.status === 'Running' && p.ready);

      res.json({
        healthy: allHealthy,
        pods,
        timestamp: new Date().toISOString()
      });
    } catch (e) {
      res.json({ healthy: false, pods: [] });
    }
  });
});

// Server-Sent Events for real-time log streaming
app.get('/api/stream', (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  });

  // Send initial connection message
  res.write('data: {"type":"connected"}\n\n');

  // Stream kubectl logs
  const logStream = exec('kubectl logs -f -l app=opa -n zero-trust-demo --tail=10');

  logStream.stdout.on('data', (data) => {
    const lines = data.toString().split('\n');
    lines.forEach(line => {
      if (line.includes('Decision Log')) {
        try {
          const jsonMatch = line.match(/\{.*\}/);
          if (jsonMatch) {
            const json = JSON.parse(jsonMatch[0]);
            const spiffeId = json.input?.attributes?.request?.http?.headers?.['x-spiffe-id'] || 'unknown';
            const serviceName = spiffeId.split('/').pop() || 'unknown';
            
            const event = {
              type: 'security_event',
              timestamp: new Date().toLocaleTimeString(),
              service: serviceName,
              path: json.input?.attributes?.request?.http?.path || 'unknown',
              method: json.input?.attributes?.request?.http?.method || 'GET',
              decision: json.result ? 'allowed' : 'blocked',
              spiffeId: spiffeId
            };

            res.write(`data: ${JSON.stringify(event)}\n\n`);
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    });
  });

  // Cleanup on disconnect
  req.on('close', () => {
    logStream.kill();
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║     🛡️  DEFENSE DASHBOARD RUNNING               ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');
  console.log(`   📍 Local: http://localhost:${PORT}`);
  
  // Try to get local IP
  const os = require('os');
  const interfaces = os.networkInterfaces();
  const addresses = [];
  
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        addresses.push(iface.address);
      }
    }
  }
  
  if (addresses.length > 0) {
    console.log(`   🌐 Network: http://${addresses[0]}:${PORT}`);
    console.log('');
    console.log(`   ⚠️  Use this URL on Device 1 (Attacker) to view defense`);
  }
  
  console.log('');
  console.log('   Monitoring:');
  console.log('   - Real-time OPA decisions');
  console.log('   - Attack blocking events');
  console.log('   - System health status');
  console.log('');
  console.log('   Press Ctrl+C to stop');
  console.log('');
});