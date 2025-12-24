import { mongoose } from '../../../../shared/index.js';

const conversationSchema = new mongoose.Schema(
  {
    participants: {
      type: [mongoose.Schema.Types.ObjectId],
      required: true,
      validate: {
        validator: function (v) {
          return v.length === 2;
        },
        message: 'Conversation must have exactly 2 participants',
      },
    },

    participantTypes: [
      {
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          required: true,
        },
        userType: {
          type: String,
          enum: ['patient', 'doctor'],
          required: true,
        },
      },
    ],

    conversationType: {
      type: String,
      enum: ['patient_doctor', 'doctor_doctor'],
      required: true,
    },

    lastMessage: {
      content: String,
      senderId: mongoose.Schema.Types.ObjectId,
      timestamp: Date,
      isRead: {
        type: Boolean,
        default: false,
      },
    },

    unreadCount: {
      type: Map,
      of: Number,
      default: {},
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    isArchived: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index to prevent duplicate conversations
// Sort participants array before saving to ensure consistent ordering
conversationSchema.index({ participants: 1 }, { unique: true });

// Index for finding user's conversations
conversationSchema.index({ participants: 1, 'lastMessage.timestamp': -1 });

// Index for conversation type filtering
conversationSchema.index({ conversationType: 1 });

// Pre-save hook to sort participants and set participant types
conversationSchema.pre('save', function (next) {
  if (this.isModified('participants')) {
    // Sort participants to ensure consistent ordering
    this.participants.sort((a, b) => a.toString().localeCompare(b.toString()));

    // Initialize unreadCount for both participants if not set
    if (!this.unreadCount || this.unreadCount.size === 0) {
      const unreadMap = new Map();
      this.participants.forEach((participantId) => {
        unreadMap.set(participantId.toString(), 0);
      });
      this.unreadCount = unreadMap;
    }
  }
  next();
});

// Instance method to check if user is participant
conversationSchema.methods.isParticipant = function (userId) {
  return this.participants.some(
    (participantId) => participantId.toString() === userId.toString()
  );
};

// Instance method to get other participant
conversationSchema.methods.getOtherParticipant = function (userId) {
  return this.participants.find(
    (participantId) => participantId.toString() !== userId.toString()
  );
};

// Instance method to get unread count for user
conversationSchema.methods.getUnreadCountForUser = function (userId) {
  return this.unreadCount.get(userId.toString()) || 0;
};

// Instance method to increment unread count for user
conversationSchema.methods.incrementUnreadCount = function (userId) {
  const currentCount = this.unreadCount.get(userId.toString()) || 0;
  this.unreadCount.set(userId.toString(), currentCount + 1);
};

// Instance method to reset unread count for user
conversationSchema.methods.resetUnreadCount = function (userId) {
  this.unreadCount.set(userId.toString(), 0);
};

// Instance method to update last message
conversationSchema.methods.updateLastMessage = function (message) {
  this.lastMessage = {
    content: message.content || 'File attachment',
    senderId: message.senderId,
    timestamp: message.createdAt,
    isRead: false,
  };
};

const Conversation = mongoose.model('Conversation', conversationSchema);

export default Conversation;
