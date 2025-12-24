const mongoose = require("mongoose");

const dashboardStatsSchema = new mongoose.Schema(
  {
    medecin: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: [true, "L'identifiant du médecin est requis"],
    },
    date: {
      type: Date,
      default: Date.now,
      required: true,
    },
    totalPatients: {
      type: Number,
      default: 0,
    },
    totalAppointments: {
      type: Number,
      default: 0,
    },
    pendingAppointments: {
      type: Number,
      default: 0,
    },
    completedAppointments: {
      type: Number,
      default: 0,
    },
    cancelledAppointments: {
      type: Number,
      default: 0,
    },
    upcomingAppointments: [
      {
        type: mongoose.Schema.ObjectId,
        ref: "Appointment",
      },
    ],
    revenue: {
      type: Number,
      default: 0,
    },
    patientDemographics: {
      ageGroups: {
        under18: { type: Number, default: 0 },
        age18to30: { type: Number, default: 0 },
        age31to45: { type: Number, default: 0 },
        age46to60: { type: Number, default: 0 },
        over60: { type: Number, default: 0 },
      },
      genderDistribution: {
        homme: { type: Number, default: 0 },
        femme: { type: Number, default: 0 },
      },
    },
    appointmentsByDay: {
      monday: { type: Number, default: 0 },
      tuesday: { type: Number, default: 0 },
      wednesday: { type: Number, default: 0 },
      thursday: { type: Number, default: 0 },
      friday: { type: Number, default: 0 },
      saturday: { type: Number, default: 0 },
      sunday: { type: Number, default: 0 },
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Compound index for medecin and date to ensure uniqueness
dashboardStatsSchema.index({ medecin: 1, date: 1 }, { unique: true });

// Populate references when querying
dashboardStatsSchema.pre(/^find/, function (next) {
  this.populate({
    path: "medecin",
    select: "name lastName speciality",
  }).populate({
    path: "upcomingAppointments",
    select: "startDate endDate patient status",
    options: { sort: { startDate: 1 }, limit: 5 },
  });
  next();
});

const DashboardStats = mongoose.model(
  "DashboardStats",
  dashboardStatsSchema
);

module.exports = DashboardStats;
