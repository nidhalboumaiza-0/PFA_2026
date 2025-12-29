import express from 'express';
import { createServer } from 'http';
import cors from 'cors';
import helmet from 'helmet';
import notificationRoutes from './routes/notificationRoutes.js';
import { initializeSocket } from './socket/socket.js';
import { setSocketIO } from './services/notificationService.js';
import { startNotificationConsumer, disconnectConsumer } from './kafka/notificationConsumer.js';
import { startScheduledNotificationJob } from './jobs/scheduledNotificationJob.js';
import morgan from 'morgan';
import { bootstrap, getConfig, getMongoUri, mongoose } from '../../../shared/index.js';
import { initializeEmailTransporter } from './services/emailService.js';
import { initializeOneSignal } from './config/onesignal.js';

const app = express();
const httpServer = createServer(app);
const SERVICE_NAME = 'notification-service';

// Will be initialized after bootstrap
let io;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Routes
app.use('/api/v1/notifications', notificationRoutes);

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
        message: 'Notification Service is healthy',
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

// MongoDB connection using Consul config
const connectDB = async () => {
  try {
    await mongoose.connect(getMongoUri());
    console.log('✅ MongoDB connected');
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

    // Initialize email transporter with config from Consul
    initializeEmailTransporter();

    // Initialize OneSignal with config from Consul
    initializeOneSignal();

    // Initialize Socket.IO with config from Consul
    io = initializeSocket(httpServer);
    setSocketIO(io);

    // Connect to MongoDB using Consul config
    await connectDB();

    // Start Kafka consumer
    await startNotificationConsumer();

    // Start scheduled notification job
    startScheduledNotificationJob();

    // Start HTTP server
    const PORT = getConfig('PORT', 3007);
    httpServer.listen(PORT, () => {
      console.log(`✅ Notification Service running on port ${PORT}`);
      console.log(`Environment: ${getConfig('NODE_ENV', 'development')}`);
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
