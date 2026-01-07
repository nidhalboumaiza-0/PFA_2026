/**
 * Consul Configuration Seeder - E-Santé Healthcare Platform
 * 
 * Seeds the Consul KV store with ALL configuration for the e-Santé platform.
 * This runs once at startup before all services.
 * 
 * Structure:
 *   esante/common/     - Shared configuration (JWT, MongoDB, Kafka, AWS, etc.)
 *   esante/{service}/  - Service-specific configuration
 */

const CONSUL_HOST = process.env.CONSUL_HOST || 'consul';
const CONSUL_PORT = process.env.CONSUL_PORT || '8500';
const CONSUL_URL = `http://${CONSUL_HOST}:${CONSUL_PORT}`;

// Retry configuration
const MAX_RETRIES = 30;
const RETRY_DELAY = 2000;

/**
 * Wait for Consul to be ready
 */
async function waitForConsul() {
  console.log(`⏳ Waiting for Consul at ${CONSUL_URL}...`);

  for (let i = 0; i < MAX_RETRIES; i++) {
    try {
      const response = await fetch(`${CONSUL_URL}/v1/status/leader`);
      if (response.ok) {
        const leader = await response.text();
        if (leader && leader !== '""') {
          console.log(`✅ Consul is ready! Leader: ${leader}`);
          return true;
        }
      }
    } catch (error) {
      // Ignore errors, keep retrying
    }

    console.log(`   Attempt ${i + 1}/${MAX_RETRIES}...`);
    await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
  }

  throw new Error('Consul not available after maximum retries');
}

/**
 * Set a key in Consul KV store
 */
async function setKey(key, value) {
  const response = await fetch(`${CONSUL_URL}/v1/kv/${key}`, {
    method: 'PUT',
    body: typeof value === 'object' ? JSON.stringify(value) : String(value)
  });

  if (!response.ok) {
    throw new Error(`Failed to set key ${key}: ${response.status}`);
  }

  return true;
}

/**
 * Seed all configuration
 */
