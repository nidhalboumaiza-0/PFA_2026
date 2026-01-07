import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import http from 'http';
import { connectDB, errorHandler, requestLogger, bootstrap, getConfig, getMongoUri } from '../../../shared/index.js';
import userRoutes from './routes/userRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import { initializeConsumer } from './consumers/userConsumer.js';
import { initializeS3 } from './services/s3Service.js';
import { initializeSocket } from './socket/index.js';

const app = express();
const server = http.createServer(app);
const SERVICE_NAME = 'user-service';

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);
app.use(morgan('dev'));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    service: 'User Service',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Routes
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/users/admin', adminRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    message: 'Route not found'
  });
});

// Error handling
app.use(errorHandler);

// Start server with Consul bootstrap
const startServer = async () => {
  try {
    // Bootstrap: Load config from Consul + register service
    await bootstrap(SERVICE_NAME);
    
    // Initialize S3 client with config from Consul
    initializeS3();
    
    // Connect to MongoDB using config from Consul
    const mongoUri = getMongoUri('esante_users');
    await connectDB(mongoUri);
    
    // Initialize Kafka consumer (after config is loaded)
    initializeConsumer().catch(error => {
      console.error('Failed to initialize Kafka consumer:', error);
    });
    
    const PORT = getConfig('PORT', '3002');
    
    // Initialize Socket.IO for real-time admin updates
    initializeSocket(server);
    
    server.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════════╗
║   👥 USER SERVICE STARTED 👥               ║
║   Port: ${PORT}                             ║
║   Socket.IO: /user-socket                  ║
║   Environment: ${getConfig('NODE_ENV')}    ║
╚════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('❌ Failed to start service:', error);
    process.exit(1);
  }
};

startServer();
