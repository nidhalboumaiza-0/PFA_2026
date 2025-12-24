/**
 * Consul-based Service Discovery for API Gateway
 * 
 * This module discovers microservice URLs dynamically from Consul
 * instead of using hardcoded URLs. It caches service instances and
 * provides load balancing across multiple instances.
 */

import { getConfig, discoverService } from '../../../shared/index.js';

// Service cache with TTL
const serviceCache = new Map();
const CACHE_TTL = 10000; // 10 seconds

// Round-robin indexes for load balancing
const rrIndexes = new Map();

// Consul connection info (loaded from config)
let CONSUL_HOST = 'localhost';
let CONSUL_PORT = '8500';

/**
 * Initialize Consul connection info from config
 * Must be called after bootstrap()
 */
export const initializeConsulConfig = () => {
  CONSUL_HOST = getConfig('CONSUL_HOST', process.env.CONSUL_HOST || 'localhost');
  CONSUL_PORT = getConfig('CONSUL_PORT', process.env.CONSUL_PORT || '8500');
};

const getConsulUrl = () => `http://${CONSUL_HOST}:${CONSUL_PORT}`;

/**
 * Make HTTP request to Consul API
 */
const consulFetch = async (path, options = {}) => {
  const url = `${getConsulUrl()}${path}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    }
  });
  return response;
};

/**
 * Service configuration mapping
 * Maps route paths to Consul service names
 * Fallback URLs use localhost for local dev
 */
export const serviceConfig = {
  auth: {
    serviceName: 'auth-service',
    path: '/api/v1/auth',
    public: true,
    fallbackUrl: 'http://127.0.0.1:3001'
  },
  users: {
    serviceName: 'user-service',
    path: '/api/v1/users',
    public: false,
    fallbackUrl: 'http://127.0.0.1:3002'
  },
  appointments: {
    serviceName: 'rdv-service',
    path: '/api/v1/appointments',
    public: false,
    fallbackUrl: 'http://127.0.0.1:3003'
  },
  medical: {
    serviceName: 'medical-records-service',
    path: '/api/v1/medical',
    public: false,
    fallbackUrl: 'http://127.0.0.1:3004'
  },
  referrals: {
    serviceName: 'referral-service',
    path: '/api/v1/referrals',
    public: false,
    fallbackUrl: 'http://127.0.0.1:3005'
  },
  messages: {
    serviceName: 'messaging-service',
    path: '/api/v1/messages',
    public: false,
    fallbackUrl: 'http://127.0.0.1:3006'
  },
  notifications: {
    serviceName: 'notification-service',
    path: '/api/v1/notifications',
    public: false,
    fallbackUrl: 'http://127.0.0.1:3007'
  },
  audit: {
    serviceName: 'audit-service',
    path: '/api/v1/audit',
    public: false,
    adminOnly: true,
    fallbackUrl: 'http://127.0.0.1:3008'
  }
};

/**
 * Discover healthy instances of a service from Consul
 */
const discoverFromConsul = async (serviceName) => {
  try {
    const response = await consulFetch(`/v1/health/service/${serviceName}?passing=true`);
    
    if (!response.ok) {
      throw new Error(`Consul discovery failed: ${response.status}`);
    }
    
    const services = await response.json();
    
    return services.map(entry => ({
      id: entry.Service.ID,
      address: entry.Service.Address,
      port: entry.Service.Port,
      url: `http://${entry.Service.Address}:${entry.Service.Port}`
    }));
  } catch (error) {
    console.error(`❌ Consul discovery failed for ${serviceName}:`, error.message);
    return [];
  }
};

/**
 * Get cached service instances or fetch from Consul
 */
const getCachedInstances = async (serviceName) => {
  const cached = serviceCache.get(serviceName);
  
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.instances;
  }
  
  const instances = await discoverFromConsul(serviceName);
  
  if (instances.length > 0) {
    serviceCache.set(serviceName, {
      instances,
      timestamp: Date.now()
    });
  }
  
  return instances;
};

/**
 * Get a service URL using round-robin load balancing
 * Falls back to static URL if Consul is unavailable
 */
export const getServiceUrl = async (serviceKey) => {
  const config = serviceConfig[serviceKey];
  
  if (!config) {
    throw new Error(`Unknown service: ${serviceKey}`);
  }
  
  const instances = await getCachedInstances(config.serviceName);
  
  if (instances.length === 0) {
    console.log(`⚠️ No Consul instances for ${config.serviceName}, using fallback`);
    return config.fallbackUrl;
  }
  
  // Round-robin selection
  const currentIndex = rrIndexes.get(config.serviceName) || 0;
  const instance = instances[currentIndex % instances.length];
  rrIndexes.set(config.serviceName, currentIndex + 1);
  
  return instance.url;
};

/**
 * Get all services with their current URLs (for display/debugging)
 */
export const getAllServiceUrls = async () => {
  const result = {};
  
  for (const [key, config] of Object.entries(serviceConfig)) {
    const url = await getServiceUrl(key);
    result[key] = {
      ...config,
      currentUrl: url
    };
  }
  
  return result;
};

/**
 * Check if Consul is available
 */
export const isConsulAvailable = async () => {
  try {
    const response = await consulFetch('/v1/agent/self');
    return response.ok;
  } catch {
    return false;
  }
};

/**
 * Register the API Gateway itself with Consul
 */
export const registerGateway = async (port) => {
  const os = await import('os');
  
  const getLocalIP = () => {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
      for (const iface of interfaces[name]) {
        if (iface.family === 'IPv4' && !iface.internal) {
          return iface.address;
        }
      }
    }
    return '127.0.0.1';
  };
  
  // In Docker, use the service name; locally use the IP
  const address = process.env.SERVICE_HOST || getLocalIP();
  const serviceId = `api-gateway-${address}-${port}`;
  
  const registration = {
    ID: serviceId,
    Name: 'api-gateway',
    Address: address,
    Port: parseInt(port),
    Tags: ['esante', 'gateway', 'proxy'],
    Check: {
      HTTP: `http://${address}:${port}/health`,
      Interval: '10s',
      Timeout: '5s'
    }
  };
  
  try {
    const response = await consulFetch('/v1/agent/service/register', {
      method: 'PUT',
      body: JSON.stringify(registration)
    });
    
    if (response.ok) {
      console.log(`✅ API Gateway registered with Consul: ${serviceId}`);
      
      // Deregister on shutdown
      const deregister = async () => {
        try {
          await consulFetch(`/v1/agent/service/deregister/${serviceId}`, {
            method: 'PUT'
          });
          console.log(`👋 API Gateway deregistered from Consul`);
        } catch (e) {
          console.error('Deregister error:', e.message);
        }
        process.exit(0);
      };
      
      process.on('SIGTERM', deregister);
      process.on('SIGINT', deregister);
      
      return serviceId;
    } else {
      throw new Error(`Registration failed: ${response.status}`);
    }
  } catch (error) {
    console.warn(`⚠️ Could not register with Consul: ${error.message}`);
    return null;
  }
};

// For backward compatibility - export static config as default
const getStaticServices = () => {
  const result = {};
  for (const [key, config] of Object.entries(serviceConfig)) {
    result[key] = {
      url: config.fallbackUrl,
      path: config.path,
      public: config.public,
      adminOnly: config.adminOnly
    };
  }
  return result;
};

export default getStaticServices();
