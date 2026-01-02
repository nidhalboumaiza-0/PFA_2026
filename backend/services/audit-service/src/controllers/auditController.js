import AuditLog from '../models/AuditLog.js';
import { formatAuditLog, calculatePagination, getUserInfo, getPatientInfo } from '../utils/auditHelpers.js';
import {
  exportToCSV,
  exportToJSON,
  generateHIPAAReport,
  generateActivityReport,
} from '../services/exportService.js';

/**
 * Get audit logs with filters
 * GET /api/v1/audit/logs
 */
export const getAuditLogs = async (req, res) => {
  try {
    const filters = req.query;

    const result = await AuditLog.getLogsWithFilters(filters);

    const formattedLogs = result.logs.map(formatAuditLog);
    const pagination = calculatePagination(result.page, result.limit, result.totalCount);

    // Get summary statistics for the filtered results
    const summary = {
      total: result.totalCount,
      bySeverity: {},
      byCategory: {},
    };

    // Calculate summary (this could be optimized with aggregation if needed)
    result.logs.forEach((log) => {
      summary.bySeverity[log.severity] = (summary.bySeverity[log.severity] || 0) + 1;
      summary.byCategory[log.actionCategory] = (summary.byCategory[log.actionCategory] || 0) + 1;
    });

    res.json({
      success: true,
      data: {
        logs: formattedLogs,
        pagination,
        summary,
      },
    });
  } catch (error) {
    console.error('Error getting audit logs:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching audit logs',
      error: error.message,
    });
  }
};

/**
 * Get user activity history
 * GET /api/v1/audit/users/:userId/activity
 */
export const getUserActivity = async (req, res) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate, actionCategory, page = 1, limit = 50 } = req.query;

    // Get user info
    const user = await getUserInfo(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Build query
    const query = { performedBy: userId };
    if (actionCategory) query.actionCategory = actionCategory;
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const skip = (page - 1) * limit;

    const [logs, totalCount] = await Promise.all([
      AuditLog.find(query).sort({ timestamp: -1 }).skip(skip).limit(parseInt(limit)),
      AuditLog.countDocuments(query),
    ]);

    // Calculate statistics
    const statistics = {
      totalActions: totalCount,
      loginCount: await AuditLog.countDocuments({
        performedBy: userId,
        action: 'user.login',
      }),
      consultationsViewed: await AuditLog.countDocuments({
        performedBy: userId,
        actionCategory: 'consultation',
      }),
      documentsAccessed: await AuditLog.countDocuments({
        performedBy: userId,
        actionCategory: 'document',
      }),
    };

    const activityTimeline = logs.map((log) => ({
      timestamp: log.timestamp,
      action: log.action,
      description: log.description,
      patient: log.patientName,
      severity: log.severity,
      resourceType: log.resourceType,
    }));

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: `${user.firstName} ${user.lastName}`,
          email: user.email,
          type: user.role,
        },
        activityTimeline,
        statistics,
        pagination: calculatePagination(parseInt(page), parseInt(limit), totalCount),
      },
    });
  } catch (error) {
    console.error('Error getting user activity:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user activity',
      error: error.message,
    });
  }
};

/**
 * Get patient access log
 * GET /api/v1/audit/patients/:patientId/access-log
 */
export const getPatientAccessLog = async (req, res) => {
  try {
    const { patientId } = req.params;
    const { startDate, endDate, page = 1, limit = 50 } = req.query;

    // Get patient info
    const patient = await getPatientInfo(patientId);
    if (!patient) {
      return res.status(404).json({
        success: false,
        message: 'Patient not found',
      });
    }

    // Build query for patient-related logs
    const query = { patientId };
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const skip = (page - 1) * limit;

    const [logs, totalCount] = await Promise.all([
      AuditLog.find(query).sort({ timestamp: -1 }).skip(skip).limit(parseInt(limit)),
      AuditLog.countDocuments(query),
    ]);

    // Get unique doctors who accessed this patient
    const uniqueDoctors = await AuditLog.distinct('performedBy', {
      patientId,
      performedByType: 'doctor',
    });

    // Get last access time
    const lastAccessLog = await AuditLog.findOne({ patientId }).sort({ timestamp: -1 });

    const accessLog = logs.map((log) => ({
      timestamp: log.timestamp,
      accessedBy: {
        id: log.performedBy,
        name: log.performedByName,
        type: log.performedByType,
      },
      action: log.action,
      resourceType: log.resourceType,
      ipAddress: log.ipAddress,
      description: log.description,
    }));

    const statistics = {
      totalAccesses: totalCount,
      uniqueDoctors: uniqueDoctors.length,
      lastAccessed: lastAccessLog?.timestamp || null,
    };

    res.json({
      success: true,
      data: {
        patient: {
          id: patient._id,
          name: `${patient.firstName} ${patient.lastName}`,
        },
        accessLog,
        statistics,
        pagination: calculatePagination(parseInt(page), parseInt(limit), totalCount),
      },
    });
  } catch (error) {
    console.error('Error getting patient access log:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching patient access log',
      error: error.message,
    });
  }
};

/**
 * Get security events
 * GET /api/v1/audit/security-events
 */
