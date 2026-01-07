import express from 'express';
import { createServer } from 'http';
import cors from 'cors';
import helmet from 'helmet';
import { createProxyMiddleware } from 'http-proxy-middleware';
import httpProxy from 'http-proxy';
import { bootstrap, getConfig } from '../../shared/index.js';
import {
  serviceConfig,
  getServiceUrl,
  isConsulAvailable,
  registerGateway,
  getAllServiceUrls,
  initializeConsulConfig
} from './config/serviceDiscovery.js';
import { authenticateToken, requireAdmin } from './middleware/auth.js';
import { initializeRateLimiters, getGeneralLimiter, getAuthLimiter } from './middleware/rateLimiter.js';
import requestLogger from './middleware/logger.js';
import morgan from 'morgan';
import healthRoutes from './routes/health.js';
import adminDashboardRoutes from './routes/adminDashboard.js';

const app = express();
const server = createServer(app);
const SERVICE_NAME = 'api-gateway';

// ==================== WebSocket Proxies using http-proxy ====================
// Using http-proxy directly for WebSocket connections (more reliable than http-proxy-middleware for WS)
const notificationTarget = process.env.NOTIFICATION_SERVICE_URL || 'http://notification-service:3007';
const messagingTarget = process.env.MESSAGING_SERVICE_URL || 'http://messaging-service:3006';
const userServiceTarget = process.env.USER_SERVICE_URL || 'http://user-service:3002';
const rdvServiceTarget = process.env.RDV_SERVICE_URL || 'http://rdv-service:3003';

// Create separate proxy servers for each service
const notificationWsProxy = httpProxy.createProxyServer({
  target: notificationTarget,
  ws: true,
  changeOrigin: true,
});

const messagingWsProxy = httpProxy.createProxyServer({
  target: messagingTarget,
  ws: true,
  changeOrigin: true,
});

const userWsProxy = httpProxy.createProxyServer({
  target: userServiceTarget,
  ws: true,
  changeOrigin: true,
});

const rdvWsProxy = httpProxy.createProxyServer({
  target: rdvServiceTarget,
  ws: true,
  changeOrigin: true,
});

// Handle proxy errors gracefully
notificationWsProxy.on('error', (err, req, res) => {
  const ignoredCodes = ['ECONNRESET', 'EPIPE', 'ETIMEDOUT', 'ECONNREFUSED'];
  if (!ignoredCodes.includes(err.code)) {
    console.error('❌ Notification proxy error:', err.code || err.message);
  }
});

messagingWsProxy.on('error', (err, req, res) => {
  const ignoredCodes = ['ECONNRESET', 'EPIPE', 'ETIMEDOUT', 'ECONNREFUSED'];
  if (!ignoredCodes.includes(err.code)) {
    console.error('❌ Messaging proxy error:', err.code || err.message);
  }
});

userWsProxy.on('error', (err, req, res) => {
  const ignoredCodes = ['ECONNRESET', 'EPIPE', 'ETIMEDOUT', 'ECONNREFUSED'];
  if (!ignoredCodes.includes(err.code)) {
    console.error('❌ User service proxy error:', err.code || err.message);
  }
});

rdvWsProxy.on('error', (err, req, res) => {
  const ignoredCodes = ['ECONNRESET', 'EPIPE', 'ETIMEDOUT', 'ECONNREFUSED'];
  if (!ignoredCodes.includes(err.code)) {
    console.error('❌ RDV service proxy error:', err.code || err.message);
  }
});

