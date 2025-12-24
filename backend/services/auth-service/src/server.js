import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { connectDB, errorHandler, requestLogger, bootstrap, getConfig, getMongoUri } from '../../../shared/index.js';
import authRoutes from './routes/authRoutes.js';

const SERVICE_NAME = 'auth-service';

const app = express();

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
    service: 'Auth Service',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Routes
app.use('/api/v1/auth', authRoutes);

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
    
    // Connect to MongoDB using config from Consul
    const mongoUri = getMongoUri('esante_auth');
    console.log('🔗 MongoDB URI:', mongoUri.replace(/\/\/.*:.*@/, '//<credentials>@'));
    await connectDB(mongoUri);
    
    const PORT = getConfig('PORT', '3001');
    
    app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════╗
║   🔐 AUTH SERVICE STARTED 🔐           ║
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
