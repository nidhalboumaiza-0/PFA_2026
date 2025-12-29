import rateLimit from 'express-rate-limit';
import { RedisStore } from 'rate-limit-redis';
import { createClient } from 'redis';
import { getConfig } from '../../../shared/index.js';

// Redis client singleton - initialized lazily after bootstrap
let redisClient = null;

// Rate limiters - initialized lazily after bootstrap  
let generalLimiter = null;
let authLimiter = null;
let uploadLimiter = null;

/**
 * Create Redis client for rate limiting
 * Called lazily after bootstrap() loads config from Consul
 */
const createRedisClient = async () => {
  const client = createClient({
    socket: {
      host: getConfig('REDIS_HOST', 'localhost'),
      port: parseInt(getConfig('REDIS_PORT', '6379'))
    },
    password: getConfig('REDIS_PASSWORD', undefined) || undefined
  });

  client.on('error', (err) => {
    console.error('❌ Redis Client Error:', err);
  });

  client.on('connect', () => {
    console.log('✅ Redis: Connected for rate limiting');
  });

  await client.connect();
  return client;
};

/**
 * Initialize rate limiters - MUST be called after bootstrap()
 * This ensures config is loaded from Consul before connecting to Redis
 */
export const initializeRateLimiters = async () => {
  if (redisClient) {
    console.log('⚠️ Rate limiters already initialized');
    return;
  }

  console.log('🔧 Initializing rate limiters with Redis...');
  redisClient = await createRedisClient();

  // General rate limiter (10000 requests per 15 minutes - very permissive for development)
  generalLimiter = rateLimit({
    windowMs: parseInt(getConfig('RATE_LIMIT_WINDOW_MS', '900000')),
    max: parseInt(getConfig('RATE_LIMIT_MAX_REQUESTS', '10000')),
    message: {
      success: false,
      message: 'Too many requests, please try again later'
    },
    standardHeaders: true,
    legacyHeaders: false,
    store: new RedisStore({
      sendCommand: (...args) => redisClient.sendCommand(args),
      prefix: 'rate_limit:general:'
    })
  });

  // Auth rate limiter (500 requests per 15 minutes - permissive for development)
  authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 500,
    message: {
      success: false,
      message: 'Too many authentication attempts, please try again later'
    },
    standardHeaders: true,
    legacyHeaders: false,
    store: new RedisStore({
      sendCommand: (...args) => redisClient.sendCommand(args),
      prefix: 'rate_limit:auth:'
    })
  });

  // File upload rate limiter (100 requests per hour - permissive for development)
  uploadLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 100,
    message: {
      success: false,
      message: 'Too many file uploads, please try again later'
    },
    store: new RedisStore({
      sendCommand: (...args) => redisClient.sendCommand(args),
      prefix: 'rate_limit:upload:'
    })
  });

  console.log('✅ Rate limiters initialized successfully');
};

/**
 * Get general rate limiter middleware
 * Returns a pass-through middleware if not initialized yet
 */
export const getGeneralLimiter = () => {
  return (req, res, next) => {
    if (generalLimiter) {
      return generalLimiter(req, res, next);
    }
    next();
  };
};

/**
 * Get auth rate limiter middleware
 * Returns a pass-through middleware if not initialized yet
 */
export const getAuthLimiter = () => {
  return (req, res, next) => {
    if (authLimiter) {
      return authLimiter(req, res, next);
    }
    next();
  };
};

/**
 * Get upload rate limiter middleware
 * Returns a pass-through middleware if not initialized yet
 */
export const getUploadLimiter = () => {
  return (req, res, next) => {
    if (uploadLimiter) {
      return uploadLimiter(req, res, next);
    }
    next();
  };
};
