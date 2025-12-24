import { mongoose } from '../../../../shared/index.js';

const auditLogSchema = new mongoose.Schema(
  {
    // Action Details
    action: {
      type: String,
      required: true,
      index: true,
      trim: true,
    },
    actionCategory: {
      type: String,
      required: true,
      enum: [
        'authentication',
        'user_management',
        'appointment',
        'consultation',
        'prescription',
        'document',
        'referral',
        'message',
        'system',
      ],
      index: true,
    },

    // Actor (Who performed the action)
    performedBy: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },
    performedByType: {
      type: String,
      required: true,
      enum: ['patient', 'doctor', 'admin', 'system'],
    },
    performedByName: {
      type: String,
      required: true,
    },
    performedByEmail: {
      type: String,
    },

    // Target (What was affected)
    resourceType: {
      type: String,
      index: true,
    },
    resourceId: {
      type: mongoose.Schema.Types.ObjectId,
      index: true,
    },
    resourceName: {
      type: String,
    },

    // Patient Context (for medical records)
    patientId: {
      type: mongoose.Schema.Types.ObjectId,
      index: true,
    },
    patientName: {
      type: String,
    },

    // Action Details
    description: {
      type: String,
      required: true,
    },
    severity: {
      type: String,
      enum: ['info', 'warning', 'critical'],
      default: 'info',
      index: true,
    },

    // Request Metadata
    ipAddress: {
      type: String,
      index: true,
    },
    userAgent: {
      type: String,
    },
    requestMethod: {
      type: String,
      enum: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', null],
    },
    requestUrl: {
      type: String,
    },

    // Data Changes (for update/delete actions)
    changes: {
      type: mongoose.Schema.Types.Mixed,
    },
    previousData: {
      type: mongoose.Schema.Types.Mixed,
    },
    newData: {
      type: mongoose.Schema.Types.Mixed,
    },

    // Status
    status: {
      type: String,
      enum: ['success', 'failed', 'blocked'],
      default: 'success',
      index: true,
    },
    errorMessage: {
      type: String,
    },

    // Compliance Flags
    isSecurityRelevant: {
      type: Boolean,
      default: false,
      index: true,
    },
    isComplianceRelevant: {
      type: Boolean,
      default: false,
      index: true,
    },
    requiresReview: {
      type: Boolean,
      default: false,
      index: true,
    },

    // Review Information
    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
    },
    reviewedAt: {
      type: Date,
    },
    reviewNotes: {
      type: String,
    },

    // Metadata
    metadata: {
      type: mongoose.Schema.Types.Mixed,
    },

    timestamp: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound Indexes for efficient queries
auditLogSchema.index({ performedBy: 1, timestamp: -1 });
auditLogSchema.index({ patientId: 1, timestamp: -1 });
auditLogSchema.index({ resourceType: 1, resourceId: 1, timestamp: -1 });
auditLogSchema.index({ actionCategory: 1, timestamp: -1 });
auditLogSchema.index({ severity: 1, timestamp: -1 });
auditLogSchema.index({ isSecurityRelevant: 1, timestamp: -1 });
auditLogSchema.index({ isComplianceRelevant: 1, timestamp: -1 });

// TTL Index (Optional: Auto-delete old logs after X days)
// Uncomment to enable automatic cleanup of old logs
// const RETENTION_DAYS = parseInt(process.env.AUDIT_LOG_RETENTION_DAYS) || 365;
// auditLogSchema.index({ timestamp: 1 }, { expireAfterSeconds: RETENTION_DAYS * 24 * 60 * 60 });

// Static method to get logs with filters
auditLogSchema.statics.getLogsWithFilters = async function (filters) {
  const {
    actionCategory,
    performedBy,
    patientId,
    resourceType,
    severity,
    status,
    isSecurityRelevant,
    isComplianceRelevant,
    requiresReview,
    startDate,
    endDate,
    page = 1,
    limit = 50,
  } = filters;

  const query = {};

  if (actionCategory) query.actionCategory = actionCategory;
  if (performedBy) query.performedBy = performedBy;
  if (patientId) query.patientId = patientId;
  if (resourceType) query.resourceType = resourceType;
  if (severity) query.severity = severity;
  if (status) query.status = status;
  if (isSecurityRelevant !== undefined) query.isSecurityRelevant = isSecurityRelevant;
  if (isComplianceRelevant !== undefined) query.isComplianceRelevant = isComplianceRelevant;
  if (requiresReview !== undefined) query.requiresReview = requiresReview;

  // Date range filter
  if (startDate || endDate) {
    query.timestamp = {};
    if (startDate) query.timestamp.$gte = new Date(startDate);
    if (endDate) query.timestamp.$lte = new Date(endDate);
  }

  const skip = (page - 1) * limit;

  const [logs, totalCount] = await Promise.all([
    this.find(query).sort({ timestamp: -1 }).skip(skip).limit(limit),
    this.countDocuments(query),
  ]);

  return { logs, totalCount, page, limit };
};

// Static method to get statistics
auditLogSchema.statics.getStatistics = async function (startDate, endDate) {
  const dateFilter = {};
  if (startDate) dateFilter.$gte = new Date(startDate);
  if (endDate) dateFilter.$lte = new Date(endDate);

  const matchStage = Object.keys(dateFilter).length > 0 ? { timestamp: dateFilter } : {};

  const [totalLogs, bySeverity, byCategory, byStatus, topActions, securityEvents] =
    await Promise.all([
      this.countDocuments(matchStage),
      this.aggregate([
        { $match: matchStage },
        { $group: { _id: '$severity', count: { $sum: 1 } } },
      ]),
      this.aggregate([
        { $match: matchStage },
        { $group: { _id: '$actionCategory', count: { $sum: 1 } } },
      ]),
      this.aggregate([
        { $match: matchStage },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      this.aggregate([
        { $match: matchStage },
        { $group: { _id: '$action', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
      this.aggregate([
        {
          $match: {
            ...matchStage,
            isSecurityRelevant: true,
          },
        },
        { $group: { _id: '$action', count: { $sum: 1 } } },
      ]),
    ]);

  return {
    totalLogs,
    bySeverity: bySeverity.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {}),
    byCategory: byCategory.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {}),
    byStatus: byStatus.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {}),
    topActions: topActions.map((item) => ({ action: item._id, count: item.count })),
    securityEvents: securityEvents.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {}),
  };
};

const AuditLog = mongoose.model('AuditLog', auditLogSchema);

export default AuditLog;
