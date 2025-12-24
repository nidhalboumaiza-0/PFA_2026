/**
 * Redis Utility Module
 * 
 * Provides Redis functionality for:
 * 1. Caching - Store frequently accessed data to reduce DB queries
 * 2. Sessions - Track logged-in users for better logout control
 * 3. Pub/Sub - Real-time notifications and events
 */

import { createClient } from 'redis';

// Redis client configuration
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = process.env.REDIS_PORT || 6379;
const REDIS_PASSWORD = process.env.REDIS_PASSWORD || undefined;

let redisClient = null;
let subscriberClient = null;

// ==================== Connection Management ====================

/**
 * Create and connect Redis client
 */
export const createRedisClient = async () => {
  if (redisClient && redisClient.isOpen) {
    return redisClient;
  }

  redisClient = createClient({
    socket: {
      host: REDIS_HOST,
      port: REDIS_PORT
    },
    password: REDIS_PASSWORD
  });

  redisClient.on('error', (err) => {
    console.error('❌ Redis Error:', err.message);
  });

  redisClient.on('connect', () => {
    console.log('✅ Redis: Connected');
  });

  redisClient.on('reconnecting', () => {
    console.log('🔄 Redis: Reconnecting...');
  });

  await redisClient.connect();
  return redisClient;
};

/**
 * Get the Redis client (creates if not exists)
 */
export const getRedisClient = async () => {
  if (!redisClient || !redisClient.isOpen) {
    return await createRedisClient();
  }
  return redisClient;
};

/**
 * Disconnect Redis client
 */
export const disconnectRedis = async () => {
  if (redisClient && redisClient.isOpen) {
    await redisClient.quit();
    console.log('👋 Redis: Disconnected');
  }
  if (subscriberClient && subscriberClient.isOpen) {
    await subscriberClient.quit();
  }
};

// ==================== CACHING ====================

/**
 * Cache data with expiration
 * 
 * @param {string} key - Cache key
 * @param {any} value - Value to cache (will be JSON stringified)
 * @param {number} ttlSeconds - Time to live in seconds (default: 5 minutes)
 */
export const cacheSet = async (key, value, ttlSeconds = 300) => {
  const client = await getRedisClient();
  const serialized = JSON.stringify(value);
  await client.setEx(key, ttlSeconds, serialized);
};

/**
 * Get cached data
 * 
 * @param {string} key - Cache key
 * @returns {any} - Parsed value or null if not found
 */
export const cacheGet = async (key) => {
  const client = await getRedisClient();
  const value = await client.get(key);
  if (!value) return null;
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
};

/**
 * Delete cached data
 * 
 * @param {string} key - Cache key
 */
export const cacheDelete = async (key) => {
  const client = await getRedisClient();
  await client.del(key);
};

/**
 * Delete multiple keys matching a pattern
 * 
 * @param {string} pattern - Pattern to match (e.g., "doctor:*")
 */
export const cacheDeletePattern = async (pattern) => {
  const client = await getRedisClient();
  const keys = await client.keys(pattern);
  if (keys.length > 0) {
    await client.del(keys);
  }
};

/**
 * Cache wrapper - get from cache or execute function and cache result
 * 
 * @param {string} key - Cache key
 * @param {Function} fetchFn - Function to execute if cache miss
 * @param {number} ttlSeconds - Time to live in seconds
 */
export const cacheOrFetch = async (key, fetchFn, ttlSeconds = 300) => {
  // Try cache first
  const cached = await cacheGet(key);
  if (cached) {
    return { data: cached, fromCache: true };
  }

  // Cache miss - fetch and store
  const data = await fetchFn();
  if (data) {
    await cacheSet(key, data, ttlSeconds);
  }
  return { data, fromCache: false };
};

// ==================== SESSIONS ====================

const SESSION_PREFIX = 'session:';
const USER_SESSIONS_PREFIX = 'user_sessions:';
const DEFAULT_SESSION_TTL = 24 * 60 * 60; // 24 hours

