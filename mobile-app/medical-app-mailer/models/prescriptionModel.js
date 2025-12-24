const mongoose = require("mongoose");

const medicationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, "Le nom du médicament est requis"],
  },
  dosage: {
    type: String,
    required: [true, "La posologie est requise"],
  },
  instructions: {
    type: String,
    required: [true, "Les instructions sont requises"],
  },
  frequency: {
    type: String,
  },
  duration: {
    type: String,
  },
});

const prescriptionSchema = new mongoose.Schema(
  {
    appointment: {
      type: mongoose.Schema.ObjectId,
      ref: "Appointment",
      required: [true, "L'identifiant du rendez-vous est requis"],
    },
    patient: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "L'identifiant du patient est requis"],
    },
    medecin: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "L'identifiant du médecin est requis"],
    },
    medications: {
      type: [medicationSchema],
      required: [true, "Au moins un médicament est requis"],
      validate: {
        validator: function (medications) {
          return medications.length > 0;
        },
        message:
          "La prescription doit contenir au moins un médicament",
      },
    },
    note: {
      type: String,
    },
    issuedAt: {
      type: Date,
      default: Date.now,
    },
    expiresAt: {
      type: Date,
    },
    status: {
      type: String,
      enum: ["active", "completed", "expired"],
      default: "active",
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Populate references when querying
prescriptionSchema.pre(/^find/, function (next) {
  this.populate({
    path: "patient",
    select: "name lastName",
  }).populate({
    path: "medecin",
    select: "name lastName speciality",
  });
  next();
});

const Prescription = mongoose.model(
  "Prescription",
  prescriptionSchema
);

module.exports = Prescription;
