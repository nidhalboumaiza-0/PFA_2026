const mongoose = require("mongoose");

const fileSchema = new mongoose.Schema({
  filename: {
    type: String,
    required: [true, "Le nom du fichier est requis"],
  },
  originalName: {
    type: String,
    required: [true, "Le nom original du fichier est requis"],
  },
  path: {
    type: String,
    required: [true, "Le chemin du fichier est requis"],
  },
  mimetype: {
    type: String,
    required: [true, "Le type MIME est requis"],
  },
  size: {
    type: Number,
    required: [true, "La taille du fichier est requise"],
  },
  description: {
    type: String,
  },
  uploadedAt: {
    type: Date,
    default: Date.now,
  },
  uploadedBy: {
    type: mongoose.Schema.ObjectId,
    ref: "User",
  },
});

// Virtual properties for file type
fileSchema.virtual("isImage").get(function () {
  return this.mimetype.startsWith("image/");
});

fileSchema.virtual("isPdf").get(function () {
  return this.mimetype === "application/pdf";
});

fileSchema.virtual("fileType").get(function () {
  if (this.mimetype.startsWith("image/")) return "Image";
  if (this.mimetype === "application/pdf") return "PDF";
  return "Document";
});

fileSchema.virtual("displayName").get(function () {
  return this.originalName || this.filename;
});

const medicalRecordSchema = new mongoose.Schema(
  {
    patient: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "L'identifiant du patient est requis"],
    },
    title: {
      type: String,
      required: [true, "Le titre du dossier médical est requis"],
    },
    description: {
      type: String,
    },
    files: [fileSchema],
    category: {
      type: String,
      enum: [
        "Analyse",
        "Radiologie",
        "Consultation",
        "Ordonnance",
        "Autre",
      ],
      default: "Autre",
    },
    recordDate: {
      type: Date,
      default: Date.now,
    },
    createdBy: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Populate references when querying
medicalRecordSchema.pre(/^find/, function (next) {
  this.populate({
    path: "patient",
    select: "name lastName",
  }).populate({
    path: "createdBy",
    select: "name lastName role",
  });
  next();
});

const MedicalRecord = mongoose.model(
  "MedicalRecord",
  medicalRecordSchema
);

module.exports = MedicalRecord;