// Handle WebSocket upgrades on the HTTP server
server.on('upgrade', (req, socket, head) => {
  const url = req.url || '';
  
  console.log(`🔄 WebSocket UPGRADE request received: ${url}`);
  
  // Prevent socket errors from crashing the server
  socket.on('error', (err) => {
    if (err.code !== 'ECONNRESET') {
      console.log(`⚠️ WS socket error: ${err.code}`);
    }
  });

  if (url.startsWith('/messaging/socket.io') || url.startsWith('/messaging/?')) {
    // Rewrite path: /messaging/socket.io -> /socket.io
    req.url = req.url.replace(/^\/messaging/, '');
    console.log(`🔌 WS → messaging-service: ${url} → ${req.url}`);
    messagingWsProxy.ws(req, socket, head);
  } else if (url.startsWith('/user-socket') || url.startsWith('/admin/user-socket')) {
    // Admin user management real-time updates
    // Rewrite path: /admin/user-socket -> /user-socket
    req.url = req.url.replace(/^\/admin/, '');
    console.log(`🔌 WS → user-service: ${url} → ${req.url}`);
    userWsProxy.ws(req, socket, head);
  } else if (url.startsWith('/rdv-socket') || url.startsWith('/admin/rdv-socket')) {
    // Admin appointment management real-time updates
    // Rewrite path: /admin/rdv-socket -> /rdv-socket
    req.url = req.url.replace(/^\/admin/, '');
    console.log(`🔌 WS → rdv-service: ${url} → ${req.url}`);
    rdvWsProxy.ws(req, socket, head);
  } else if (url.startsWith('/socket.io') || url.startsWith('/?EIO=')) {
    console.log(`🔌 WS → notification-service: ${url}`);
    notificationWsProxy.ws(req, socket, head);
  } else {
    console.log(`❌ Unknown WS path: ${url}`);
    socket.destroy();
  }
});

console.log(`✅ WebSocket proxies configured:`);
console.log(`   /socket.io → ${notificationTarget}`);
console.log(`   /messaging/socket.io → ${messagingTarget}`);
console.log(`   /user-socket → ${userServiceTarget}`);
console.log(`   /rdv-socket → ${rdvServiceTarget}`);

// ==================== HTTP Proxies for Socket.IO Polling ====================
// Use http-proxy for both HTTP (polling) and WebSocket to avoid conflicts
// Route HTTP polling requests through the same proxy as WebSocket

// Express route to handle HTTP polling for notification service
app.use('/socket.io', (req, res) => {
  notificationWsProxy.web(req, res);
});

// Express route to handle HTTP polling for messaging service (with path rewrite)
app.use('/messaging', (req, res) => {
  console.log(`📨 HTTP request to /messaging: ${req.method} ${req.url}`);
  // Rewrite the URL to remove /messaging prefix
  req.url = req.url.replace(/^\/messaging/, '') || '/';
  messagingWsProxy.web(req, res);
});

// Express route to handle HTTP polling for user-service socket (admin)
app.use('/user-socket', (req, res) => {
  console.log(`📨 HTTP request to /user-socket: ${req.method} ${req.url}`);
  userWsProxy.web(req, res);
});

// Express route to handle HTTP polling for rdv-service socket (admin appointments)
app.use('/rdv-socket', (req, res) => {
  console.log(`📨 HTTP request to /rdv-socket: ${req.method} ${req.url}`);
  rdvWsProxy.web(req, res);
});

// ==================== Security & Middleware ====================

// CORS configuration - allow all origins (must be FIRST)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept']
}));

app.use(helmet());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);
app.use(morgan('dev'));
// Rate limiter is applied via getGeneralLimiter() after bootstrap

// ==================== Health Routes ====================

app.use(healthRoutes);

