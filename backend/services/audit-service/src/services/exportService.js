import { Parser } from 'json2csv';
import AuditLog from '../models/AuditLog.js';

/**
 * Export audit logs to CSV
 */
export const exportToCSV = async (filters) => {
  try {
    const { actionCategory, startDate, endDate, limit = 1000 } = filters;

    const query = {};
    if (actionCategory) query.actionCategory = actionCategory;
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const logs = await AuditLog.find(query)
      .sort({ timestamp: -1 })
      .limit(Math.min(limit, 10000))
      .lean();

    // Format logs for CSV
    const formattedLogs = logs.map((log) => ({
      Timestamp: log.timestamp,
      Action: log.action,
      Category: log.actionCategory,
      PerformedBy: log.performedByName,
      PerformedByEmail: log.performedByEmail,
      PerformedByType: log.performedByType,
      Description: log.description,
      Severity: log.severity,
      Status: log.status,
      ResourceType: log.resourceType || '',
      ResourceId: log.resourceId || '',
      PatientName: log.patientName || '',
      IPAddress: log.ipAddress || '',
      RequestMethod: log.requestMethod || '',
      RequestURL: log.requestUrl || '',
      ErrorMessage: log.errorMessage || '',
      IsSecurityRelevant: log.isSecurityRelevant,
      IsComplianceRelevant: log.isComplianceRelevant,
      RequiresReview: log.requiresReview,
    }));

    // Convert to CSV
    const parser = new Parser();
    const csv = parser.parse(formattedLogs);

    return csv;
  } catch (error) {
    console.error('Error exporting to CSV:', error);
    throw error;
  }
};

/**
 * Export audit logs to JSON
 */
export const exportToJSON = async (filters) => {
  try {
    const { actionCategory, startDate, endDate, limit = 1000 } = filters;

    const query = {};
    if (actionCategory) query.actionCategory = actionCategory;
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const logs = await AuditLog.find(query)
      .sort({ timestamp: -1 })
      .limit(Math.min(limit, 10000))
      .lean();

    return JSON.stringify(logs, null, 2);
  } catch (error) {
    console.error('Error exporting to JSON:', error);
    throw error;
  }
};

/**
 * Generate HIPAA compliance report
 */
export const generateHIPAAReport = async (startDate, endDate) => {
  try {
    const dateFilter = {};
    if (startDate) dateFilter.$gte = new Date(startDate);
    if (endDate) dateFilter.$lte = new Date(endDate);

    const matchStage = Object.keys(dateFilter).length > 0 ? { timestamp: dateFilter } : {};

    // Get all compliance-relevant logs
    const complianceLogs = await AuditLog.find({
      ...matchStage,
      isComplianceRelevant: true,
    })
      .sort({ timestamp: -1 })
      .lean();

    // Group by action category
    const byCategory = complianceLogs.reduce((acc, log) => {
      if (!acc[log.actionCategory]) {
        acc[log.actionCategory] = [];
      }
      acc[log.actionCategory].push(log);
      return acc;
    }, {});

    // Get patient access statistics
    const patientAccesses = await AuditLog.aggregate([
      {
        $match: {
          ...matchStage,
          isComplianceRelevant: true,
          patientId: { $exists: true, $ne: null },
        },
      },
      {
        $group: {
          _id: {
            patientId: '$patientId',
            performedBy: '$performedBy',
          },
          count: { $sum: 1 },
          firstAccess: { $min: '$timestamp' },
          lastAccess: { $max: '$timestamp' },
          actions: { $push: '$action' },
        },
      },
    ]);

    return {
      reportType: 'HIPAA Compliance',
      dateRange: {
        start: startDate || 'All time',
        end: endDate || 'Present',
      },
      summary: {
        totalComplianceEvents: complianceLogs.length,
        byCategory: Object.keys(byCategory).map((category) => ({
          category,
          count: byCategory[category].length,
        })),
        uniquePatientsAccessed: new Set(complianceLogs.map((log) => log.patientId).filter(Boolean))
          .size,
        uniqueAccessors: new Set(complianceLogs.map((log) => log.performedBy).filter(Boolean))
          .size,
      },
      detailedAccesses: patientAccesses,
      logs: complianceLogs,
    };
  } catch (error) {
    console.error('Error generating HIPAA report:', error);
    throw error;
  }
};

/**
 * Generate general activity report
 */
export const generateActivityReport = async (startDate, endDate) => {
  try {
    const statistics = await AuditLog.getStatistics(startDate, endDate);

    // Get detailed breakdown
    const dateFilter = {};
    if (startDate) dateFilter.$gte = new Date(startDate);
    if (endDate) dateFilter.$lte = new Date(endDate);

    const matchStage = Object.keys(dateFilter).length > 0 ? { timestamp: dateFilter } : {};

    // Get top users by activity
    const topUsers = await AuditLog.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: '$performedBy',
          name: { $first: '$performedByName' },
          type: { $first: '$performedByType' },
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
      { $limit: 20 },
    ]);

    // Get activity timeline (grouped by day)
    const timeline = await AuditLog.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$timestamp' },
          },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    return {
      reportType: 'Activity Report',
      dateRange: {
        start: startDate || 'All time',
        end: endDate || 'Present',
      },
      summary: statistics,
      topUsers: topUsers.map((user) => ({
        userId: user._id,
        name: user.name,
        type: user.type,
        actionCount: user.count,
      })),
      timeline: timeline.map((item) => ({
        date: item._id,
        count: item.count,
      })),
    };
  } catch (error) {
    console.error('Error generating activity report:', error);
    throw error;
  }
};
