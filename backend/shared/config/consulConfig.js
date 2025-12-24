/**
 * Consul Configuration Module
 * 
 * Provides centralized configuration management using Consul KV store.
 * Services call bootstrap() at startup to load config from Consul.
 */

// In-memory config store (populated by bootstrap)
const configStore = new Map();

// Consul connection info
let CONSUL_HOST = process.env.CONSUL_HOST || 'localhost';
let CONSUL_PORT = process.env.CONSUL_PORT || '8500';

const getConsulUrl = () => `http://${CONSUL_HOST}:${CONSUL_PORT}`;

/**
 * Fetch all keys with a given prefix from Consul
 */
async function fetchKeysWithPrefix(prefix) {
  try {
    const response = await fetch(`${getConsulUrl()}/v1/kv/${prefix}?recurse=true`);
    if (!response.ok) {
      if (response.status === 404) return [];
      throw new Error(`Consul returned ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error(`Failed to fetch keys with prefix ${prefix}:`, error.message);
    return [];
  }
}

/**
 * Decode base64 value from Consul
 */
function decodeValue(base64Value) {
  try {
    return Buffer.from(base64Value, 'base64').toString('utf8');
  } catch {
    return base64Value;
  }
}

/**
 * Load configuration from Consul into memory
 */
async function loadConfigFromConsul(serviceName) {
  console.log(`📡 Loading config from Consul for ${serviceName}...`);
  
  // Load common config (esante/common/)
  const commonKeys = await fetchKeysWithPrefix('esante/common/');
  let commonCount = 0;
  for (const item of commonKeys) {
    const key = item.Key.replace('esante/common/', '');
    const value = decodeValue(item.Value);
    configStore.set(key, value);
    process.env[key] = value; // Also set in process.env for compatibility
    commonCount++;
  }
  console.log(`   ✓ Common: ${commonCount} keys`);
  
  // Load service-specific config (esante/{serviceName}/)
  const serviceKeys = await fetchKeysWithPrefix(`esante/${serviceName}/`);
  let serviceCount = 0;
  for (const item of serviceKeys) {
    const key = item.Key.replace(`esante/${serviceName}/`, '');
    const value = decodeValue(item.Value);
    configStore.set(key, value);
    process.env[key] = value;
    serviceCount++;
  }
  console.log(`   ✓ Service: ${serviceCount} keys`);
  
  // Load service registry for discovery (esante/services/)
  const registryKeys = await fetchKeysWithPrefix('esante/services/');
  let registryCount = 0;
  for (const item of registryKeys) {
    const key = item.Key;
    const value = decodeValue(item.Value);
    configStore.set(key, value);
    registryCount++;
  }
  console.log(`   ✓ Registry: ${registryCount} keys`);
  
  console.log(`   ✓ Total config: ${configStore.size} keys`);
  return configStore.size;
}

/**
 * Register service with Consul service catalog
 */
async function registerWithConsul(serviceName, port) {
  try {
    const hostname = process.env.HOSTNAME || serviceName;
    const serviceId = `${serviceName}-${hostname}-${port}`;
    
    const registration = {
      ID: serviceId,
      Name: serviceName,
      Address: hostname,
      Port: parseInt(port),
      Tags: ['esante', process.env.NODE_ENV || 'development'],
      Check: {
        HTTP: `http://${hostname}:${port}/health`,
        Interval: '10s',
        Timeout: '5s',
        DeregisterCriticalServiceAfter: '1m'
      }
    };
    
    const response = await fetch(`${getConsulUrl()}/v1/agent/service/register`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(registration)
    });
    
    if (response.ok) {
      console.log(`✅ Registered in Consul: ${serviceName} @ ${hostname}:${port}`);
      return serviceId;
    } else {
      console.error(`❌ Failed to register with Consul: ${response.status}`);
      return null;
    }
  } catch (error) {
    console.error(`❌ Consul registration error: ${error.message}`);
    return null;
  }
}

/**
 * Deregister service from Consul
 */
async function deregisterFromConsul(serviceId) {
  if (!serviceId) return;
  
  try {
    await fetch(`${getConsulUrl()}/v1/agent/service/deregister/${serviceId}`, {
      method: 'PUT'
    });
    console.log(`👋 Deregistered from Consul: ${serviceId}`);
  } catch (error) {
    console.error(`Failed to deregister: ${error.message}`);
  }
}

/**
 * Bootstrap service - load config and register with Consul
 * Call this at service startup before using any config
 */
export async function bootstrap(serviceName) {
  console.log(`\n🚀 Bootstrapping ${serviceName}...`);
  console.log('='.repeat(50));
  
  // Update Consul host from environment (for Docker)
  CONSUL_HOST = process.env.CONSUL_HOST || 'localhost';
  CONSUL_PORT = process.env.CONSUL_PORT || '8500';
  
  // Load configuration
  const keyCount = await loadConfigFromConsul(serviceName);
  
  if (keyCount === 0) {
    console.warn('⚠️  No config loaded from Consul, using environment variables');
  }
  
  // Register with Consul
  const port = getConfig('PORT', '3000');
  const serviceId = await registerWithConsul(serviceName, port);
  
  // Setup graceful shutdown
  const shutdown = async () => {
    console.log('\n🛑 Shutting down...');
    await deregisterFromConsul(serviceId);
    process.exit(0);
  };
  
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
  
  console.log('='.repeat(50));
  console.log(`✅ ${serviceName} bootstrapped successfully!\n`);
  
  return { serviceId, keyCount };
}

/**
 * Get configuration value
 * First checks in-memory store, then falls back to process.env
 */
export function getConfig(key, defaultValue = undefined) {
  // Check in-memory config store first
  if (configStore.has(key)) {
    return configStore.get(key);
  }
  
  // Fall back to environment variable
  if (process.env[key] !== undefined) {
    return process.env[key];
  }
  
  return defaultValue;
}

/**
 * Build MongoDB URI from config
 */
export function getMongoUri(dbName) {
  const host = getConfig('MONGO_HOST', 'localhost');
  const port = getConfig('MONGO_PORT', '27017');
  const user = getConfig('MONGO_USER', '');
  const password = getConfig('MONGO_PASSWORD', '');
  const database = dbName || getConfig('MONGO_DB_NAME', 'esante');
  
  console.log(`🔧 MongoDB Config: host=${host}, port=${port}, user=${user ? 'set' : 'empty'}, password=${password ? 'set' : 'empty'}, db=${database}`);
  
  if (user && password) {
    return `mongodb://${user}:${password}@${host}:${port}/${database}?authSource=admin`;
  }
  return `mongodb://${host}:${port}/${database}`;
}

/**
 * Discover service URL from Consul
 */
export async function discoverService(serviceName) {
  try {
    // First try from cached registry
    const host = configStore.get(`esante/services/${serviceName}/host`);
    const port = configStore.get(`esante/services/${serviceName}/port`);
    if (host && port) {
      return `http://${host}:${port}`;
    }
    
    // Query Consul catalog
    const response = await fetch(
      `${getConsulUrl()}/v1/health/service/${serviceName}?passing=true`
    );
    
    if (response.ok) {
      const services = await response.json();
      if (services.length > 0) {
        const service = services[0].Service;
        return `http://${service.Address}:${service.Port}`;
      }
    }
    
    return null;
  } catch (error) {
    console.error(`Service discovery failed for ${serviceName}:`, error.message);
    return null;
  }
}

export default {
  bootstrap,
  getConfig,
  getMongoUri,
  discoverService
};
