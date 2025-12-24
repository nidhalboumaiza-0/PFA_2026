import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { connectDB, errorHandler, requestLogger, kafkaProducer, bootstrap, getConfig, getMongoUri } from '../../../shared/index.js';
import referralRoutes from './routes/referralRoutes.js';

const app = express();
const SERVICE_NAME = 'referral-service';

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
    service: 'Referral Service',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Routes
app.use('/api/v1/referrals', referralRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    message: 'Route not found'
  });
});

// Error handler
app.use(errorHandler);

// Start server with Consul bootstrap
const startServer = async () => {
  try {
    // Bootstrap: Load config from Consul + register service
    await bootstrap(SERVICE_NAME);
    
    // Connect to MongoDB using config from Consul
    const mongoUri = getMongoUri('esante_referral');
    await connectDB(mongoUri);

    // Connect to Kafka (after config is loaded)
    await kafkaProducer.connect();
    console.log('✅ Kafka Producer connected');

    const PORT = getConfig('PORT', '3005');

    app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════╗
║   🔗 REFERRAL SERVICE STARTED 🔗       ║
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
