import express from 'express';
import { createServer } from 'http';
import cors from 'cors';
import helmet from 'helmet';
import { createProxyMiddleware } from 'http-proxy-middleware';
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

const app = express();
const server = createServer(app);
const SERVICE_NAME = 'api-gateway';

// Store WebSocket proxy for upgrade handling
let wsProxy = null;

// ==================== Setup Socket.IO Proxy ====================
// Socket.IO needs special handling - set up before body parsing middleware
const setupSocketIOProxy = () => {
  // Use Docker container hostname for internal communication
  const socketIOTarget = process.env.NOTIFICATION_SERVICE_URL || 'http://notification-service:3007';

  wsProxy = createProxyMiddleware({
    target: socketIOTarget,
    changeOrigin: true,
    ws: true,
    logger: console,
    onError: (err, req, res) => {
      console.error('❌ Socket.IO proxy error:', err.message);
    }
  });

  // Must be registered BEFORE body parsing middleware
  app.use('/socket.io', wsProxy);
  console.log(`✅ Socket.IO proxy configured → ${socketIOTarget}`);
};

// Setup Socket.IO proxy immediately (before body parsing)
setupSocketIOProxy();

// ==================== Security & Middleware ====================

app.use(helmet());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);
app.use(morgan('dev'));
// Rate limiter is applied via getGeneralLimiter() after bootstrap

// ==================== Health Routes ====================

app.use(healthRoutes);

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

  // CORS configuration (needs config loaded)
  app.use(cors({
    origin: [
      getConfig('FRONTEND_URL', 'http://localhost:3000'),
      getConfig('ADMIN_URL', 'http://localhost:3001'),
      getConfig('MOBILE_APP_SCHEME', 'esante://')
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
  }));

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
      ws: true, // Enable WebSocket proxying
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
        if (!contentType.includes('multipart/form-data') && req.body && Object.keys(req.body).length > 0) {
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

  // Handle WebSocket upgrade for socket.io
  server.on('upgrade', (req, socket, head) => {
    if (req.url.startsWith('/socket.io') && wsProxy) {
      console.log('🔌 WebSocket upgrade request for socket.io');
      wsProxy.upgrade(req, socket, head);
    }
  });

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
