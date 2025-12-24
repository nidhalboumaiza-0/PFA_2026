import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import {
  connectDB,
  errorHandler,
  requestLogger,
  kafkaProducer,
  bootstrap,
  getConfig,
  getMongoUri
} from '../../../shared/index.js';
import medicalRoutes from './routes/medicalRoutes.js';
import { startAutoLockScheduler } from './jobs/prescriptionLockJob.js';
import morgan from 'morgan';
import { initializeS3 } from './services/s3DocumentService.js';

const app = express();
const SERVICE_NAME = 'medical-records-service';

// ============================
// MIDDLEWARE
// ============================
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);
app.use(morgan('dev'));

// ============================
// ROUTES
// ============================
app.get('/health', (req, res) => {
  res.status(200).json({
    service: 'Medical Records Service',
    status: 'UP',
    timestamp: new Date().toISOString()
  });
});

app.use('/api/v1/medical', medicalRoutes);

// ============================
// ERROR HANDLING
// ============================
app.use(errorHandler);

// ============================
// SERVER INITIALIZATION
// ============================
const startServer = async () => {
  try {
    // Bootstrap: Load config from Consul + Register service
    await bootstrap(SERVICE_NAME);
    
    // Initialize S3 client with config from Consul
    initializeS3();
    
    // Connect to MongoDB using Consul config
    await connectDB(getMongoUri());
    console.log('✅ MongoDB connected successfully');

    // Initialize Kafka Producer
    await kafkaProducer.connect();
    console.log('✅ Kafka Producer connected successfully');

    // Start auto-lock scheduler for prescriptions
    startAutoLockScheduler();

    // Start Express server
    const PORT = getConfig('PORT', 3004);
    app.listen(PORT, () => {
      console.log(`✅ Medical Records Service running on port ${PORT}`);
    });
  } catch (error) {
    console.error('❌ Failed to start Medical Records Service:', error);
    process.exit(1);
  }
};

// Note: Graceful shutdown (deregisterService) is handled by bootstrap()

startServer();
