/**
 * Consul Service Registry Client
 * 
 * This module provides service registration and discovery functionality
 * using HashiCorp Consul HTTP API directly. It allows microservices to:
 * 1. Register themselves with Consul on startup
 * 2. Deregister on shutdown
 * 3. Discover other services dynamically
 * 4. Health check integration
 * 
 * Note: Kafka is still used for inter-service async communication (events).
 * Consul is used for service discovery (finding service URLs).
 */

import os from 'os';

// Consul configuration
const CONSUL_HOST = process.env.CONSUL_HOST || 'localhost';
const CONSUL_PORT = process.env.CONSUL_PORT || '8500';
const CONSUL_URL = `http://${CONSUL_HOST}:${CONSUL_PORT}`;

let registeredServiceId = null;

/**
 * Make HTTP request to Consul API
 */
const consulFetch = async (path, options = {}) => {
  const url = `${CONSUL_URL}${path}`;
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
 * Get the local IP address for service registration
 */
const getLocalIP = () => {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Skip internal and non-IPv4 addresses
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
};

/**
 * Register a service with Consul
 * 
 * @param {Object} options - Service registration options
 * @param {string} options.name - Service name (e.g., 'auth-service')
 * @param {number} options.port - Service port
 * @param {string[]} options.tags - Service tags for filtering
 * @param {Object} options.meta - Additional metadata
 * @returns {Promise<string>} - The registered service ID
 */
export const registerService = async ({
  name,
  port,
  tags = [],
  meta = {}
}) => {
  const address = process.env.SERVICE_HOST || getLocalIP();
  const serviceId = `${name}-${address}-${port}`;
  
  const registration = {
    ID: serviceId,
    Name: name,
    Address: address,
    Port: parseInt(port),
    Tags: ['esante', 'microservice', ...tags],
    Meta: {
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      ...meta
    },
    Check: {
      HTTP: `http://${address}:${port}/health`,
      Interval: '10s',
      Timeout: '5s',
      DeregisterCriticalServiceAfter: '1m'
    }
  };

  try {
    const response = await consulFetch('/v1/agent/service/register', {
      method: 'PUT',
      body: JSON.stringify(registration)
    });
    
    if (response.ok) {
      registeredServiceId = serviceId;
      console.log(`✅ Registered with Consul: ${name} (${serviceId})`);
      console.log(`   Address: ${address}:${port}`);
      
      // Setup graceful deregistration on shutdown
      setupGracefulShutdown(serviceId);
      
      return serviceId;
    } else {
      throw new Error(`Consul registration failed: ${response.status}`);
    }
  } catch (error) {
    console.error(`❌ Failed to register with Consul: ${error.message}`);
    // Don't throw - allow service to run without Consul in dev mode
    if (process.env.NODE_ENV === 'production') {
      throw error;
    }
    return null;
  }
};

/**
 * Deregister a service from Consul
 * 
 * @param {string} serviceId - The service ID to deregister
 */
export const deregisterService = async (serviceId = registeredServiceId) => {
  if (!serviceId) return;
  
  try {
    const response = await consulFetch(`/v1/agent/service/deregister/${serviceId}`, {
      method: 'PUT'
    });
    
    if (response.ok) {
      console.log(`👋 Deregistered from Consul: ${serviceId}`);
      registeredServiceId = null;
    }
  } catch (error) {
    console.error(`❌ Failed to deregister from Consul: ${error.message}`);
  }
};

/**
 * Discover healthy instances of a service
 * 
 * @param {string} serviceName - The name of the service to find
 * @returns {Promise<Array>} - Array of healthy service instances
 */
export const discoverService = async (serviceName) => {
  try {
    const response = await consulFetch(`/v1/health/service/${serviceName}?passing=true`);
    
    if (!response.ok) {
      throw new Error(`Consul discovery failed: ${response.status}`);
    }
    
    const services = await response.json();
    
    return services.map(entry => ({
      id: entry.Service.ID,
      name: entry.Service.Service,
      address: entry.Service.Address,
      port: entry.Service.Port,
      tags: entry.Service.Tags,
      meta: entry.Service.Meta,
      url: `http://${entry.Service.Address}:${entry.Service.Port}`
    }));
  } catch (error) {
    console.error(`❌ Failed to discover service ${serviceName}: ${error.message}`);
    return [];
  }
};

/**
 * Get a single healthy instance URL for a service (load balancing)
 * Uses round-robin selection
 * 
 * @param {string} serviceName - The name of the service
 * @returns {Promise<string|null>} - Service URL or null if not found
 */
const serviceIndexes = new Map();

export const getServiceUrl = async (serviceName) => {
  const instances = await discoverService(serviceName);
  
  if (instances.length === 0) {
    console.warn(`⚠️ No healthy instances found for: ${serviceName}`);
    return null;
  }
  
  // Round-robin load balancing
  const currentIndex = serviceIndexes.get(serviceName) || 0;
  const instance = instances[currentIndex % instances.length];
  serviceIndexes.set(serviceName, currentIndex + 1);
  
  return instance.url;
};

/**
 * Get all registered services
 * 
 * @returns {Promise<Object>} - Map of all services
 */
export const getAllServices = async () => {
  try {
    const response = await consulFetch('/v1/agent/services');
    
    if (!response.ok) {
      throw new Error(`Failed to get services: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error(`❌ Failed to get services: ${error.message}`);
    return {};
  }
};

/**
 * Watch for changes in a service (polling-based)
 * 
 * @param {string} serviceName - Service to watch
 * @param {Function} callback - Called when service instances change
 * @param {number} interval - Polling interval in ms (default 5000)
 * @returns {Object} - Object with stop() method to stop watching
 */
export const watchService = (serviceName, callback, interval = 5000) => {
  let lastInstances = null;
  
  const poll = async () => {
    const instances = await discoverService(serviceName);
    const instancesJson = JSON.stringify(instances);
    
    if (lastInstances !== instancesJson) {
      lastInstances = instancesJson;
      callback(instances);
    }
  };
  
  const intervalId = setInterval(poll, interval);
  poll(); // Initial poll
  
  return {
    stop: () => clearInterval(intervalId)
  };
};

/**
 * Setup graceful shutdown handlers
 */
const setupGracefulShutdown = (serviceId) => {
  const shutdown = async (signal) => {
    console.log(`\n${signal} received, deregistering from Consul...`);
    await deregisterService(serviceId);
    process.exit(0);
  };
  
  // Only add handlers once
  if (!process.listenerCount('SIGTERM')) {
    process.on('SIGTERM', () => shutdown('SIGTERM'));
  }
  if (!process.listenerCount('SIGINT')) {
    process.on('SIGINT', () => shutdown('SIGINT'));
  }
};

/**
 * Health check helper - checks if Consul is reachable
 */
export const isConsulHealthy = async () => {
  try {
    const response = await consulFetch('/v1/agent/self');
    return response.ok;
  } catch (error) {
    return false;
  }
};

// Service name constants for easy reference
export const SERVICE_NAMES = {
  AUTH: 'auth-service',
  USER: 'user-service',
  RDV: 'rdv-service',
  MEDICAL_RECORDS: 'medical-records-service',
  REFERRAL: 'referral-service',
  MESSAGING: 'messaging-service',
  NOTIFICATION: 'notification-service',
  AUDIT: 'audit-service',
  API_GATEWAY: 'api-gateway'
};

export default {
  registerService,
  deregisterService,
  discoverService,
  getServiceUrl,
  getAllServices,
  watchService,
  isConsulHealthy,
  SERVICE_NAMES
};
