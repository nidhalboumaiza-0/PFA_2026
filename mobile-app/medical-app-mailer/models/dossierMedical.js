const mongoose = require("mongoose");

const dossierMedicalSchema = new mongoose.Schema(
  {
    patientId: {
      type: String,
      required: [
        true,
        "Un dossier médical doit appartenir à un patient",
      ],
      trim: true,
      index: true,
    },
    files: [
      {
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
          required: [true, "Le type du fichier est requis"],
        },
        size: {
          type: Number,
          required: [true, "La taille du fichier est requise"],
        },
        createdAt: {
          type: Date,
          default: Date.now,
        },
        description: {
          type: String,
          default: "",
        },
      },
    ],
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Index for faster queries
dossierMedicalSchema.index({ patientId: 1 });

const DossierMedical = mongoose.model(
  "DossierMedical",
  dossierMedicalSchema
);

module.exports = DossierMedical;
