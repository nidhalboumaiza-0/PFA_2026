const mongoose = require("mongoose");
const User = require("./userModel");

const ratingSchema = new mongoose.Schema(
  {
    patientId: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "L'identifiant du patient est requis"],
    },
    rating: {
      type: Number,
      required: [true, "La note est requise"],
      min: 1,
      max: 5,
    },
    comment: {
      type: String,
    },
    appointmentId: {
      type: mongoose.Schema.ObjectId,
      ref: "Appointment",
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

const medecinSchema = new mongoose.Schema({
  speciality: {
    type: mongoose.Schema.ObjectId,
    ref: "Speciality",
    required: [true, "Veuillez fournir votre spécialité !"],
  },
  numLicence: {
    type: String,
    default: "",
  },
  appointmentDuration: {
    type: Number,
    default: 30, // Default 30 minutes
    required: [true, "Veuillez fournir la durée de consultation !"],
  },
  workingTime: {
    type: [
      {
        day: Number,
        start: Date,
        end: Date,
      },
    ],
  },
  appointments: [
    {
      type: mongoose.Schema.ObjectId,
      ref: "Appointment",
    },
  ],
  ratings: [ratingSchema],
  totalPatients: {
    type: Number,
    default: 0,
  },
  education: {
    type: String,
  },
  experience: {
    type: Number, // Years of experience
    default: 0,
  },
  about: {
    type: String,
  },
  languages: {
    type: [String],
    default: ["Français"],
  },
  services: {
    type: [String],
  },
});

// Virtual property for average rating
medecinSchema.virtual("ratingAverage").get(function () {
  if (this.ratings && this.ratings.length > 0) {
    const sum = this.ratings.reduce(
      (total, rating) => total + rating.rating,
      0
    );
    return sum / this.ratings.length;
  }
  return 0;
});

// Virtual property for ratings count
medecinSchema.virtual("ratingsCount").get(function () {
  return this.ratings ? this.ratings.length : 0;
});

// Populate speciality when querying
medecinSchema.pre(/^find/, function (next) {
  this.populate({
    path: "speciality",
    select: "name",
  });
  next();
});

const Medecin = User.discriminator("medecin", medecinSchema);

module.exports = Medecin;