/**
 * Create a new session
 * 
 * @param {string} userId - User ID
 * @param {Object} sessionData - Session data (role, device, etc.)
 * @param {number} ttlSeconds - Session TTL (default: 24 hours)
 * @returns {string} - Session ID
 */
export const createSession = async (userId, sessionData = {}, ttlSeconds = DEFAULT_SESSION_TTL) => {
  const client = await getRedisClient();
  const sessionId = generateSessionId();
  
  const session = {
    sessionId,
    userId,
    createdAt: new Date().toISOString(),
    lastActivity: new Date().toISOString(),
    ...sessionData
  };

  // Store session
  await client.setEx(
    `${SESSION_PREFIX}${sessionId}`,
    ttlSeconds,
    JSON.stringify(session)
  );

  // Add to user's session list (for "logout all devices")
  await client.sAdd(`${USER_SESSIONS_PREFIX}${userId}`, sessionId);
  await client.expire(`${USER_SESSIONS_PREFIX}${userId}`, ttlSeconds);

  return sessionId;
};

/**
 * Get session by ID
 * 
 * @param {string} sessionId - Session ID
 * @returns {Object|null} - Session data or null
 */
export const getSession = async (sessionId) => {
  const client = await getRedisClient();
  const session = await client.get(`${SESSION_PREFIX}${sessionId}`);
  if (!session) return null;
  return JSON.parse(session);
};

/**
 * Validate session and update last activity
 * 
 * @param {string} sessionId - Session ID
 * @returns {Object|null} - Session data or null if invalid
 */
export const validateSession = async (sessionId) => {
  const client = await getRedisClient();
  const session = await getSession(sessionId);
  
  if (!session) return null;

  // Update last activity
  session.lastActivity = new Date().toISOString();
  const ttl = await client.ttl(`${SESSION_PREFIX}${sessionId}`);
  await client.setEx(
    `${SESSION_PREFIX}${sessionId}`,
    ttl > 0 ? ttl : DEFAULT_SESSION_TTL,
    JSON.stringify(session)
  );

  return session;
};

/**
 * Delete a session (logout)
 * 
 * @param {string} sessionId - Session ID
 */
export const deleteSession = async (sessionId) => {
  const client = await getRedisClient();
  const session = await getSession(sessionId);
  
  if (session) {
    // Remove from user's session list
    await client.sRem(`${USER_SESSIONS_PREFIX}${session.userId}`, sessionId);
  }
  
  await client.del(`${SESSION_PREFIX}${sessionId}`);
};

/**
 * Get all sessions for a user
 * 
 * @param {string} userId - User ID
 * @returns {Array} - List of session data
 */
export const getUserSessions = async (userId) => {
  const client = await getRedisClient();
  const sessionIds = await client.sMembers(`${USER_SESSIONS_PREFIX}${userId}`);
  
  const sessions = [];
  for (const sessionId of sessionIds) {
    const session = await getSession(sessionId);
    if (session) {
      sessions.push(session);
    } else {
      // Clean up stale session reference
      await client.sRem(`${USER_SESSIONS_PREFIX}${userId}`, sessionId);
    }
  }
  
  return sessions;
};

/**
 * Delete all sessions for a user (logout from all devices)
 * 
 * @param {string} userId - User ID
 * @returns {number} - Number of sessions deleted
 */
export const deleteAllUserSessions = async (userId) => {
  const client = await getRedisClient();
  const sessionIds = await client.sMembers(`${USER_SESSIONS_PREFIX}${userId}`);
  
  for (const sessionId of sessionIds) {
    await client.del(`${SESSION_PREFIX}${sessionId}`);
  }
  
  await client.del(`${USER_SESSIONS_PREFIX}${userId}`);
  
  return sessionIds.length;
};

/**
 * Generate a random session ID
 */
const generateSessionId = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < 32; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

// ==================== PUB/SUB ====================

/**
 * Publish a message to a channel
 * 
 * @param {string} channel - Channel name
 * @param {any} message - Message to publish (will be JSON stringified)
 */
