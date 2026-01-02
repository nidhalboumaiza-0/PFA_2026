import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import {
  connectDB,
  errorHandler,
  requestLogger,
  kafkaProducer,
  bootstrap,
  getConfig,
  getMongoUri
} from '../../../shared/index.js';
import appointmentRoutes from './routes/appointmentRoutes.js';
import reviewRoutes from './routes/reviewRoutes.js';

const app = express();
const SERVICE_NAME = 'rdv-service';

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
    service: 'RDV Service',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

app.use('/api/v1/appointments', appointmentRoutes);
app.use('/api/v1/reviews', reviewRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    message: 'Route not found'
  });
});

// ============================
// ERROR HANDLING
// ============================
app.use(errorHandler);

// ============================
// SERVER INITIALIZATION
// ============================
const startServer = async () => {
  try {
    // Bootstrap: Load config from Consul + register service
    await bootstrap(SERVICE_NAME);
    
    // Connect to MongoDB using config from Consul
    const mongoUri = getMongoUri('esante_rdv');
    await connectDB(mongoUri);

    // Initialize Kafka Producer (after config is loaded)
    await kafkaProducer.connect();
    console.log('✅ Kafka Producer connected');

    const PORT = getConfig('PORT', '3003');

    app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════╗
║   📅 RDV SERVICE STARTED 📅            ║
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
