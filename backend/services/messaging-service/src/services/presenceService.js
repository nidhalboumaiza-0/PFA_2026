/**
 * Presence Service
 * 
 * Manages user online/offline status using Redis Pub/Sub
 * This allows real-time presence updates across multiple server instances
 */

import { publish, subscribe, CHANNELS, cacheSet, cacheGet, cacheDelete } from '../../../../shared/index.js';

const USER_PRESENCE_PREFIX = 'presence:';
const PRESENCE_TTL = 300; // 5 minutes

/**
 * Set user as online
 * @param {string} userId - User ID
 * @param {Object} metadata - Additional info (socketId, device, etc.)
 */
export const setUserOnline = async (userId, metadata = {}) => {
  const presenceData = {
    userId,
    status: 'online',
    lastSeen: new Date().toISOString(),
    ...metadata
  };

  // Store in Redis
  await cacheSet(`${USER_PRESENCE_PREFIX}${userId}`, presenceData, PRESENCE_TTL);

  // Publish to presence channel for real-time updates
  await publish(CHANNELS.USER_ONLINE, {
    type: 'user_online',
    userId,
    timestamp: Date.now()
  });

  console.log(`👤 User ${userId} is now online`);
};

/**
 * Set user as offline
 * @param {string} userId - User ID
 */
export const setUserOffline = async (userId) => {
  // Update presence with offline status
  await cacheSet(`${USER_PRESENCE_PREFIX}${userId}`, {
    userId,
    status: 'offline',
    lastSeen: new Date().toISOString()
  }, PRESENCE_TTL);

  // Publish offline event
  await publish(CHANNELS.USER_ONLINE, {
    type: 'user_offline',
    userId,
    timestamp: Date.now()
  });

  console.log(`👤 User ${userId} is now offline`);
};

/**
 * Get user presence status
 * @param {string} userId - User ID
 * @returns {Object|null} - Presence data or null
 */
export const getUserPresence = async (userId) => {
  return await cacheGet(`${USER_PRESENCE_PREFIX}${userId}`);
};

/**
 * Check if user is online
 * @param {string} userId - User ID
 * @returns {boolean}
 */
export const isUserOnline = async (userId) => {
  const presence = await getUserPresence(userId);
  return presence?.status === 'online';
};

/**
 * Update user's last seen time
 * @param {string} userId - User ID
 */
export const updateLastSeen = async (userId) => {
  const presence = await getUserPresence(userId);
  if (presence) {
    presence.lastSeen = new Date().toISOString();
    await cacheSet(`${USER_PRESENCE_PREFIX}${userId}`, presence, PRESENCE_TTL);
  }
};

/**
 * Subscribe to presence updates
 * @param {Function} callback - Called when presence changes
 */
export const subscribeToPresence = async (callback) => {
  return await subscribe(CHANNELS.USER_ONLINE, callback);
};

/**
 * Publish typing status
 * @param {string} conversationId - Conversation ID
 * @param {string} userId - User who is typing
 * @param {boolean} isTyping - Whether user is typing
 */
export const publishTypingStatus = async (conversationId, userId, isTyping) => {
  await publish(CHANNELS.CHAT_TYPING(conversationId), {
    userId,
    isTyping,
    timestamp: Date.now()
  });
};

/**
 * Subscribe to typing updates in a conversation
 * @param {string} conversationId - Conversation ID
 * @param {Function} callback - Called when typing status changes
 */
export const subscribeToTyping = async (conversationId, callback) => {
  return await subscribe(CHANNELS.CHAT_TYPING(conversationId), callback);
};

export default {
  setUserOnline,
  setUserOffline,
  getUserPresence,
  isUserOnline,
  updateLastSeen,
  subscribeToPresence,
  publishTypingStatus,
  subscribeToTyping
};
