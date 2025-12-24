import express from 'express';
import { createServer } from 'http';
import mongoose from 'mongoose';
import cors from 'cors';
import helmet from 'helmet';
import auditRoutes from './routes/auditRoutes.js';
import { initializeSocket, emitCriticalEvent, emitSecurityAlert } from './socket/socket.js';
import { startAuditConsumer, disconnectConsumer } from './kafka/auditConsumer.js';
import AuditLog from './models/AuditLog.js';
import morgan from 'morgan';
import { bootstrap, getConfig, getMongoUri } from '../../../shared/index.js';

const app = express();
const httpServer = createServer(app);
const SERVICE_NAME = 'audit-service';

// Will be initialized after bootstrap
let io;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// API Routes
app.use('/api/v1/audit', auditRoutes);

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const mongoStatus = mongoose.connection.readyState;
    const isHealthy = mongoStatus === 1;
    
    const statusMap = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };
    
    if (isHealthy) {
      res.json({
        success: true,
        message: 'Audit Service is healthy',
        data: {
          status: 'healthy',
          timestamp: new Date().toISOString(),
          mongodb: statusMap[mongoStatus] || 'unknown',
        },
      });
    } else {
      res.status(503).json({
        success: false,
        message: 'Service starting up',
        data: {
          status: 'starting',
          mongodb: statusMap[mongoStatus] || 'unknown',
        },
      });
    }
  } catch (error) {
    res.status(503).json({
      success: false,
      message: 'Service unhealthy',
      error: error.message,
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: getConfig('NODE_ENV', 'development') === 'development' ? err.message : undefined,
  });
});

// MongoDB connection with change stream setup
const connectDB = async () => {
  try {
    await mongoose.connect(getMongoUri());
    console.log('✅ MongoDB connected');

    // Set up change stream for real-time monitoring (requires replica set)
    try {
      const changeStream = AuditLog.watch();

      changeStream.on('change', async (change) => {
        if (change.operationType === 'insert') {
          const auditLog = change.fullDocument;

          // Emit critical events to admin dashboard
          if (auditLog.severity === 'critical') {
            emitCriticalEvent(auditLog);
          }

          // Emit security alerts
          if (auditLog.isSecurityRelevant && (auditLog.severity === 'warning' || auditLog.severity === 'critical')) {
            emitSecurityAlert(auditLog);
          }
        }
      });

      changeStream.on('error', (error) => {
        console.log('⚠️  Change stream error:', error.message);
        console.log('⚠️  Running without real-time monitoring - audit logs will still be saved');
      });

      console.log('✅ MongoDB change stream initialized for real-time monitoring');
    } catch (changeStreamError) {
      console.log('⚠️  Change streams not available (requires MongoDB replica set)');
      console.log('⚠️  Running without real-time monitoring - audit logs will still be saved');
    }
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Start server
const startServer = async () => {
  try {
    // Bootstrap: Load config from Consul + Register service
    await bootstrap(SERVICE_NAME);
    
    // Initialize Socket.IO
    io = initializeSocket(httpServer);

    // Connect to MongoDB using Consul config
    await connectDB();

    // Start Kafka consumer
    await startAuditConsumer();

    // Start HTTP server
    const PORT = getConfig('PORT', 3008);
    httpServer.listen(PORT, () => {
      console.log(`✅ Audit Service running on port ${PORT}`);
      console.log(`Environment: ${getConfig('NODE_ENV', 'development')}`);
      console.log(`📊 Real-time monitoring enabled via Socket.IO`);
    });
  } catch (error) {
    console.error('❌ Error starting server:', error);
    process.exit(1);
  }
};

// Handle shutdown signals (additional cleanup beyond bootstrap)
process.on('SIGTERM', async () => {
  console.log('\nSIGTERM received. Additional cleanup...');
  try {
    await disconnectConsumer();
    if (io) io.close();
    await mongoose.connection.close();
    console.log('✅ Additional cleanup completed');
  } catch (error) {
    console.error('❌ Error during additional cleanup:', error);
  }
});

process.on('SIGINT', async () => {
  console.log('\nSIGINT received. Additional cleanup...');
  try {
    await disconnectConsumer();
    if (io) io.close();
    await mongoose.connection.close();
    console.log('✅ Additional cleanup completed');
  } catch (error) {
    console.error('❌ Error during additional cleanup:', error);
  }
});

// Note: Service deregistration from Consul is handled by bootstrap()

startServer();
