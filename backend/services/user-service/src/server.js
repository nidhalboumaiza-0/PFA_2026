import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { connectDB, errorHandler, requestLogger, bootstrap, getConfig, getMongoUri } from '../../../shared/index.js';
import userRoutes from './routes/userRoutes.js';
import { initializeConsumer } from './consumers/userConsumer.js';
import { initializeS3 } from './services/s3Service.js';

const app = express();
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
    
    app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════╗
║   👥 USER SERVICE STARTED 👥           ║
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

startServer();