async function seedConfiguration() {
  console.log('\n📋 Seeding configuration to Consul KV...\n');

  // ============================================================================
  // COMMON/SHARED CONFIGURATION (esante/common/)
  // These are shared across multiple services to avoid duplication
  // ============================================================================
  const commonConfig = {
    // === Environment ===
    'esante/common/NODE_ENV': 'development',
    'esante/common/LOG_LEVEL': 'info',

    // === JWT Configuration (shared by all services) ===
    // IMPORTANT: Must match docker-compose JWT_SECRET env var
    'esante/common/JWT_SECRET': 'your-super-secret-jwt-key-change-in-production',
    'esante/common/JWT_EXPIRE': '1d',
    'esante/common/JWT_REFRESH_SECRET': 'your_super_secret_refresh_key_change_in_production',
    'esante/common/JWT_REFRESH_EXPIRE': '30d',

    // === MongoDB Configuration ===
    'esante/common/MONGO_HOST': 'mongodb',
    'esante/common/MONGO_PORT': '27017',
    'esante/common/MONGO_USER': 'admin',
    'esante/common/MONGO_PASSWORD': 'password',
    'esante/common/MONGO_AUTH_SOURCE': 'admin',

    // === Redis Configuration ===
    'esante/common/REDIS_HOST': 'redis',
    'esante/common/REDIS_PORT': '6379',
    'esante/common/REDIS_PASSWORD': '',

    // === Kafka Configuration ===
    'esante/common/KAFKA_BROKERS': 'kafka:9092',

    // === AWS S3 Configuration ===
    'esante/common/AWS_REGION': 'eu-north-1',
   
    'esante/common/AWS_S3_BUCKET': 'esante-medical-documents',

    // === Email/SMTP Configuration ===
    'esante/common/SMTP_HOST': 'smtp.gmail.com',
    'esante/common/SMTP_PORT': '587',
    'esante/common/SMTP_SECURE': 'false',
    'esante/common/SMTP_USER': 'evatra752@gmail.com',
    'esante/common/SMTP_PASS': 'lgwc oqaf vqfw budl',
    'esante/common/EMAIL_FROM': 'evatra752@gmail.com',
    'esante/common/EMAIL_SERVICE': 'gmail',
    'esante/common/EMAIL_USER': 'evatra752@gmail.com',
    'esante/common/EMAIL_PASSWORD': 'lgwc oqaf vqfw budl',

    // === OneSignal Push Notifications ===
    'esante/common/ONESIGNAL_APP_ID': 'b7f38ec8-6bd1-468b-bf40-8bd991871561',
    'esante/common/ONESIGNAL_REST_API_KEY': 'os_v2_app_w7zy5sdl2fdixp2arpmzdbyvmhswk2ajua3ew4ucclozuixmlghmmpk22kucdsp22hrqclpm4va2uadpxvd3gvrkz6rcenxr3zu2veq',

    // === URLs (for inter-service communication) ===
    'esante/common/FRONTEND_URL': 'http://192.168.0.127:3000',
    'esante/common/ADMIN_URL': 'http://192.168.0.127:3001',
    'esante/common/API_GATEWAY_URL': 'http://192.168.0.127:3000',
    'esante/common/MOBILE_APP_SCHEME': 'esante://',

    // === Rate Limiting ===
    'esante/common/RATE_LIMIT_WINDOW_MS': '60000', // 1 minute
    'esante/common/RATE_LIMIT_MAX_REQUESTS': '1000' // 1000 requests per minute
  };

  // ============================================================================
  // API-GATEWAY (Port 3000)
  // ============================================================================
  const apiGatewayConfig = {
    'esante/api-gateway/PORT': '3000',
    'esante/api-gateway/SERVICE_NAME': 'api-gateway',
    'esante/api-gateway/AUTH_SERVICE_URL': 'http://auth-service:3001',
    'esante/api-gateway/USER_SERVICE_URL': 'http://user-service:3002',
    'esante/api-gateway/RDV_SERVICE_URL': 'http://rdv-service:3003',
    'esante/api-gateway/MEDICAL_SERVICE_URL': 'http://medical-records-service:3004',
    'esante/api-gateway/REFERRAL_SERVICE_URL': 'http://referral-service:3005',
    'esante/api-gateway/MESSAGING_SERVICE_URL': 'http://messaging-service:3006',
    'esante/api-gateway/NOTIFICATION_SERVICE_URL': 'http://notification-service:3007',
    'esante/api-gateway/AUDIT_SERVICE_URL': 'http://audit-service:3008'
  };

  // ============================================================================
  // AUTH-SERVICE (Port 3001)
  // ============================================================================
  const authServiceConfig = {
    'esante/auth-service/PORT': '3001',
    'esante/auth-service/SERVICE_NAME': 'auth-service',
    'esante/auth-service/MONGO_DB_NAME': 'esante_auth',
    'esante/auth-service/KAFKA_CLIENT_ID': 'auth-service',
    'esante/auth-service/BCRYPT_ROUNDS': '10'
  };

  // ============================================================================
  // USER-SERVICE (Port 3002)
  // ============================================================================
  const userServiceConfig = {
    'esante/user-service/PORT': '3002',
    'esante/user-service/SERVICE_NAME': 'user-service',
    'esante/user-service/MONGO_DB_NAME': 'esante_users',
    'esante/user-service/KAFKA_CLIENT_ID': 'user-service',
    'esante/user-service/KAFKA_GROUP_ID': 'user-service-group',
    'esante/user-service/AUTH_SERVICE_URL': 'http://auth-service:3001'
  };

  // ============================================================================
  // RDV-SERVICE (Port 3003) - Appointments
  // ============================================================================
  const rdvServiceConfig = {
    'esante/rdv-service/PORT': '3003',
    'esante/rdv-service/SERVICE_NAME': 'rdv-service',
    'esante/rdv-service/MONGO_DB_NAME': 'esante_rdv',
    'esante/rdv-service/KAFKA_CLIENT_ID': 'rdv-service',
    'esante/rdv-service/KAFKA_GROUP_ID': 'rdv-service-group',
    'esante/rdv-service/USER_SERVICE_URL': 'http://user-service:3002',
    'esante/rdv-service/DEFAULT_SLOT_DURATION': '30'
  };

  // ============================================================================
  // MEDICAL-RECORDS-SERVICE (Port 3004)
  // ============================================================================
  const medicalRecordsConfig = {
    'esante/medical-records-service/PORT': '3004',
    'esante/medical-records-service/SERVICE_NAME': 'medical-records-service',
    'esante/medical-records-service/MONGO_DB_NAME': 'esante_medical_records',
    'esante/medical-records-service/KAFKA_CLIENT_ID': 'medical-records-service',
    'esante/medical-records-service/KAFKA_GROUP_ID': 'medical-records-group',
    'esante/medical-records-service/USER_SERVICE_URL': 'http://user-service:3002',
    'esante/medical-records-service/RDV_SERVICE_URL': 'http://rdv-service:3003',
    'esante/medical-records-service/MAX_FILE_SIZE': '10485760'
  };

  // ============================================================================
  // REFERRAL-SERVICE (Port 3005)
  // ============================================================================
  const referralServiceConfig = {
    'esante/referral-service/PORT': '3005',
    'esante/referral-service/SERVICE_NAME': 'referral-service',
    'esante/referral-service/MONGO_DB_NAME': 'esante_referrals',
    'esante/referral-service/KAFKA_CLIENT_ID': 'referral-service',
    'esante/referral-service/KAFKA_GROUP_ID': 'referral-service-group',
    'esante/referral-service/USER_SERVICE_URL': 'http://user-service:3002/api/v1/users',
    'esante/referral-service/RDV_SERVICE_URL': 'http://rdv-service:3003/api/v1/rdv',
    'esante/referral-service/MEDICAL_RECORDS_SERVICE_URL': 'http://medical-records-service:3004/api/v1/medical',
    'esante/referral-service/REFERRAL_EXPIRY_DAYS': '90'
  };

  // ============================================================================
  // MESSAGING-SERVICE (Port 3006)
  // ============================================================================
  const messagingServiceConfig = {
    'esante/messaging-service/PORT': '3006',
    'esante/messaging-service/SERVICE_NAME': 'messaging-service',
    'esante/messaging-service/MONGO_DB_NAME': 'esante_messaging',
    'esante/messaging-service/KAFKA_CLIENT_ID': 'messaging-service',
    'esante/messaging-service/KAFKA_GROUP_ID': 'messaging-service-group',
    'esante/messaging-service/USER_SERVICE_URL': 'http://user-service:3002',
    'esante/messaging-service/NOTIFICATION_SERVICE_URL': 'http://notification-service:3007',
    'esante/messaging-service/AWS_S3_BUCKET': 'esante-messages',
    'esante/messaging-service/MAX_FILE_SIZE': '10485760',
    'esante/messaging-service/MAX_MESSAGE_LENGTH': '5000',
    'esante/messaging-service/MESSAGES_PER_PAGE': '50'
  };

  // ============================================================================
  // NOTIFICATION-SERVICE (Port 3007)
  // ============================================================================
  const notificationServiceConfig = {
    'esante/notification-service/PORT': '3007',
    'esante/notification-service/SERVICE_NAME': 'notification-service',
    'esante/notification-service/MONGO_DB_NAME': 'esante_notifications',
    'esante/notification-service/KAFKA_CLIENT_ID': 'notification-service',
    'esante/notification-service/KAFKA_GROUP_ID': 'notification-service-group',
    'esante/notification-service/USER_SERVICE_URL': 'http://user-service:3002',
    'esante/notification-service/RDV_SERVICE_URL': 'http://rdv-service:3003',
    'esante/notification-service/MESSAGING_SERVICE_URL': 'http://messaging-service:3006',
    'esante/notification-service/EMAIL_FROM': '"E-Santé <noreply@esante.com>"',
    'esante/notification-service/DEFAULT_NOTIFICATION_LIMIT': '20',
    'esante/notification-service/MAX_NOTIFICATION_LIMIT': '100',
    'esante/notification-service/SCHEDULED_NOTIFICATION_INTERVAL': '* * * * *',
    'esante/notification-service/BATCH_SIZE': '100'
  };

  // ============================================================================
  // AUDIT-SERVICE (Port 3008)
  // ============================================================================
  const auditServiceConfig = {
    'esante/audit-service/PORT': '3008',
    'esante/audit-service/SERVICE_NAME': 'audit-service',
    'esante/audit-service/MONGO_DB_NAME': 'esante-audit',
    'esante/audit-service/KAFKA_CLIENT_ID': 'audit-service',
    'esante/audit-service/KAFKA_GROUP_ID': 'audit-service-group',
    'esante/audit-service/USER_SERVICE_URL': 'http://user-service:3002',
    'esante/audit-service/NOTIFICATION_SERVICE_URL': 'http://notification-service:3007',
    'esante/audit-service/DEFAULT_AUDIT_LIMIT': '50',
    'esante/audit-service/MAX_AUDIT_LIMIT': '500',
    'esante/audit-service/AUDIT_LOG_RETENTION_DAYS': '365',
    'esante/audit-service/ENABLE_CRITICAL_ALERTS': 'true',
    'esante/audit-service/ALERT_WEBHOOK_URL': '',
    'esante/audit-service/EXPORT_MAX_RECORDS': '10000'
  };

  // ============================================================================
  // SERVICE REGISTRY (for service discovery)
  // ============================================================================
  const serviceRegistry = {
    'esante/services/api-gateway/host': 'api-gateway',
    'esante/services/api-gateway/port': '3000',
    'esante/services/auth-service/host': 'auth-service',
    'esante/services/auth-service/port': '3001',
    'esante/services/user-service/host': 'user-service',
    'esante/services/user-service/port': '3002',
    'esante/services/rdv-service/host': 'rdv-service',
    'esante/services/rdv-service/port': '3003',
    'esante/services/medical-records-service/host': 'medical-records-service',
    'esante/services/medical-records-service/port': '3004',
    'esante/services/referral-service/host': 'referral-service',
    'esante/services/referral-service/port': '3005',
    'esante/services/messaging-service/host': 'messaging-service',
    'esante/services/messaging-service/port': '3006',
    'esante/services/notification-service/host': 'notification-service',
    'esante/services/notification-service/port': '3007',
    'esante/services/audit-service/host': 'audit-service',
    'esante/services/audit-service/port': '3008'
  };

  // Combine all configs
  const allConfig = {
    ...commonConfig,
    ...apiGatewayConfig,
    ...authServiceConfig,
    ...userServiceConfig,
    ...rdvServiceConfig,
    ...medicalRecordsConfig,
    ...referralServiceConfig,
    ...messagingServiceConfig,
    ...notificationServiceConfig,
    ...auditServiceConfig,
    ...serviceRegistry
  };

  // Seed each key
  let successCount = 0;
  let failCount = 0;

  console.log('--- Common Configuration ---');
  for (const [key, value] of Object.entries(commonConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- API Gateway ---');
  for (const [key, value] of Object.entries(apiGatewayConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- Auth Service ---');
  for (const [key, value] of Object.entries(authServiceConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- User Service ---');
  for (const [key, value] of Object.entries(userServiceConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- RDV Service ---');
  for (const [key, value] of Object.entries(rdvServiceConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- Medical Records Service ---');
  for (const [key, value] of Object.entries(medicalRecordsConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- Referral Service ---');
  for (const [key, value] of Object.entries(referralServiceConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- Messaging Service ---');
  for (const [key, value] of Object.entries(messagingServiceConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- Notification Service ---');
  for (const [key, value] of Object.entries(notificationServiceConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- Audit Service ---');
  for (const [key, value] of Object.entries(auditServiceConfig)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n--- Service Registry ---');
  for (const [key, value] of Object.entries(serviceRegistry)) {
    try {
      await setKey(key, value);
      console.log(`   ✓ ${key}`);
      successCount++;
    } catch (error) {
      console.error(`   ✗ ${key}: ${error.message}`);
      failCount++;
    }
  }

  console.log('\n' + '='.repeat(50));
  console.log(`📊 Results: ${successCount} succeeded, ${failCount} failed`);
  console.log('='.repeat(50) + '\n');

  return failCount === 0;
}

/**
 * Main entry point
 */
async function main() {
  console.log('\n' + '='.repeat(60));
  console.log('🚀 E-Santé Consul Configuration Seeder');
  console.log('   Centralizing ALL environment variables');
  console.log('='.repeat(60) + '\n');

  try {
    // Wait for Consul to be ready
    await waitForConsul();

    // Seed configuration
    const success = await seedConfiguration();

    if (success) {
      console.log('✅ Configuration seeding completed successfully!');
      console.log('📍 View in Consul UI: http://localhost:8500/ui/dc1/kv/esante/');
      process.exit(0);
    } else {
      console.error('❌ Some configuration failed to seed');
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ Fatal error:', error.message);
    process.exit(1);
  }
}

main();
