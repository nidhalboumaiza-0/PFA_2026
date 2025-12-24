import axios from 'axios';
import { getUserServiceUrl, getRdvServiceUrl, getMessagingServiceUrl } from '../../../../shared/index.js';

/**
 * Get user information from User Service
 * @param {string} userId - User ID
 * @param {string} token - JWT token
 * @returns {Promise<object>} - User data
 */
export const getUserInfo = async (userId, token) => {
  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/api/v1/users/profile/${userId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return response.data.data;
  } catch (error) {
    console.error('Error fetching user info:', error.message);
    return null;
  }
};

/**
 * Get doctor by ID
 * @param {string} doctorId - Doctor ID
 * @returns {Promise<object>} - Doctor data
 */
export const getDoctorById = async (doctorId) => {
  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/api/v1/users/doctors/${doctorId}`);
    return response.data.data;
  } catch (error) {
    console.error('Error fetching doctor:', error.message);
    return null;
  }
};

/**
 * Get patient by ID
 * @param {string} patientId - Patient ID
 * @returns {Promise<object>} - Patient data
 */
export const getPatientById = async (patientId) => {
  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/api/v1/users/patients/${patientId}`);
    return response.data.data;
  } catch (error) {
    console.error('Error fetching patient:', error.message);
    return null;
  }
};

/**
 * Get appointment by ID
 * @param {string} appointmentId - Appointment ID
 * @returns {Promise<object>} - Appointment data
 */
export const getAppointmentById = async (appointmentId) => {
  try {
    const rdvServiceUrl = await getRdvServiceUrl();
    const response = await axios.get(`${rdvServiceUrl}/api/v1/appointments/${appointmentId}`);
    return response.data.data;
  } catch (error) {
    console.error('Error fetching appointment:', error.message);
    return null;
  }
};

/**
 * Check if user is online via Messaging Service
 * @param {string} userId - User ID
 * @returns {Promise<boolean>} - Online status
 */
export const isUserOnline = async (userId) => {
  try {
    const messagingServiceUrl = await getMessagingServiceUrl();
    const response = await axios.get(
      `${messagingServiceUrl}/api/v1/messages/users/${userId}/online-status`
    );
    return response.data.data.isOnline || false;
  } catch (error) {
    console.error('Error checking online status:', error.message);
    return false;
  }
};

/**
 * Format notification for API response
 * @param {object} notification - Notification document
 * @returns {object} - Formatted notification
 */
export const formatNotificationForResponse = (notification) => {
  return {
    id: notification._id,
    userId: notification.userId,
    userType: notification.userType,
    title: notification.title,
    body: notification.body,
    type: notification.type,
    relatedResource: notification.relatedResource,
    channels: {
      push: {
        enabled: notification.channels.push.enabled,
        sent: notification.channels.push.sent,
        sentAt: notification.channels.push.sentAt,
      },
      email: {
        enabled: notification.channels.email.enabled,
        sent: notification.channels.email.sent,
        sentAt: notification.channels.email.sentAt,
      },
      inApp: {
        enabled: notification.channels.inApp.enabled,
        delivered: notification.channels.inApp.delivered,
      },
    },
    isRead: notification.isRead,
    readAt: notification.readAt,
    priority: notification.priority,
    actionUrl: notification.actionUrl,
    actionData: notification.actionData,
    scheduledFor: notification.scheduledFor,
    createdAt: notification.createdAt,
    updatedAt: notification.updatedAt,
  };
};

/**
 * Calculate pagination metadata
 * @param {number} page - Current page
 * @param {number} limit - Items per page
 * @param {number} totalItems - Total number of items
 * @returns {object} - Pagination metadata
 */
export const calculatePagination = (page, limit, totalItems) => {
  const totalPages = Math.ceil(totalItems / limit);
  const hasNextPage = page < totalPages;
  const hasPrevPage = page > 1;

  return {
    currentPage: page,
    totalPages,
    totalItems,
    itemsPerPage: limit,
    hasNextPage,
    hasPrevPage,
  };
};
