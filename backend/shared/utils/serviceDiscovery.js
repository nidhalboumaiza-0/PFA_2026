/**
 * Service Discovery Module
 * 
 * Provides dynamic service URL resolution using Consul.
 * Services should use these functions instead of hardcoded URLs.
 * 
 * IMPORTANT: This module relies on consulConfig being bootstrapped first.
 * Always call bootstrap() in your service startup before using these functions.
 */

import { getConfig, discoverService } from '../config/consulConfig.js';

// Service URL cache (populated after bootstrap from Consul)
const serviceCache = new Map();

/**
 * Get service URL dynamically from Consul
 * First checks Consul service catalog, then falls back to KV config
 * 
 * @param {string} serviceName - Service name (e.g., 'user-service', 'auth-service')
 * @returns {Promise<string>} - Service base URL (e.g., 'http://user-service:3002')
 */
export async function getServiceUrl(serviceName) {
  // Check cache first
  if (serviceCache.has(serviceName)) {
    return serviceCache.get(serviceName);
  }
  
  // Try Consul service discovery
  const discoveredUrl = await discoverService(serviceName);
  if (discoveredUrl) {
    serviceCache.set(serviceName, discoveredUrl);
    return discoveredUrl;
  }
  
  // Fallback to config-based URL (from Consul KV)
  const configKey = `${serviceName.toUpperCase().replace(/-/g, '_')}_URL`;
  const configUrl = getConfig(configKey);
  if (configUrl) {
    serviceCache.set(serviceName, configUrl);
    return configUrl;
  }
  
  // Last resort: construct from service registry in KV
  const host = getConfig(`esante/services/${serviceName}/host`) || serviceName;
  const port = getConfig(`esante/services/${serviceName}/port`) || getDefaultPort(serviceName);
  const url = `http://${host}:${port}`;
  serviceCache.set(serviceName, url);
  return url;
}

/**
 * Get default port for a service
 */
function getDefaultPort(serviceName) {
  const ports = {
    'api-gateway': '3000',
    'auth-service': '3001',
    'user-service': '3002',
    'rdv-service': '3003',
    'medical-records-service': '3004',
    'referral-service': '3005',
    'messaging-service': '3006',
    'notification-service': '3007',
    'audit-service': '3008'
  };
  return ports[serviceName] || '3000';
}

/**
 * Clear the service cache (useful for reconnection scenarios)
 */
export function clearServiceCache() {
  serviceCache.clear();
}

/**
 * Pre-defined service getters for common use cases
 */
export async function getUserServiceUrl() {
  return getServiceUrl('user-service');
}

export async function getAuthServiceUrl() {
  return getServiceUrl('auth-service');
}

export async function getRdvServiceUrl() {
  return getServiceUrl('rdv-service');
}

export async function getMedicalRecordsServiceUrl() {
  return getServiceUrl('medical-records-service');
}

export async function getReferralServiceUrl() {
  return getServiceUrl('referral-service');
}

export async function getMessagingServiceUrl() {
  return getServiceUrl('messaging-service');
}

export async function getNotificationServiceUrl() {
  return getServiceUrl('notification-service');
}

export async function getAuditServiceUrl() {
  return getServiceUrl('audit-service');
}

export default {
  getServiceUrl,
  clearServiceCache,
  getUserServiceUrl,
  getAuthServiceUrl,
  getRdvServiceUrl,
  getMedicalRecordsServiceUrl,
  getReferralServiceUrl,
  getMessagingServiceUrl,
  getNotificationServiceUrl,
  getAuditServiceUrl
};
