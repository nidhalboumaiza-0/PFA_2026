const mongoose = require("mongoose");
const User = require("../models/userModel");
const Medecin = require("../models/medecinModel");
const Appointment = require("../models/appointmentModel");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");

// Create a schema for doctor ratings
const doctorRatingSchema = new mongoose.Schema(
  {
    doctorId: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "L'identifiant du médecin est requis"],
    },
    patientId: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "L'identifiant du patient est requis"],
    },
    rendezVousId: {
      type: mongoose.Schema.ObjectId,
      ref: "Appointment",
      required: [true, "L'identifiant du rendez-vous est requis"],
    },
    rating: {
      type: Number,
      required: [true, "La note est requise"],
      min: 1,
      max: 5,
    },
    comment: {
      type: String,
      trim: true,
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

// Create a compound index to ensure a patient can only rate a specific appointment once
doctorRatingSchema.index(
  { patientId: 1, rendezVousId: 1 },
  { unique: true }
);

// Pre-find middleware to populate references
doctorRatingSchema.pre(/^find/, function (next) {
  this.populate({
    path: "patientId",
    select: "name lastName profilePicture",
  });
  next();
});

// Create the model if it doesn't exist
const DoctorRating =
  mongoose.models.DoctorRating ||
  mongoose.model("DoctorRating", doctorRatingSchema);

// Submit a rating for a doctor
exports.submitDoctorRating = catchAsync(async (req, res, next) => {
  const { doctorId, rendezVousId, rating, comment } = req.body;
  const patientId = req.user.id;

  // Verify doctor exists
  const doctor = await User.findOne({
    _id: doctorId,
    role: "medecin",
  });
  if (!doctor) {
    return next(new AppError("Médecin non trouvé", 404));
  }

  // Verify appointment exists and belongs to this patient and doctor
  const appointment = await Appointment.findOne({
    _id: rendezVousId,
    patient: patientId,
    medecin: doctorId,
    status: "completed", // Only allow rating completed appointments
  });

  if (!appointment) {
    return next(
      new AppError(
        "Rendez-vous non trouvé ou non éligible pour une évaluation",
        404
      )
    );
  }

  // Check if patient has already rated this appointment
  const existingRating = await DoctorRating.findOne({
    patientId,
    rendezVousId,
  });

  if (existingRating) {
    return next(
      new AppError("Vous avez déjà évalué ce rendez-vous", 400)
    );
  }

  // Create the rating
  const newRating = await DoctorRating.create({
    doctorId,
    patientId,
    rendezVousId,
    rating,
    comment,
  });

  // Update doctor's average rating
  await updateDoctorAverageRating(doctorId);

  res.status(201).json({
    status: "success",
    data: {
      rating: newRating,
    },
  });
});

// Get all ratings for a specific doctor
exports.getDoctorRatings = catchAsync(async (req, res, next) => {
  const { doctorId } = req.params;

  // Verify doctor exists
  const doctor = await User.findOne({
    _id: doctorId,
    role: "medecin",
  });
  if (!doctor) {
    return next(new AppError("Médecin non trouvé", 404));
  }

  const ratings = await DoctorRating.find({ doctorId }).sort({
    createdAt: -1,
  });

  res.status(200).json({
    status: "success",
    results: ratings.length,
    data: {
      ratings,
    },
  });
});

// Get average rating for a doctor
exports.getDoctorAverageRating = catchAsync(
  async (req, res, next) => {
    const { doctorId } = req.params;

    // Verify doctor exists
    const doctor = await User.findOne({
      _id: doctorId,
      role: "medecin",
    });
    if (!doctor) {
      return next(new AppError("Médecin non trouvé", 404));
    }

    const result = await DoctorRating.aggregate([
      {
        $match: { doctorId: mongoose.Types.ObjectId(doctorId) },
      },
      {
        $group: {
          _id: "$doctorId",
          averageRating: { $avg: "$rating" },
          numberOfRatings: { $sum: 1 },
        },
      },
    ]);

    const averageRating =
      result.length > 0 ? result[0].averageRating : 0;
    const numberOfRatings =
      result.length > 0 ? result[0].numberOfRatings : 0;

    res.status(200).json({
      status: "success",
      data: {
        averageRating,
        numberOfRatings,
      },
    });
  }
);

// Check if patient has already rated a specific appointment
exports.hasPatientRatedAppointment = catchAsync(
  async (req, res, next) => {
    const { rendezVousId } = req.params;
    const patientId = req.user.id;

    const existingRating = await DoctorRating.findOne({
      patientId,
      rendezVousId,
    });

    res.status(200).json({
      status: "success",
      data: {
        hasRated: !!existingRating,
      },
    });
  }
);

// Helper function to update a doctor's average rating
const updateDoctorAverageRating = async (doctorId) => {
  const result = await DoctorRating.aggregate([
    {
      $match: { doctorId: mongoose.Types.ObjectId(doctorId) },
    },
    {
      $group: {
        _id: "$doctorId",
        averageRating: { $avg: "$rating" },
        numberOfRatings: { $sum: 1 },
      },
    },
  ]);

  if (result.length > 0) {
    await Medecin.findByIdAndUpdate(doctorId, {
      averageRating: result[0].averageRating,
      numberOfRatings: result[0].numberOfRatings,
    });
  }
};