// ==================== Admin Dashboard Routes ====================
// These routes are handled directly by the API gateway (not proxied)
app.use('/api/v1/admin/dashboard', adminDashboardRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'E-Santé API Gateway',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// ==================== Setup Service Proxies ====================

const setupProxies = () => {
  // Apply general rate limiter (now initialized after bootstrap)
  app.use(getGeneralLimiter());

  // Setup dynamic proxy for each microservice using Consul discovery
  // Skip socketio - already handled separately above
  Object.entries(serviceConfig).forEach(([name, config]) => {
    // Skip socketio - handled by dedicated WebSocket proxy
    if (name === 'socketio') return;

    const middleware = [];

    // Apply auth limiter for auth service
    if (name === 'auth') {
      middleware.push(getAuthLimiter());
    }

    // Apply authentication if service is not public
    if (!config.public) {
      middleware.push(authenticateToken);
    }

    // Apply admin-only restriction
    if (config.adminOnly) {
      middleware.push(requireAdmin);
    }

    // Create dynamic proxy middleware with Consul discovery
    const proxyMiddleware = createProxyMiddleware({
      router: async (req) => {
        try {
          const url = await getServiceUrl(name);
          return url;
        } catch (error) {
          console.error(`❌ Failed to resolve ${name}:`, error.message);
          return config.fallbackUrl;
        }
      },
      // Don't rewrite the path - services expect full /api/v1/<service>/... paths
      changeOrigin: true,
      ws: false, // DISABLED - WebSocket handled separately by http-proxy in server.on('upgrade')
      proxyTimeout: 60000, // 60 seconds timeout
      timeout: 60000, // Connection timeout
      onProxyReq: (proxyReq, req, res) => {
        // Forward user info to downstream services
        if (req.user) {
          proxyReq.setHeader('X-User', JSON.stringify(req.user));
        }

        // Restream parsed body for JSON requests only
        // Skip for multipart/form-data (file uploads) to preserve the original request
        const contentType = req.headers['content-type'] || '';
        if (!contentType.includes('multipart/form-data') && req.body) {
          // Always restream the body if it exists (even if empty object)
          // because express.json() has already consumed the stream
          const bodyData = JSON.stringify(req.body);
          proxyReq.setHeader('Content-Type', 'application/json');
          proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
          proxyReq.write(bodyData);
        }
        console.log(`📡 Proxying ${req.method} ${req.url} → ${config.serviceName}`);
      },
      onProxyRes: (proxyRes, req, res) => {
        // Remove connection: close header to allow keep-alive
        proxyRes.headers['connection'] = 'keep-alive';
        console.log(`✅ Response from ${name}: ${proxyRes.statusCode}`);
      },
      onError: (err, req, res) => {
        console.error(`❌ Proxy error for ${name}:`, err.message);
        res.status(503).json({
          message: `Service ${name} temporarily unavailable`,
          error: getConfig('NODE_ENV', 'development') === 'development' ? err.message : undefined
        });
      }
    });

    middleware.push(proxyMiddleware);

    app.use(config.path, ...middleware);
    console.log(`✅ Registered route: ${config.path} → ${config.serviceName} (Consul)`);
  });

  // NOTE: WebSocket upgrade handling is done at the top of the file using http-proxy
  // Do NOT add another server.on('upgrade') handler here

  // ==================== Error Handling ====================
  // Must be registered AFTER proxy routes

  // 404 handler
  app.use((req, res) => {
    res.status(404).json({
      message: `Route ${req.originalUrl} not found`
    });
  });

  // Global error handler
  app.use((err, req, res, next) => {
    console.error('❌ Gateway Error:', err);

    res.status(err.statusCode || 500).json({
      message: err.message || 'Internal server error',
      ...(getConfig('NODE_ENV', 'development') === 'development' && { stack: err.stack })
    });
  });
};

// ==================== Start Server ====================

const startServer = async () => {
  try {
    // Bootstrap: Load config from Consul + Register service
    await bootstrap(SERVICE_NAME);

    // Initialize Redis-backed rate limiters (after config loaded from Consul)
    await initializeRateLimiters();

    // Initialize Consul connection info in serviceDiscovery
    initializeConsulConfig();

    // Setup proxy routes (after config is loaded)
    setupProxies();

    // Check Consul availability
    const consulAvailable = await isConsulAvailable();

    const PORT = getConfig('PORT', 3000);
    server.listen(PORT, async () => {
      console.log(`
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║          🏥 E-SANTÉ API GATEWAY STARTED 🏥              ║
║                                                          ║
║  Port:        ${PORT}                                    ║
║  Environment: ${getConfig('NODE_ENV', 'development')}                   ║
║  Health:      http://localhost:${PORT}/health           ║
║  Services:    http://localhost:${PORT}/health/services  ║
║  Consul:      ${consulAvailable ? '✅ Connected' : '⚠️  Fallback mode'}              ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
      `);

      // NOTE: WebSocket upgrade handling is at the top of the file using http-proxy directly

      // Register API Gateway with Consul
      if (consulAvailable) {
        await registerGateway(PORT);
        console.log('\n📋 Service Discovery Mode: CONSUL\n');
      } else {
        console.log('\n📋 Service Discovery Mode: STATIC (Consul unavailable)\n');
      }

      console.log('Registered Routes:\n');
      Object.entries(serviceConfig).forEach(([name, config]) => {
        console.log(`   ${name.padEnd(15)} → ${config.path.padEnd(30)} → ${config.serviceName}`);
      });
      console.log('\n');
    });
  } catch (error) {
    console.error('❌ Failed to start API Gateway:', error);
    process.exit(1);
  }
};

// Note: Graceful shutdown (deregisterService) is handled by bootstrap()
// Additional cleanup for gateway registration is in serviceDiscovery.js

startServer();
