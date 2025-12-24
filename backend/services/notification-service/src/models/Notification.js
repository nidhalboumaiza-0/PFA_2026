import { mongoose } from '../../../../shared/index.js';

const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },

    userType: {
      type: String,
      enum: ['patient', 'doctor', 'admin'],
      required: true,
    },

    title: {
      type: String,
      required: true,
      maxlength: 200,
    },

    body: {
      type: String,
      required: true,
      maxlength: 500,
    },

    type: {
      type: String,
      enum: [
        'appointment_confirmed',
        'appointment_rejected',
        'appointment_reminder',
        'appointment_cancelled',
        'new_message',
        'referral_received',
        'referral_scheduled',
        'consultation_created',
        'prescription_created',
        'document_uploaded',
        'system_alert',
      ],
      required: true,
    },

    relatedResource: {
      resourceType: {
        type: String,
        enum: ['appointment', 'message', 'referral', 'consultation', 'prescription', 'document'],
      },
      resourceId: mongoose.Schema.Types.ObjectId,
    },

    channels: {
      push: {
        enabled: {
          type: Boolean,
          default: true,
        },
        sent: {
          type: Boolean,
          default: false,
        },
        sentAt: Date,
        oneSignalId: String,
        error: String,
      },
      email: {
        enabled: {
          type: Boolean,
          default: true,
        },
        sent: {
          type: Boolean,
          default: false,
        },
        sentAt: Date,
        error: String,
      },
      inApp: {
        enabled: {
          type: Boolean,
          default: true,
        },
        delivered: {
          type: Boolean,
          default: true,
        },
      },
    },

    isRead: {
      type: Boolean,
      default: false,
    },

    readAt: Date,

    priority: {
      type: String,
      enum: ['low', 'medium', 'high', 'urgent'],
      default: 'medium',
    },

    actionUrl: String,

    actionData: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },

    scheduledFor: Date,
  },
  {
    timestamps: true,
  }
);

// Compound indexes for efficient queries
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });
notificationSchema.index({ type: 1, createdAt: -1 });
notificationSchema.index({ scheduledFor: 1 });

// Instance method to mark as read
notificationSchema.methods.markAsRead = function () {
  if (!this.isRead) {
    this.isRead = true;
    this.readAt = new Date();
  }
};

// Instance method to check if scheduled
notificationSchema.methods.isScheduled = function () {
  return this.scheduledFor && new Date(this.scheduledFor) > new Date();
};

// Instance method to check if due for sending
notificationSchema.methods.isDue = function () {
  if (!this.scheduledFor) return true;
  return new Date(this.scheduledFor) <= new Date();
};

// Static method to get unread count for user
notificationSchema.statics.getUnreadCountForUser = async function (userId) {
  return this.countDocuments({
    userId,
    isRead: false,
  });
};

// Static method to mark all as read for user
notificationSchema.statics.markAllAsReadForUser = async function (userId) {
  const result = await this.updateMany(
    { userId, isRead: false },
    { $set: { isRead: true, readAt: new Date() } }
  );
  return result.modifiedCount;
};

const Notification = mongoose.model('Notification', notificationSchema);

export default Notification;
