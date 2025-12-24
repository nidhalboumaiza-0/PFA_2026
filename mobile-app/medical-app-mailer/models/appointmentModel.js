const mongoose = require("mongoose");

const appointmentSchema = new mongoose.Schema(
  {
    startDate: {
      type: Date,
      required: [true, "Veuillez fournir la date de début !"],
    },
    endDate: {
      type: Date,
    },
    serviceName: {
      type: String,
      required: [true, "Veuillez fournir le nom du service !"],
    },
    patient: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "Veuillez fournir le patient !"],
    },
    medecin: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "Veuillez fournir le médecin !"],
    },
    status: {
      type: String,
      enum: ["En attente", "Accepté", "Refusé", "Annulé", "Terminé"],
      default: "En attente",
    },
    motif: {
      type: String,
    },
    notes: {
      type: String,
    },
    symptoms: {
      type: [String],
      default: [],
    },
    isRated: {
      type: Boolean,
      default: false,
    },
    hasPrescription: {
      type: Boolean,
      default: false,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Populate the patient and medecin references when querying
appointmentSchema.pre(/^find/, function (next) {
  this.populate(
    "patient",
    "name lastName profilePicture phoneNumber"
  ).populate("medecin", "name lastName profilePicture speciality");
  next();
});

// Virtual populate for prescription
appointmentSchema.virtual("prescription", {
  ref: "Prescription",
  foreignField: "appointment",
  localField: "_id",
  justOne: true,
});

const Appointment = mongoose.model("Appointment", appointmentSchema);

module.exports = Appointment;
