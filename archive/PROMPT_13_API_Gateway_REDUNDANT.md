# PROMPT 13: API Gateway & Final Integration

## Objective
Build the API Gateway as the central entry point for all microservices, handle routing, authentication, rate limiting, and integrate all services for end-to-end functionality.

## Requirements

### 1. API Gateway Architecture

```
Client Apps (Flutter, Next.js)
            ↓
      API Gateway :3000
            ↓
    ┌──────┴──────┬──────────┬──────────┬──────────┐
    ↓             ↓          ↓          ↓          ↓
Auth:3001    Users:3002   RDV:3003   Medical:3004  ...
```

### 2. Gateway Setup

#### Package.json
```json
{
  "name": "api-gateway",
  "version": "1.0.0",
  "scripts": {
    "dev": "nodemon src/index.js",
    "start": "node src/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "http-proxy-middleware": "^2.0.6",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.10.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "jsonwebtoken": "^9.0.2",
    "redis": "^4.6.7"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

#### Main Gateway File
```javascript
// api-gateway/src/index.js

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { createProxyMiddleware } = require('http-proxy-middleware');

const authMiddleware = require('./middleware/auth.middleware');
const rateLimitMiddleware = require('./middleware/rateLimit.middleware');
const errorHandler = require('./middleware/error.middleware');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Security & Logging
app.use(helmet());
app.use(cors({
  origin: [
    process.env.FRONTEND_URL,
    process.env.ADMIN_URL
  ],
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate Limiting
app.use(rateLimitMiddleware);

// Health Check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API Routes
app.use('/api/v1', routes);

// Error Handler
app.use(errorHandler);

// Start Server
app.listen(PORT, () => {
  console.log(`🚀 API Gateway running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
});

// Graceful Shutdown
process.on('SIGINT', () => {
  console.log('\n⚠️ Shutting down gracefully...');
  process.exit(0);
});
```

### 3. Service Configuration

```javascript
// api-gateway/src/config/services.js

const SERVICES = {
  AUTH: {
    name: 'auth-service',
    url: process.env.AUTH_SERVICE_URL || 'http://localhost:3001',
    pathPrefix: '/auth'
  },
  USERS: {
    name: 'user-service',
    url: process.env.USER_SERVICE_URL || 'http://localhost:3002',
    pathPrefix: '/users'
  },
  APPOINTMENTS: {
    name: 'rdv-service',
    url: process.env.RDV_SERVICE_URL || 'http://localhost:3003',
    pathPrefix: '/appointments'
  },
  MEDICAL: {
    name: 'medical-records-service',
    url: process.env.MEDICAL_SERVICE_URL || 'http://localhost:3004',
    pathPrefix: '/medical'
  },
  REFERRALS: {
    name: 'referral-service',
    url: process.env.REFERRAL_SERVICE_URL || 'http://localhost:3005',
    pathPrefix: '/referrals'
  },
  MESSAGES: {
    name: 'messaging-service',
    url: process.env.MESSAGING_SERVICE_URL || 'http://localhost:3006',
    pathPrefix: '/messages'
  },
  NOTIFICATIONS: {
    name: 'notification-service',
    url: process.env.NOTIFICATION_SERVICE_URL || 'http://localhost:3007',
    pathPrefix: '/notifications'
  },
  AUDIT: {
    name: 'audit-service',
    url: process.env.AUDIT_SERVICE_URL || 'http://localhost:3008',
    pathPrefix: '/audit'
  }
};

module.exports = SERVICES;
```

### 4. Routing Configuration

```javascript
// api-gateway/src/routes/index.js

const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const authMiddleware = require('../middleware/auth.middleware');
const SERVICES = require('../config/services');

const router = express.Router();

// Proxy Options
const createProxyOptions = (target, pathRewrite) => ({
  target,
  changeOrigin: true,
  pathRewrite: pathRewrite || {},
  onProxyReq: (proxyReq, req) => {
    // Forward user info to microservices
    if (req.user) {
      proxyReq.setHeader('X-User-Id', req.user.userId);
      proxyReq.setHeader('X-User-Role', req.user.role);
      proxyReq.setHeader('X-User-Email', req.user.email);
    }
  },
  onError: (err, req, res) => {
    console.error('Proxy Error:', err);
    res.status(502).json({
      success: false,
      error: 'Service temporarily unavailable'
    });
  }
});

// AUTH SERVICE (Public routes - no auth required)
router.use('/auth', createProxyMiddleware(
  createProxyOptions(SERVICES.AUTH.url, {
    [`^${SERVICES.AUTH.pathPrefix}`]: ''
  })
));

// USERS SERVICE (Protected)
router.use('/users', 
  authMiddleware.authenticate,
  createProxyMiddleware(
    createProxyOptions(SERVICES.USERS.url, {
      [`^${SERVICES.USERS.pathPrefix}`]: ''
    })
  )
);

// APPOINTMENTS SERVICE (Protected)
router.use('/appointments',
  authMiddleware.authenticate,
  createProxyMiddleware(
    createProxyOptions(SERVICES.APPOINTMENTS.url, {
      [`^${SERVICES.APPOINTMENTS.pathPrefix}`]: ''
    })
  )
);

// MEDICAL RECORDS SERVICE (Protected)
router.use('/medical',
  authMiddleware.authenticate,
  createProxyMiddleware(
    createProxyOptions(SERVICES.MEDICAL.url, {
      [`^${SERVICES.MEDICAL.pathPrefix}`]: ''
    })
  )
);

// REFERRALS SERVICE (Protected, Doctors only for some routes)
router.use('/referrals',
  authMiddleware.authenticate,
  createProxyMiddleware(
    createProxyOptions(SERVICES.REFERRALS.url, {
      [`^${SERVICES.REFERRALS.pathPrefix}`]: ''
    })
  )
);

// MESSAGES SERVICE (Protected)
router.use('/messages',
  authMiddleware.authenticate,
  createProxyMiddleware(
    createProxyOptions(SERVICES.MESSAGES.url, {
      [`^${SERVICES.MESSAGES.pathPrefix}`]: ''
    })
  )
);

// NOTIFICATIONS SERVICE (Protected)
router.use('/notifications',
  authMiddleware.authenticate,
  createProxyMiddleware(
    createProxyOptions(SERVICES.NOTIFICATIONS.url, {
      [`^${SERVICES.NOTIFICATIONS.pathPrefix}`]: ''
    })
  )
);

// AUDIT SERVICE (Protected, Admin only)
router.use('/audit',
  authMiddleware.authenticate,
  authMiddleware.authorize(['admin']),
  createProxyMiddleware(
    createProxyOptions(SERVICES.AUDIT.url, {
      [`^${SERVICES.AUDIT.pathPrefix}`]: ''
    })
  )
);

module.exports = router;
```

### 5. Authentication Middleware

```javascript
// api-gateway/src/middleware/auth.middleware.js

const jwt = require('jsonwebtoken');

class AuthMiddleware {
  authenticate(req, res, next) {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
          success: false,
          error: 'No token provided'
        });
      }
      
      const token = authHeader.substring(7);
      
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Attach user info to request
        req.user = {
          userId: decoded.userId,
          email: decoded.email,
          role: decoded.role,
          profileId: decoded.profileId
        };
        
        next();
      } catch (jwtError) {
        return res.status(401).json({
          success: false,
          error: 'Invalid or expired token'
        });
      }
    } catch (error) {
      return res.status(500).json({
        success: false,
        error: 'Authentication error'
      });
    }
  }

  authorize(allowedRoles) {
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Unauthorized'
        });
      }
      
      if (!allowedRoles.includes(req.user.role)) {
        return res.status(403).json({
          success: false,
          error: 'Insufficient permissions'
        });
      }
      
      next();
    };
  }
}

module.exports = new AuthMiddleware();
```

### 6. Rate Limiting Middleware

```javascript
// api-gateway/src/middleware/rateLimit.middleware.js

const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const redis = require('redis');

// Redis client for distributed rate limiting
const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.connect().catch(console.error);

// General rate limiter
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: {
    success: false,
    error: 'Too many requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Use Redis store for distributed rate limiting
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:general:'
  })
});

// Auth endpoints stricter rate limiting
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 attempts per 15 minutes
  skipSuccessfulRequests: true,
  message: {
    success: false,
    error: 'Too many login attempts, please try again later'
  },
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:auth:'
  })
});

// Apply rate limiting based on route
function rateLimitMiddleware(req, res, next) {
  if (req.path.startsWith('/api/v1/auth/login') || 
      req.path.startsWith('/api/v1/auth/register')) {
    return authLimiter(req, res, next);
  }
  
  return generalLimiter(req, res, next);
}

module.exports = rateLimitMiddleware;
```

### 7. Error Handling Middleware

```javascript
// api-gateway/src/middleware/error.middleware.js

function errorHandler(err, req, res, next) {
  console.error('Gateway Error:', err);
  
  // Handle specific error types
  if (err.name === 'UnauthorizedError') {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized access'
    });
  }
  
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: err.details
    });
  }
  
  // Default error
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
}

module.exports = errorHandler;
```

### 8. Service Health Monitoring

```javascript
// api-gateway/src/utils/healthCheck.js

const axios = require('axios');
const SERVICES = require('../config/services');

async function checkServiceHealth(service) {
  try {
    const response = await axios.get(`${service.url}/health`, {
      timeout: 5000
    });
    return {
      name: service.name,
      status: 'healthy',
      responseTime: response.headers['x-response-time'] || 'N/A'
    };
  } catch (error) {
    return {
      name: service.name,
      status: 'unhealthy',
      error: error.message
    };
  }
}

async function checkAllServices() {
  const healthChecks = Object.values(SERVICES).map(checkServiceHealth);
  const results = await Promise.all(healthChecks);
  
  return {
    gateway: 'healthy',
    services: results,
    timestamp: new Date().toISOString()
  };
}

module.exports = { checkAllServices };
```

#### Health Check Endpoint
```javascript
// Add to api-gateway/src/index.js

const { checkAllServices } = require('./utils/healthCheck');

app.get('/health/services', async (req, res) => {
  const health = await checkAllServices();
  const allHealthy = health.services.every(s => s.status === 'healthy');
  
  res.status(allHealthy ? 200 : 503).json(health);
});
```

### 9. Request Logging

```javascript
// api-gateway/src/middleware/logging.middleware.js

const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

// Create logs directory
const logDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir);
}

// Create write stream
const accessLogStream = fs.createWriteStream(
  path.join(logDir, 'access.log'),
  { flags: 'a' }
);

// Custom format
morgan.token('user-id', (req) => req.user?.userId || 'anonymous');
morgan.token('user-role', (req) => req.user?.role || 'none');

const customFormat = ':remote-addr - :user-id [:user-role] ":method :url" :status :res[content-length] - :response-time ms';

// Morgan middleware
const loggingMiddleware = morgan(customFormat, {
  stream: accessLogStream
});

module.exports = loggingMiddleware;
```

### 10. API Documentation Endpoint

```javascript
// api-gateway/src/routes/docs.js

const express = require('express');
const router = express.Router();

router.get('/api-docs', (req, res) => {
  res.json({
    version: '1.0.0',
    title: 'E-Santé API Gateway',
    description: 'Central API Gateway for E-Santé Platform',
    baseUrl: `${req.protocol}://${req.get('host')}/api/v1`,
    services: {
      auth: {
        basePath: '/auth',
        description: 'Authentication and authorization',
        endpoints: [
          'POST /register',
          'POST /login',
          'POST /refresh-token',
          'POST /forgot-password',
          'POST /reset-password/:token',
          'GET /verify-email/:token'
        ]
      },
      users: {
        basePath: '/users',
        description: 'User profile management',
        requiresAuth: true,
        endpoints: [
          'GET /me',
          'PUT /patient/profile',
          'PUT /doctor/profile',
          'POST /upload-photo',
          'GET /doctors/search',
          'GET /doctors/nearby'
        ]
      },
      appointments: {
        basePath: '/appointments',
        description: 'Appointment management',
        requiresAuth: true,
        endpoints: [
          'POST /request',
          'GET /patient/my-appointments',
          'GET /doctor/my-appointments',
          'PUT /:id/confirm',
          'PUT /:id/reject',
          'PUT /:id/cancel'
        ]
      },
      medical: {
        basePath: '/medical',
        description: 'Medical records, prescriptions, documents',
        requiresAuth: true,
        endpoints: [
          'POST /consultations',
          'GET /consultations/:id',
          'POST /prescriptions',
          'GET /prescriptions/:id',
          'POST /documents/upload',
          'GET /patients/:patientId/timeline'
        ]
      },
      referrals: {
        basePath: '/referrals',
        description: 'Doctor-to-doctor referrals',
        requiresAuth: true,
        endpoints: [
          'POST /',
          'GET /sent',
          'GET /received',
          'POST /:id/book-appointment',
          'PUT /:id/accept',
          'PUT /:id/reject'
        ]
      },
      messages: {
        basePath: '/messages',
        description: 'Real-time messaging',
        requiresAuth: true,
        endpoints: [
          'POST /conversations',
          'GET /conversations',
          'GET /conversations/:id/messages',
          'POST /conversations/:id/send-file'
        ]
      },
      notifications: {
        basePath: '/notifications',
        description: 'Push and email notifications',
        requiresAuth: true,
        endpoints: [
          'GET /',
          'GET /unread-count',
          'PUT /:id/read',
          'PUT /mark-all-read',
          'GET /preferences',
          'PUT /preferences'
        ]
      },
      audit: {
        basePath: '/audit',
        description: 'Activity logging and audit trails',
        requiresAuth: true,
        requiresAdmin: true,
        endpoints: [
          'GET /logs',
          'GET /users/:userId/activity',
          'GET /patients/:patientId/access-log',
          'GET /security-events',
          'GET /statistics'
        ]
      }
    }
  });
});

module.exports = router;
```

### 11. Docker Compose for All Services

```yaml
# docker-compose.yml

version: '3.8'

services:
  # Database
  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password
    networks:
      - esante-network

  # Redis (for rate limiting, caching)
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    networks:
      - esante-network

  # Kafka & Zookeeper
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - esante-network

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    networks:
      - esante-network

  # API Gateway
  api-gateway:
    build: ./api-gateway
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      PORT: 3000
      JWT_SECRET: ${JWT_SECRET}
      REDIS_URL: redis://redis:6379
    depends_on:
      - redis
      - mongodb
      - kafka
    networks:
      - esante-network

  # Auth Service
  auth-service:
    build: ./services/auth-service
    ports:
      - "3001:3001"
    environment:
      NODE_ENV: production
      PORT: 3001
      MONGODB_URI: mongodb://admin:password@mongodb:27017/esante?authSource=admin
      JWT_SECRET: ${JWT_SECRET}
      KAFKA_BROKERS: kafka:9092
    depends_on:
      - mongodb
      - kafka
    networks:
      - esante-network

  # User Service
  user-service:
    build: ./services/user-service
    ports:
      - "3002:3002"
    environment:
      NODE_ENV: production
      PORT: 3002
      MONGODB_URI: mongodb://admin:password@mongodb:27017/esante?authSource=admin
      AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
      AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
      KAFKA_BROKERS: kafka:9092
    depends_on:
      - mongodb
      - kafka
    networks:
      - esante-network

  # ... Add other services similarly

volumes:
  mongo-data:

networks:
  esante-network:
    driver: bridge
```

### 12. Environment Variables Template

```bash
# .env.example

# General
NODE_ENV=development
PORT=3000

# MongoDB
MONGODB_URI=mongodb://localhost:27017/esante

# JWT
JWT_SECRET=your_super_secret_jwt_key_change_in_production
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=your_refresh_secret
JWT_REFRESH_EXPIRE=30d

# Redis
REDIS_URL=redis://localhost:6379

# Kafka
KAFKA_BROKERS=localhost:9092
KAFKA_CLIENT_ID=esante-backend

# Service URLs
AUTH_SERVICE_URL=http://localhost:3001
USER_SERVICE_URL=http://localhost:3002
RDV_SERVICE_URL=http://localhost:3003
MEDICAL_SERVICE_URL=http://localhost:3004
REFERRAL_SERVICE_URL=http://localhost:3005
MESSAGING_SERVICE_URL=http://localhost:3006
NOTIFICATION_SERVICE_URL=http://localhost:3007
AUDIT_SERVICE_URL=http://localhost:3008

# Frontend URLs
FRONTEND_URL=http://localhost:3000
ADMIN_URL=http://localhost:3001

# Email (Nodemailer)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
EMAIL_FROM=noreply@esante.com

# AWS S3
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=esante-medical-documents

# OneSignal
ONESIGNAL_APP_ID=your_app_id
ONESIGNAL_REST_API_KEY=your_api_key

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

### 13. Start Script

```bash
#!/bin/bash
# start-all.sh

echo "🚀 Starting E-Santé Backend Services..."

# Start infrastructure
echo "📦 Starting MongoDB, Redis, Kafka..."
docker-compose up -d mongodb redis zookeeper kafka

sleep 10

# Start services
echo "🔧 Starting microservices..."
cd services/auth-service && npm start &
cd services/user-service && npm start &
cd services/rdv-service && npm start &
cd services/medical-records-service && npm start &
cd services/referral-service && npm start &
cd services/messaging-service && npm start &
cd services/notification-service && npm start &
cd services/audit-service && npm start &

sleep 5

# Start API Gateway
echo "🌐 Starting API Gateway..."
cd api-gateway && npm start

echo "✅ All services started!"
echo "📍 API Gateway: http://localhost:3000"
echo "📍 Health Check: http://localhost:3000/health/services"
```

## Deliverables
1. ✅ API Gateway setup
2. ✅ Service routing configuration
3. ✅ Authentication middleware
4. ✅ Rate limiting
5. ✅ Error handling
6. ✅ Service health monitoring
7. ✅ Request logging
8. ✅ API documentation endpoint
9. ✅ Docker Compose orchestration
10. ✅ Environment configuration
11. ✅ Start scripts
12. ✅ Complete integration

## Testing Checklist
- [ ] API Gateway starts successfully
- [ ] All services accessible through gateway
- [ ] Authentication works across services
- [ ] Rate limiting prevents abuse
- [ ] Health checks report correctly
- [ ] Routing to all services works
- [ ] Error handling consistent
- [ ] Logs captured properly
- [ ] Docker Compose brings up all services
- [ ] End-to-end flows work

---

**🎉 BACKEND COMPLETE!** 
All 13 prompts create a professional, scalable E-Santé backend with microservices architecture.
