import { mongoose } from '../../../../shared/index.js';

const messageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      required: true,
      index: true,
    },

    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },

    senderType: {
      type: String,
      enum: ['patient', 'doctor'],
      required: true,
    },

    receiverId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },

    receiverType: {
      type: String,
      enum: ['patient', 'doctor'],
      required: true,
    },

    messageType: {
      type: String,
      enum: ['text', 'image', 'document', 'system'],
      default: 'text',
    },

    content: {
      type: String,
      required: function () {
        return this.messageType === 'text' || this.messageType === 'system';
      },
      maxlength: 5000,
    },

    attachment: {
      fileName: String,
      fileSize: Number,
      mimeType: String,
      s3Key: String,
      s3Url: String,
    },

    isRead: {
      type: Boolean,
      default: false,
    },

    readAt: Date,

    isDelivered: {
      type: Boolean,
      default: false,
    },

    deliveredAt: Date,

    isEdited: {
      type: Boolean,
      default: false,
    },

    editedAt: Date,

    isDeleted: {
      type: Boolean,
      default: false,
    },

    deletedAt: Date,

    deletedBy: mongoose.Schema.Types.ObjectId,

    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

// Compound indexes for efficient queries
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ senderId: 1, createdAt: -1 });
messageSchema.index({ receiverId: 1, isRead: 1 });

// Text index for message search
messageSchema.index({ content: 'text' });

// Instance method to mark as delivered
messageSchema.methods.markAsDelivered = function () {
  if (!this.isDelivered) {
    this.isDelivered = true;
    this.deliveredAt = new Date();
  }
};

// Instance method to mark as read
messageSchema.methods.markAsRead = function () {
  if (!this.isRead) {
    this.isRead = true;
    this.readAt = new Date();
    // Marking as read implies delivered
    if (!this.isDelivered) {
      this.markAsDelivered();
    }
  }
};

// Instance method to soft delete
messageSchema.methods.softDelete = function (deletedByUserId) {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.deletedBy = deletedByUserId;
  this.content = 'Message deleted';
};

// Instance method to check if user can delete
messageSchema.methods.canUserDelete = function (userId) {
  // Only sender can delete their own message
  return this.senderId.toString() === userId.toString();
};

// Instance method to check if message is recent (within 24 hours)
messageSchema.methods.isRecent = function () {
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
  return this.createdAt > oneDayAgo;
};

// Static method to get unread count for user
messageSchema.statics.getUnreadCountForUser = async function (userId) {
  return this.countDocuments({
    receiverId: userId,
    isRead: false,
    isDeleted: false,
  });
};

// Static method to mark multiple messages as read
messageSchema.statics.markMultipleAsRead = async function (messageIds, userId) {
  const now = new Date();
  return this.updateMany(
    {
      _id: { $in: messageIds },
      receiverId: userId,
      isRead: false,
    },
    {
      $set: {
        isRead: true,
        readAt: now,
        isDelivered: true,
        deliveredAt: now,
      },
    }
  );
};

const Message = mongoose.model('Message', messageSchema);

export default Message;
