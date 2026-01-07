import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import helmet from 'helmet';
import cors from 'cors';
import { mongoose, bootstrap, getConfig, getMongoUri } from '../../../shared/index.js';
import { connectProducer } from '../../../shared/kafka/producer.js';
import { initializeSocketIO } from './socket/socketHandlers.js';
import messageRoutes from './routes/messageRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import morgan from 'morgan';
import { initializeS3 } from './utils/messageHelpers.js';

const app = express();
const httpServer = createServer(app);
const SERVICE_NAME = 'messaging-service';

let io;
let onlineUsers;
let redisClients = null;

// Setup Redis adapter for horizontal scaling
const setupRedisAdapter = async (redisHost, redisPort) => {
  try {
    const pubClient = createClient({ 
      socket: { host: redisHost, port: redisPort } 
    });
    const subClient = pubClient.duplicate();

    pubClient.on('error', (err) => console.error('Redis Pub Client Error:', err.message));
    subClient.on('error', (err) => console.error('Redis Sub Client Error:', err.message));

    await Promise.all([pubClient.connect(), subClient.connect()]);
    
    io.adapter(createAdapter(pubClient, subClient));
    console.log(`✅ Socket.IO Redis adapter connected to ${redisHost}:${redisPort}`);
    
    return { pubClient, subClient };
  } catch (error) {
    console.warn('⚠️ Redis adapter not available, using in-memory adapter');
    return null;
  }
};

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Request logger
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    service: 'Messaging Service',
    status: 'healthy',
    timestamp: new Date().toISOString(),
    onlineUsers: onlineUsers ? onlineUsers.size : 0,
    config: 'Centralized (Consul KV)'
  });
});

// Routes - mounted at root because API gateway strips /api/v1/messages prefix
// When accessed directly (not via gateway), use full path /api/v1/messages/...
app.use('/api/v1/messages', messageRoutes);
app.use('/api/v1/messaging/admin', adminRoutes);
// When accessed via API gateway, path is already stripped to /conversations, etc.
app.use('/', messageRoutes);
app.use('/admin', adminRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);

  // Multer file upload errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({
      message: 'File size exceeds the maximum allowed limit',
    });
  }

  if (err.name === 'MulterError') {
    return res.status(400).json({
      message: `File upload error: ${err.message}`,
    });
  }

  res.status(err.status || 500).json({
    message: err.message || 'Internal server error',
  });
});

// Start server with Consul bootstrap
const startServer = async () => {
  try {
    // Bootstrap: Load config from Consul + register service
    await bootstrap(SERVICE_NAME);
    
    // Initialize S3 client with config from Consul
    initializeS3();
    
    const PORT = getConfig('PORT', '3006');
    const REDIS_HOST = getConfig('REDIS_HOST', 'localhost');
    const REDIS_PORT = getConfig('REDIS_PORT', '6379');
    const FRONTEND_URL = getConfig('FRONTEND_URL', 'http://localhost:3000');
    
    // Initialize Socket.IO with config
    io = new Server(httpServer, {
      cors: {
        origin: '*', // Allow all origins for mobile app
        methods: ['GET', 'POST'],
        credentials: true,
      },
      transports: ['websocket', 'polling'],
      pingTimeout: 60000, // 60s - how long to wait for pong
      pingInterval: 30000, // 30s - how often to send ping
      connectTimeout: 45000, // 45s - connection timeout
      allowEIO3: true, // Allow Engine.IO v3 clients for compatibility
    });

    // Initialize Socket.IO handlers and get onlineUsers map
    onlineUsers = initializeSocketIO(io);

    // Store io and onlineUsers in app for access in controllers
    app.set('io', io);
    app.set('onlineUsers', onlineUsers);
    
    // Connect to MongoDB using config from Consul
    const mongoUri = getMongoUri('esante_messaging');
    await mongoose.connect(mongoUri);
    console.log('✅ MongoDB connected');

    // Connect Kafka producer (after config is loaded)
    await connectProducer();
    console.log('✅ Kafka producer connected');

    // TEMPORARILY DISABLED: Redis adapter for Socket.IO (enables horizontal scaling)
    // Disabled to debug "invalid payload" errors
    // redisClients = await setupRedisAdapter(REDIS_HOST, REDIS_PORT);
    console.log('⚠️ Redis adapter DISABLED for debugging');

    // Start HTTP server with Socket.IO
    httpServer.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════╗
║   💬 MESSAGING SERVICE STARTED 💬      ║
║   Port: ${PORT}                         ║
║   Environment: ${getConfig('NODE_ENV')} ║
╚════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('❌ Failed to start service:', error);
    process.exit(1);
  }
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Start the server
startServer();
