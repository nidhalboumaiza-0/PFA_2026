import express from 'express';
import { createServer } from 'http';
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
import adminAppointmentRoutes from './routes/adminAppointmentRoutes.js';
import { initializeS3 } from './services/s3Service.js';
import { initializeSocket } from './socket/index.js';

const app = express();
const server = createServer(app);
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
app.use('/api/v1/appointments/admin', adminAppointmentRoutes);
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
    
    // Initialize S3 client for document uploads
    initializeS3();
    
    // Connect to MongoDB using config from Consul
    const mongoUri = getMongoUri('esante_rdv');
    await connectDB(mongoUri);

    // Initialize Kafka Producer (after config is loaded)
    await kafkaProducer.connect();
    console.log('✅ Kafka Producer connected');

    // Initialize Socket.IO for real-time updates
    initializeSocket(server);

    const PORT = getConfig('PORT', '3003');

    server.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════════╗
║   📅 RDV SERVICE STARTED 📅                ║
║   Port: ${PORT}                             ║
║   Socket.IO: /rdv-socket                   ║
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
