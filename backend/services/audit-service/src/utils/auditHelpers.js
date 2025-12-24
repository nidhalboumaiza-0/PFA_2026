import axios from 'axios';
import AuditLog from '../models/AuditLog.js';
import { getUserServiceUrl, getNotificationServiceUrl, getConfig } from '../../../../shared/index.js';

/**
 * Get user information from User Service
 */
export const getUserInfo = async (userId) => {
  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/api/v1/users/profile/${userId}`);
    return response.data.data;
  } catch (error) {
    console.error('Error fetching user info:', error.message);
    return null;
  }
};

/**
 * Get patient information
 */
export const getPatientInfo = async (patientId) => {
  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/api/v1/users/patients/${patientId}`);
    return response.data.data;
  } catch (error) {
    console.error('Error fetching patient info:', error.message);
    return null;
  }
};

/**
 * Send admin alert for critical events
 */
export const sendAdminAlert = async (auditLog) => {
  try {
    if (getConfig('ENABLE_CRITICAL_ALERTS') !== 'true') {
      return;
    }

    const notificationServiceUrl = await getNotificationServiceUrl();
    
    // Send notification via Notification Service
    await axios.post(
      `${notificationServiceUrl}/api/v1/notifications/admin-alert`,
      {
        title: `Critical Audit Event: ${auditLog.action}`,
        body: auditLog.description,
        severity: 'critical',
        metadata: {
          auditLogId: auditLog._id,
          performedBy: auditLog.performedByName,
          timestamp: auditLog.timestamp,
        },
      },
      {
        timeout: 5000,
      }
    );

    console.log(`✅ Admin alert sent for critical audit log: ${auditLog._id}`);
  } catch (error) {
    console.error('Error sending admin alert:', error.message);
  }
};

/**
 * Create audit log entry
 */
export const createAuditLog = async ({
  action,
  actionCategory,
  performedBy,
  performedByType,
  resourceType = null,
  resourceId = null,
  resourceName = null,
  patientId = null,
  description,
  severity = 'info',
  ipAddress = null,
  userAgent = null,
  requestMethod = null,
  requestUrl = null,
  changes = null,
  previousData = null,
  newData = null,
  status = 'success',
  errorMessage = null,
  metadata = {},
}) => {
  try {
    // Get actor details
    let performedByName = 'System';
    let performedByEmail = null;

    if (performedBy && performedByType !== 'system') {
      const actor = await getUserInfo(performedBy);
      if (actor) {
        performedByName = `${actor.firstName} ${actor.lastName}`;
        performedByEmail = actor.email;
      }
    }

    // Get patient details if applicable
    let patientName = null;
    if (patientId) {
      const patient = await getPatientInfo(patientId);
      if (patient) {
        patientName = `${patient.firstName} ${patient.lastName}`;
      }
    }

    // Determine compliance flags
    const isSecurityRelevant = ['authentication', 'user_management'].includes(actionCategory);
    const isComplianceRelevant = ['consultation', 'prescription', 'document'].includes(
      actionCategory
    );

    // Determine if requires review
    const requiresReview =
      severity === 'critical' || (status === 'failed' && isSecurityRelevant);

    // Create audit log
    const auditLog = await AuditLog.create({
      action,
      actionCategory,
      performedBy: performedBy || null,
      performedByType,
      performedByName,
      performedByEmail,
      resourceType,
      resourceId,
      resourceName,
      patientId,
      patientName,
      description,
      severity,
      ipAddress,
      userAgent,
      requestMethod,
      requestUrl,
      changes,
      previousData,
      newData,
      status,
      errorMessage,
      isSecurityRelevant,
      isComplianceRelevant,
      requiresReview,
      metadata,
      timestamp: new Date(),
    });

    // Send alert if critical
    if (severity === 'critical') {
      await sendAdminAlert(auditLog);
    }

    return auditLog;
  } catch (error) {
    console.error('Audit log creation failed:', error);
    // Don't throw error - audit failure shouldn't break app
    return null;
  }
};

/**
 * Express middleware for automatic audit logging
 */
export const auditMiddleware = (req, res, next) => {
  // Store original res.json
  const originalJson = res.json;

  // Override res.json to capture response
  res.json = function (data) {
    // Log after response (only if auditAction is set)
    if (req.user && req.auditAction) {
      const status = res.statusCode >= 200 && res.statusCode < 300 ? 'success' : 'failed';

      createAuditLog({
        action: req.auditAction.action,
        actionCategory: req.auditAction.category,
        performedBy: req.user.userId,
        performedByType: req.user.role,
        resourceType: req.auditAction.resourceType,
        resourceId: req.auditAction.resourceId,
        resourceName: req.auditAction.resourceName,
        patientId: req.auditAction.patientId,
        description: req.auditAction.description,
        severity: status === 'failed' ? 'warning' : req.auditAction.severity || 'info',
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
        requestMethod: req.method,
        requestUrl: req.originalUrl,
        changes: req.auditAction.changes,
        previousData: req.auditAction.previousData,
        newData: req.auditAction.newData,
        status,
        errorMessage: status === 'failed' ? data.message || data.error : null,
        metadata: req.auditAction.metadata || {},
      });
    }

    return originalJson.call(this, data);
  };

  next();
};

/**
 * Helper to set audit action on request
 */
export const setAuditAction = (req, auditAction) => {
  req.auditAction = auditAction;
};

/**
 * Format audit log for API response
 */
export const formatAuditLog = (log) => {
  return {
    id: log._id,
    action: log.action,
    actionCategory: log.actionCategory,
    performedBy: {
      id: log.performedBy,
      name: log.performedByName,
      email: log.performedByEmail,
      type: log.performedByType,
    },
    resource: log.resourceType
      ? {
          type: log.resourceType,
          id: log.resourceId,
          name: log.resourceName,
        }
      : null,
    patient: log.patientId
      ? {
          id: log.patientId,
          name: log.patientName,
        }
      : null,
    description: log.description,
    severity: log.severity,
    ipAddress: log.ipAddress,
    userAgent: log.userAgent,
    requestMethod: log.requestMethod,
    requestUrl: log.requestUrl,
    changes: log.changes,
    status: log.status,
    errorMessage: log.errorMessage,
    isSecurityRelevant: log.isSecurityRelevant,
    isComplianceRelevant: log.isComplianceRelevant,
    requiresReview: log.requiresReview,
    reviewedBy: log.reviewedBy,
    reviewedAt: log.reviewedAt,
    reviewNotes: log.reviewNotes,
    metadata: log.metadata,
    timestamp: log.timestamp,
    createdAt: log.createdAt,
  };
};

/**
 * Calculate pagination metadata
 */
export const calculatePagination = (page, limit, totalItems) => {
  const totalPages = Math.ceil(totalItems / limit);
  return {
    currentPage: page,
    totalPages,
    totalItems,
    itemsPerPage: limit,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
  };
};
