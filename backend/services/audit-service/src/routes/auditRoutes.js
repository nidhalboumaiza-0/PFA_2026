import express from 'express';
import {
  getAuditLogs,
  getUserActivity,
  getPatientAccessLog,
  getSecurityEvents,
  getAuditStatistics,
  markLogAsReviewed,
  exportAuditLogs,
  getHIPAAReport,
  getActivityReport,
} from '../controllers/auditController.js';
import { auth } from '../../../../shared/index.js';

// For admin-only routes, we'll add role check in the controller
const adminOnly = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ message: 'Admin access required' });
  }
};
import {
  validate,
  getAuditLogsSchema,
  getUserActivitySchema,
  getPatientAccessLogSchema,
  getSecurityEventsSchema,
  getStatisticsSchema,
  markAsReviewedSchema,
  exportLogsSchema,
} from '../validators/auditValidator.js';

const router = express.Router();

// All routes require authentication and admin privileges
router.use(auth);
router.use(adminOnly);

// Get audit logs with filters
router.get('/logs', validate(getAuditLogsSchema), getAuditLogs);

// Get user activity history
router.get('/users/:userId/activity', validate(getUserActivitySchema), getUserActivity);

// Get patient access log
router.get(
  '/patients/:patientId/access-log',
  validate(getPatientAccessLogSchema),
  getPatientAccessLog
);

// Get security events
router.get('/security-events', validate(getSecurityEventsSchema), getSecurityEvents);

// Get audit statistics
router.get('/statistics', validate(getStatisticsSchema), getAuditStatistics);

// Mark audit log as reviewed
router.put('/logs/:logId/review', validate(markAsReviewedSchema), markLogAsReviewed);

// Export audit logs
router.get('/export', validate(exportLogsSchema), exportAuditLogs);

// Generate HIPAA compliance report
router.get('/compliance/hipaa-report', validate(getStatisticsSchema), getHIPAAReport);

// Generate activity report
router.get('/compliance/activity-report', validate(getStatisticsSchema), getActivityReport);

export default router;