export const getSecurityEvents = async (req, res) => {
  try {
    const { severity, requiresReview, startDate, endDate, page = 1, limit = 20 } = req.query;

    const query = { isSecurityRelevant: true };
    if (severity) query.severity = severity;
    if (requiresReview !== undefined) query.requiresReview = requiresReview;
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const skip = (page - 1) * limit;

    const [events, totalCount] = await Promise.all([
      AuditLog.find(query).sort({ timestamp: -1 }).skip(skip).limit(parseInt(limit)),
      AuditLog.countDocuments(query),
    ]);

    // Get summary
    const summary = {
      critical: await AuditLog.countDocuments({ ...query, severity: 'critical' }),
      warning: await AuditLog.countDocuments({ ...query, severity: 'warning' }),
      requiresReview: await AuditLog.countDocuments({ ...query, requiresReview: true }),
    };

    const formattedEvents = events.map((event) => ({
      id: event._id,
      timestamp: event.timestamp,
      action: event.action,
      severity: event.severity,
      description: event.description,
      performedBy: event.performedByName,
      ipAddress: event.ipAddress,
      metadata: event.metadata,
      requiresReview: event.requiresReview,
      status: event.status,
    }));

    res.json({
      success: true,
      data: {
        events: formattedEvents,
        summary,
        pagination: calculatePagination(parseInt(page), parseInt(limit), totalCount),
      },
    });
  } catch (error) {
    console.error('Error getting security events:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching security events',
      error: error.message,
    });
  }
};

/**
 * Get audit statistics
 * GET /api/v1/audit/statistics
 */
export const getAuditStatistics = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const statistics = await AuditLog.getStatistics(startDate, endDate);

    // Get top users
    const topUsers = await AuditLog.aggregate([
      {
        $match:
          startDate || endDate
            ? {
                timestamp: {
                  ...(startDate && { $gte: new Date(startDate) }),
                  ...(endDate && { $lte: new Date(endDate) }),
                },
              }
            : {},
      },
      {
        $group: {
          _id: '$performedBy',
          name: { $first: '$performedByName' },
          actionCount: { $sum: 1 },
        },
      },
      { $sort: { actionCount: -1 } },
      { $limit: 10 },
    ]);

    res.json({
      success: true,
      data: {
        ...statistics,
        dateRange: {
          start: startDate || 'All time',
          end: endDate || 'Present',
        },
        topUsers: topUsers.map((user) => ({
          userId: user._id,
          name: user.name,
          actionCount: user.actionCount,
        })),
      },
    });
  } catch (error) {
    console.error('Error getting audit statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching audit statistics',
      error: error.message,
    });
  }
};

/**
 * Mark audit log as reviewed
 * PUT /api/v1/audit/logs/:logId/review
 */
export const markLogAsReviewed = async (req, res) => {
  try {
    const { logId } = req.params;
    const { reviewNotes } = req.body;
    const adminId = req.user.profileId;

    const auditLog = await AuditLog.findById(logId);

    if (!auditLog) {
      return res.status(404).json({
        success: false,
        message: 'Audit log not found',
      });
    }

    auditLog.reviewedBy = adminId;
    auditLog.reviewedAt = new Date();
    auditLog.reviewNotes = reviewNotes;
    auditLog.requiresReview = false;

    await auditLog.save();

    res.json({
      success: true,
      message: 'Audit log marked as reviewed',
      data: formatAuditLog(auditLog),
    });
  } catch (error) {
    console.error('Error marking log as reviewed:', error);
    res.status(500).json({
      success: false,
      message: 'Error marking audit log as reviewed',
      error: error.message,
    });
  }
};

/**
 * Export audit logs
 * GET /api/v1/audit/export
 */
export const exportAuditLogs = async (req, res) => {
  try {
    const { format, actionCategory, startDate, endDate, limit } = req.query;

    let exportData;
    let contentType;
    let filename;

    if (format === 'json') {
      exportData = await exportToJSON({ actionCategory, startDate, endDate, limit });
      contentType = 'application/json';
      filename = `audit-logs-${Date.now()}.json`;
    } else {
      // Default to CSV
      exportData = await exportToCSV({ actionCategory, startDate, endDate, limit });
      contentType = 'text/csv';
      filename = `audit-logs-${Date.now()}.csv`;
    }

    res.setHeader('Content-Type', contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(exportData);
  } catch (error) {
    console.error('Error exporting audit logs:', error);
    res.status(500).json({
      success: false,
      message: 'Error exporting audit logs',
      error: error.message,
    });
  }
};

/**
 * Generate HIPAA compliance report
 * GET /api/v1/audit/compliance/hipaa-report
 */
export const getHIPAAReport = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const report = await generateHIPAAReport(startDate, endDate);

    res.json({
      success: true,
      data: report,
    });
  } catch (error) {
    console.error('Error generating HIPAA report:', error);
    res.status(500).json({
      success: false,
      message: 'Error generating HIPAA compliance report',
      error: error.message,
    });
  }
};

/**
 * Generate activity report
 * GET /api/v1/audit/compliance/activity-report
 */
export const getActivityReport = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const report = await generateActivityReport(startDate, endDate);

    res.json({
      success: true,
      data: report,
    });
  } catch (error) {
    console.error('Error generating activity report:', error);
    res.status(500).json({
      success: false,
      message: 'Error generating activity report',
      error: error.message,
    });
  }
};
