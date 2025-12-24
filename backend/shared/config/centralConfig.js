/**
 * Centralized Configuration (Legacy - File-based)
 * 
 * This module is kept for backward compatibility.
 * New services should use consulConfig.js with bootstrap().
 */

const configStore = new Map();
let initialized = false;

/**
 * Initialize configuration (legacy)
 */
export const initConfig = async (serviceName) => {
  console.log(`⚠️  initConfig is deprecated. Use bootstrap('${serviceName}') instead.`);
  initialized = true;
  return true;
};

/**
 * Get configuration value
 */
export const getConfig = (key, defaultValue) => {
  if (configStore.has(key)) {
    return configStore.get(key);
  }
  return process.env[key] || defaultValue;
};

/**
 * Set configuration value
 */
export const setConfig = (key, value) => {
  configStore.set(key, value);
};

/**
 * Set service-specific config
 */
export const setServiceConfig = (serviceName, config) => {
  Object.entries(config).forEach(([key, value]) => {
    configStore.set(key, value);
  });
};

/**
 * Get all configurations
 */
export const getAllConfigs = () => {
  return Object.fromEntries(configStore);
};

/**
 * Check if config is initialized
 */
export const isConfigInitialized = () => initialized;

/**
 * Refresh configuration
 */
export const refreshConfig = async () => {
  console.log('⚠️  refreshConfig is deprecated. Config is loaded from Consul at startup.');
  return true;
};

export default {
  initConfig,
  getConfig,
  setConfig,
  setServiceConfig,
  getAllConfigs,
  isConfigInitialized,
  refreshConfig
};