export const publish = async (channel, message) => {
  const client = await getRedisClient();
  const serialized = typeof message === 'string' ? message : JSON.stringify(message);
  await client.publish(channel, serialized);
};

/**
 * Subscribe to a channel
 * 
 * @param {string} channel - Channel name
 * @param {Function} callback - Called when message received
 * @returns {Object} - Subscriber client for unsubscribing
 */
export const subscribe = async (channel, callback) => {
  // Create a separate client for subscribing (required by Redis)
  if (!subscriberClient) {
    subscriberClient = redisClient.duplicate();
    await subscriberClient.connect();
  }

  await subscriberClient.subscribe(channel, (message) => {
    try {
      const parsed = JSON.parse(message);
      callback(parsed);
    } catch {
      callback(message);
    }
  });

  return subscriberClient;
};

/**
 * Unsubscribe from a channel
 * 
 * @param {string} channel - Channel name
 */
export const unsubscribe = async (channel) => {
  if (subscriberClient) {
    await subscriberClient.unsubscribe(channel);
  }
};

// ==================== PUB/SUB CHANNELS ====================

export const CHANNELS = {
  // Chat channels
  CHAT_TYPING: (roomId) => `chat:${roomId}:typing`,
  CHAT_MESSAGES: (roomId) => `chat:${roomId}:messages`,
  
  // User presence
  USER_ONLINE: 'users:online',
  USER_STATUS: (userId) => `user:${userId}:status`,
  
  // Notifications
  NOTIFICATIONS: (userId) => `notifications:${userId}`,
  
  // Appointments
  APPOINTMENT_UPDATES: (appointmentId) => `appointment:${appointmentId}:updates`,
  DOCTOR_AVAILABILITY: (doctorId) => `doctor:${doctorId}:availability`
};

// ==================== CACHE KEYS ====================

export const CACHE_KEYS = {
  // Doctor cache
  DOCTOR_PROFILE: (doctorId) => `doctor:profile:${doctorId}`,
  DOCTOR_LIST: (specialty) => `doctors:list:${specialty || 'all'}`,
  DOCTOR_AVAILABILITY: (doctorId, date) => `doctor:availability:${doctorId}:${date}`,
  
  // Patient cache
  PATIENT_PROFILE: (patientId) => `patient:profile:${patientId}`,
  
  // Appointment cache
  APPOINTMENTS_BY_DOCTOR: (doctorId, date) => `appointments:doctor:${doctorId}:${date}`,
  APPOINTMENTS_BY_PATIENT: (patientId) => `appointments:patient:${patientId}`,
  
  // Specialties (rarely changes)
  SPECIALTIES_LIST: 'specialties:list',
  
  // User preferences
  USER_PREFERENCES: (userId) => `user:preferences:${userId}`
};

// ==================== CACHE TTL (in seconds) ====================

export const CACHE_TTL = {
  SHORT: 60,           // 1 minute
  MEDIUM: 300,         // 5 minutes
  LONG: 3600,          // 1 hour
  VERY_LONG: 86400,    // 24 hours
  
  DOCTOR_PROFILE: 600,      // 10 minutes
  DOCTOR_LIST: 300,         // 5 minutes
  AVAILABILITY: 60,         // 1 minute (changes frequently)
  SPECIALTIES: 3600,        // 1 hour
  USER_PREFERENCES: 1800    // 30 minutes
};

export default {
  // Connection
  createRedisClient,
  getRedisClient,
  disconnectRedis,
  
  // Caching
  cacheSet,
  cacheGet,
  cacheDelete,
  cacheDeletePattern,
  cacheOrFetch,
  CACHE_KEYS,
  CACHE_TTL,
  
  // Sessions
  createSession,
  getSession,
  validateSession,
  deleteSession,
  getUserSessions,
  deleteAllUserSessions,
  
  // Pub/Sub
  publish,
  subscribe,
  unsubscribe,
  CHANNELS
};
