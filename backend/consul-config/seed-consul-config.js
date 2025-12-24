/**
 * Consul Configuration Seeder
 * 
 * Seeds all configuration keys to Consul KV store for centralized configuration.
 * Run this before starting services to ensure all config is available.
 */

const CONSUL_HOST = process.env.CONSUL_HOST || 'consul';
const CONSUL_PORT = process.env.CONSUL_PORT || '8500';
const CONSUL_URL = `http://${CONSUL_HOST}:${CONSUL_PORT}`;

/**
 * Set a key-value pair in Consul
 */
async function setKey(key, value) {
  try {
    const response = await fetch(`${CONSUL_URL}/v1/kv/${key}`, {
      method: 'PUT',
      body: typeof value === 'string' ? value : JSON.stringify(value)
    });
    return response.ok;
  } catch (error) {
    console.error(`Failed to set ${key}:`, error.message);
    return false;
  }
}

/**
 * Seed configuration to Consul
 */
async function seedConfig() {
  console.log('🌱 Seeding Consul configuration...');
  console.log(`📡 Consul URL: ${CONSUL_URL}`);
  
  let successCount = 0;
  let failCount = 0;

  // ==================== COMMON CONFIG ====================
  const commonConfig = {
    // Node environment
    NODE_ENV: 'production',
    
    // MongoDB
    MONGO_HOST: 'mongodb',
    MONGO_PORT: '27017',
    MONGO_USER: 'admin',
    MONGO_PASSWORD: 'password',
    
    // Redis
    REDIS_HOST: 'redis',
    REDIS_PORT: '6379',
    REDIS_PASSWORD: '',
    
    // Kafka
    KAFKA_BROKERS: 'kafka:9092',
    KAFKA_CLIENT_ID: 'esante',
    
    // JWT
    JWT_SECRET: 'your-super-secret-jwt-key-change-in-production',
    JWT_EXPIRES_IN: '24h',
    JWT_REFRESH_SECRET: 'your-refresh-token-secret-change-in-production',
    JWT_REFRESH_EXPIRES_IN: '7d',
    
    // Consul
    CONSUL_HOST: 'consul',
    CONSUL_PORT: '8500',
    
    // Email (SMTP)
    EMAIL_HOST: 'smtp.gmail.com',
    EMAIL_PORT: '587',
    EMAIL_USER: '',
    EMAIL_PASSWORD: '',
    EMAIL_FROM: 'E-Santé <noreply@esante.com>',
    
    // AWS S3
    AWS_ACCESS_KEY_ID: '',
    AWS_SECRET_ACCESS_KEY: '',
    AWS_REGION: 'eu-west-3',
    AWS_S3_BUCKET: 'esante-medical-files',
    
    // OneSignal Push Notifications
    ONESIGNAL_APP_ID: 'b2fdf7f6-8ee2-4d30-9adc-54f3abf69524',
    ONESIGNAL_API_KEY: 'os_v2_app_52axdpcjfnhuzpd3b6zl5wn2r4a5lrukpzuxdkxuuyfhf5wlhq22zhqzpq35e3f5gyjf4g6i26uqghlcq6dq5oo7l5xuzprz2plqogq',
    
    // Frontend URLs
    FRONTEND_URL: 'http://localhost:3000',
    ADMIN_URL: 'http://localhost:3001',
    MOBILE_APP_SCHEME: 'esante://',
  };

  // Seed common config
  console.log('\n📦 Seeding common config...');
  for (const [key, value] of Object.entries(commonConfig)) {
    const success = await setKey(`config/common/${key}`, value);
    if (success) {
      successCount++;
    } else {
      failCount++;
      console.error(`   ❌ Failed: ${key}`);
    }
  }

  // ==================== SERVICE-SPECIFIC CONFIG ====================
  const serviceConfigs = {
    'api-gateway': {
      PORT: '3000',
      SERVICE_NAME: 'api-gateway',
      RATE_LIMIT_WINDOW_MS: '900000',
      RATE_LIMIT_MAX_REQUESTS: '100',
    },
    'auth-service': {
      PORT: '3001',
      SERVICE_NAME: 'auth-service',
      MONGO_DB_NAME: 'auth_db',
      BCRYPT_ROUNDS: '12',
    },
    'user-service': {
      PORT: '3002',
      SERVICE_NAME: 'user-service',
      MONGO_DB_NAME: 'user_db',
      KAFKA_GROUP_ID: 'user-service-group',
    },
    'rdv-service': {
      PORT: '3003',
      SERVICE_NAME: 'rdv-service',
      MONGO_DB_NAME: 'rdv_db',
      KAFKA_GROUP_ID: 'rdv-service-group',
    },
    'medical-records-service': {
      PORT: '3004',
      SERVICE_NAME: 'medical-records-service',
      MONGO_DB_NAME: 'medical_records_db',
      KAFKA_GROUP_ID: 'medical-records-service-group',
    },
    'referral-service': {
      PORT: '3005',
      SERVICE_NAME: 'referral-service',
      MONGO_DB_NAME: 'referral_db',
      KAFKA_GROUP_ID: 'referral-service-group',
    },
    'messaging-service': {
      PORT: '3006',
      SERVICE_NAME: 'messaging-service',
      MONGO_DB_NAME: 'messaging_db',
      KAFKA_GROUP_ID: 'messaging-service-group',
    },
    'notification-service': {
      PORT: '3007',
      SERVICE_NAME: 'notification-service',
      MONGO_DB_NAME: 'notification_db',
      KAFKA_GROUP_ID: 'notification-service-group',
      QUIET_HOURS_START: '22',
      QUIET_HOURS_END: '7',
    },
    'audit-service': {
      PORT: '3008',
      SERVICE_NAME: 'audit-service',
      MONGO_DB_NAME: 'audit_db',
      KAFKA_GROUP_ID: 'audit-service-group',
      AUDIT_LOG_RETENTION_DAYS: '90',
    },
  };

  // Seed service-specific config
  console.log('\n📦 Seeding service configs...');
  for (const [service, config] of Object.entries(serviceConfigs)) {
    console.log(`   🔧 ${service}...`);
    for (const [key, value] of Object.entries(config)) {
      const success = await setKey(`config/services/${service}/${key}`, value);
      if (success) {
        successCount++;
      } else {
        failCount++;
        console.error(`      ❌ Failed: ${key}`);
      }
    }
  }

  // ==================== SERVICE REGISTRY ====================
  const serviceRegistry = {
    'api-gateway': { host: 'api-gateway', port: 3000, healthPath: '/health' },
    'auth-service': { host: 'auth-service', port: 3001, healthPath: '/health' },
    'user-service': { host: 'user-service', port: 3002, healthPath: '/health' },
    'rdv-service': { host: 'rdv-service', port: 3003, healthPath: '/health' },
    'medical-records-service': { host: 'medical-records-service', port: 3004, healthPath: '/health' },
    'referral-service': { host: 'referral-service', port: 3005, healthPath: '/health' },
    'messaging-service': { host: 'messaging-service', port: 3006, healthPath: '/health' },
    'notification-service': { host: 'notification-service', port: 3007, healthPath: '/health' },
    'audit-service': { host: 'audit-service', port: 3008, healthPath: '/health' },
  };

  // Seed service registry
  console.log('\n📦 Seeding service registry...');
  for (const [service, info] of Object.entries(serviceRegistry)) {
    const success = await setKey(`services/${service}/info`, JSON.stringify(info));
    if (success) {
      successCount++;
    } else {
      failCount++;
      console.error(`   ❌ Failed: ${service}`);
    }
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log(`✨ Seeding Complete!`);
  console.log(`   Total Keys: ${successCount + failCount}`);
  console.log(`   Successful: ${successCount}`);
  console.log(`   Failed: ${failCount}`);
  console.log('='.repeat(50));

  if (failCount > 0) {
    process.exit(1);
  }
}

// Wait for Consul to be ready
async function waitForConsul(maxRetries = 30, retryInterval = 2000) {
  console.log('⏳ Waiting for Consul to be ready...');
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(`${CONSUL_URL}/v1/status/leader`);
      if (response.ok) {
        const leader = await response.text();
        if (leader && leader !== '""') {
          console.log('✅ Consul is ready!');
          return true;
        }
      }
    } catch (error) {
      // Consul not ready yet
    }
    
    console.log(`   Retry ${i + 1}/${maxRetries}...`);
    await new Promise(resolve => setTimeout(resolve, retryInterval));
  }
  
  console.error('❌ Consul did not become ready in time');
  return false;
}

// Main
async function main() {
  console.log('🚀 Consul Configuration Seeder');
  console.log('='.repeat(50));
  
  const isReady = await waitForConsul();
  if (!isReady) {
    process.exit(1);
  }
  
  await seedConfig();
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
