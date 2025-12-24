import { mongoose } from '../../../../shared/index.js';

const notificationPreferenceSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      unique: true,
      index: true,
    },

    preferences: {
      appointmentConfirmed: {
        push: {
          type: Boolean,
          default: true,
        },
        email: {
          type: Boolean,
          default: true,
        },
        inApp: {
          type: Boolean,
          default: true,
        },
      },
      appointmentReminder: {
        push: {
          type: Boolean,
          default: true,
        },
        email: {
          type: Boolean,
          default: true,
        },
        inApp: {
          type: Boolean,
          default: true,
        },
      },
      appointmentCancelled: {
        push: {
          type: Boolean,
          default: true,
        },
        email: {
          type: Boolean,
          default: true,
        },
        inApp: {
          type: Boolean,
          default: true,
        },
      },
      newMessage: {
        push: {
          type: Boolean,
          default: true,
        },
        email: {
          type: Boolean,
          default: false,
        },
        inApp: {
          type: Boolean,
          default: true,
        },
      },
      referral: {
        push: {
          type: Boolean,
          default: true,
        },
        email: {
          type: Boolean,
          default: true,
        },
        inApp: {
          type: Boolean,
          default: true,
        },
      },
      prescription: {
        push: {
          type: Boolean,
          default: true,
        },
        email: {
          type: Boolean,
          default: true,
        },
        inApp: {
          type: Boolean,
          default: true,
        },
      },
      systemAlert: {
        push: {
          type: Boolean,
          default: true,
        },
        email: {
          type: Boolean,
          default: true,
        },
        inApp: {
          type: Boolean,
          default: true,
        },
      },
    },

    devices: [
      {
        oneSignalPlayerId: {
          type: String,
          required: true,
        },
        deviceType: {
          type: String,
          enum: ['mobile', 'web'],
          required: true,
        },
        platform: {
          type: String,
          enum: ['android', 'ios', 'web'],
          required: true,
        },
        registeredAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],

    // Quiet hours configuration (push notifications only, email still sent)
    quietHours: {
      enabled: {
        type: Boolean,
        default: false,
      },
      startTime: {
        type: String,
        default: '22:00', // 10 PM
      },
      endTime: {
        type: String,
        default: '07:00', // 7 AM
      },
    },
  },
  {
    timestamps: true,
  }
);

// Instance method to add device
notificationPreferenceSchema.methods.addDevice = function (deviceData) {
  // Check if device already registered
  const existingDevice = this.devices.find(
    (d) => d.oneSignalPlayerId === deviceData.oneSignalPlayerId
  );

  if (existingDevice) {
    return { added: false, message: 'Device already registered' };
  }

  this.devices.push({
    ...deviceData,
    registeredAt: new Date(),
  });

  return { added: true, message: 'Device registered successfully' };
};

// Instance method to remove device
notificationPreferenceSchema.methods.removeDevice = function (playerId) {
  const initialLength = this.devices.length;
  this.devices = this.devices.filter((d) => d.oneSignalPlayerId !== playerId);
  return this.devices.length < initialLength;
};

// Instance method to get player IDs
notificationPreferenceSchema.methods.getPlayerIds = function () {
  return this.devices.map((d) => d.oneSignalPlayerId);
};

// Static method to get or create preferences
notificationPreferenceSchema.statics.getOrCreate = async function (userId) {
  let preferences = await this.findOne({ userId });

  if (!preferences) {
    preferences = await this.create({ userId });
  }

  return preferences;
};

const NotificationPreference = mongoose.model('NotificationPreference', notificationPreferenceSchema);

export default NotificationPreference;
