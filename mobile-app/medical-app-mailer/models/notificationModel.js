const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, "Une notification doit avoir un titre"],
    },
    body: {
      type: String,
      required: [true, "Une notification doit avoir un contenu"],
    },
    senderId: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "Une notification doit avoir un expéditeur"],
    },
    recipientId: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "Une notification doit avoir un destinataire"],
    },
    type: {
      type: String,
      enum: [
        "general",
        "appointment",
        "prescription",
        "message",
        "medical_record",
      ],
      default: "general",
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    appointmentId: {
      type: mongoose.Schema.ObjectId,
      ref: "Appointment",
    },
    prescriptionId: {
      type: mongoose.Schema.ObjectId,
      ref: "Prescription",
    },
    data: {
      type: Object,
      default: {},
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Index for faster queries
notificationSchema.index({ recipientId: 1, isRead: 1 });
notificationSchema.index({ createdAt: -1 });

const Notification = mongoose.model(
  "Notification",
  notificationSchema
);

module.exports = Notification;
