// Database
export { connectDB, disconnectDB, getDBStatus, mongoose } from './config/database.js';

// Middleware
export { auth, authenticateToken, adminAuth, authorize, optionalAuth } from './middleware/auth.js';
export {
  AppError,
  ValidationError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
  errorHandler,
  notFoundHandler,
  asyncHandler
} from './middleware/errorHandler.js';
export { requestLogger, getRequestInfo } from './middleware/logger.js';

// Utilities
export {
  isValidEmail,
  isValidPhone,
  isStrongPassword,
  isValidDate,
  isPastDate,
  isFutureDate,
  isValidObjectId,
  sanitizeInput,
  validateRequiredFields
} from './utils/validation.js';
export {
  successResponse,
  errorResponse,
  paginatedResponse
} from './utils/responseFormatter.js';
export {
  formatDate,
  addDays,
  addHours,
  getDaysDifference,
  isToday,
  getStartOfDay,
  getEndOfDay,
  doTimeSlotsOverlap
} from './utils/dateUtils.js';

// Kafka
export { default as kafkaProducer } from './kafka/producer.js';
export { default as KafkaConsumer } from './kafka/consumer.js';
export { default as TOPICS } from './kafka/topics.js';

// Centralized Configuration (File-based)
export {
  initConfig,
  getConfig as getFileConfig,
  setConfig,
  setServiceConfig,
  getAllConfigs,
  isConfigInitialized,
  refreshConfig
} from './config/centralConfig.js';

// Consul Configuration (Service-based)
export {
  bootstrap,
  getConfig,
  getMongoUri,
  discoverService as discoverServiceFromConsul
} from './config/consulConfig.js';

// Redis - Caching, Sessions, Pub/Sub
export {
  createRedisClient,
  getRedisClient,
  disconnectRedis,
  cacheSet,
  cacheGet,
  cacheDelete,
  cacheDeletePattern,
  cacheOrFetch,
  createSession,
  getSession,
  validateSession,
  deleteSession,
  getUserSessions,
  deleteAllUserSessions,
  publish,
  subscribe,
  unsubscribe,
  CACHE_KEYS,
  CACHE_TTL,
  CHANNELS
} from './config/redis.js';

// Consul Service Discovery (legacy)
export {
  registerService,
  deregisterService,
  discoverService,
  getServiceUrl as getServiceUrlLegacy,
  getAllServices,
  watchService,
  isConsulHealthy,
  SERVICE_NAMES
} from './config/consul.js';

// Dynamic Service Discovery (recommended)
export {
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
} from './utils/serviceDiscovery.js';

export { EVENT_SCHEMAS, createEvent, generateEventId } from './kafka/schemas.js';
export {
  emitUserRegistered,
  emitAppointmentConfirmed,
  emitConsultationCreated,
  emitPrescriptionCreated,
  emitReferralCreated,
  emitMessageSent
} from './kafka/helpers.js';
