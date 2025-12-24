const mongoose = require("mongoose");
const User = require("./userModel");

const patientSchema = new mongoose.Schema({
  antecedent: {
    type: String,
    required: [true, "Veuillez fournir vos antécédents médicaux !"],
  },
  bloodType: {
    type: String,
    enum: [
      "A+",
      "A-",
      "B+",
      "B-",
      "AB+",
      "AB-",
      "O+",
      "O-",
      "Unknown",
    ],
    default: "Unknown",
  },
  height: {
    type: Number, // in cm
  },
  weight: {
    type: Number, // in kg
  },
  allergies: {
    type: [String],
    default: [],
  },
  chronicDiseases: {
    type: [String],
    default: [],
  },
  emergencyContact: {
    name: String,
    relationship: String,
    phoneNumber: String,
  },
});

// Virtual populate for appointments
patientSchema.virtual("appointments", {
  ref: "Appointment",
  foreignField: "patient",
  localField: "_id",
});

// Virtual populate for medical records
patientSchema.virtual("medicalRecords", {
  ref: "MedicalRecord",
  foreignField: "patient",
  localField: "_id",
});

// Virtual populate for prescriptions
patientSchema.virtual("prescriptions", {
  ref: "Prescription",
  foreignField: "patient",
  localField: "_id",
});

const Patient = User.discriminator("patient", patientSchema);

module.exports = Patient;
