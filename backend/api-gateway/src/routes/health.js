import express from 'express';
import axios from 'axios';
import services from '../config/services.js';

const router = express.Router();

/**
 * Gateway health check
 */
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    service: 'API Gateway',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

/**
 * Check all services health
 */
router.get('/health/services', async (req, res) => {
  const servicesHealth = {};

  for (const [name, config] of Object.entries(services)) {
    try {
      const response = await axios.get(`${config.url}/health`, {
        timeout: 5000
      });
      servicesHealth[name] = {
        status: 'healthy',
        url: config.url,
        responseTime: response.headers['x-response-time'] || 'N/A'
      };
    } catch (error) {
      servicesHealth[name] = {
        status: 'unhealthy',
        url: config.url,
        error: error.message
      };
    }
  }

  const allHealthy = Object.values(servicesHealth).every(
    service => service.status === 'healthy'
  );

  res.status(allHealthy ? 200 : 503).json({
    success: allHealthy,
    services: servicesHealth,
    timestamp: new Date().toISOString()
  });
});

export default router;
