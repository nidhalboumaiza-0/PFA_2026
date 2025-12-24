const Prescription = require("../models/prescriptionModel");
const Appointment = require("../models/appointmentModel");
const User = require("../models/userModel");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");

// Create a new prescription
exports.createPrescription = catchAsync(async (req, res, next) => {
  const { appointmentId, medications, note, expiresAt } = req.body;

  // Check if appointment exists
  const appointment = await Appointment.findById(appointmentId);
  if (!appointment) {
    return next(new AppError("Rendez-vous non trouvé", 404));
  }

  // Check if prescription already exists for this appointment
  const existingPrescription = await Prescription.findOne({
    appointment: appointmentId,
  });
  if (existingPrescription) {
    return next(
      new AppError(
        "Une ordonnance existe déjà pour ce rendez-vous",
        400
      )
    );
  }

  // Verify that the doctor creating the prescription is the one who handled the appointment
  if (
    appointment.medecin.toString() !== req.user.id &&
    req.user.role !== "admin"
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à créer une ordonnance pour ce rendez-vous",
        403
      )
    );
  }

  // Create prescription
  const prescription = await Prescription.create({
    appointment: appointmentId,
    patient: appointment.patient,
    medecin: appointment.medecin,
    medications,
    note,
    expiresAt:
      expiresAt || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Default 30 days
    status: "active",
  });

  // Update appointment status to completed
  await Appointment.findByIdAndUpdate(appointmentId, {
    status: "completed",
  });

  res.status(201).json({
    status: "success",
    data: {
      prescription,
    },
  });
});

// Edit an existing prescription
exports.editPrescription = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const { medications, note, expiresAt } = req.body;

  // Find the prescription
  const prescription = await Prescription.findById(id);
  if (!prescription) {
    return next(new AppError("Ordonnance non trouvée", 404));
  }

  // Check if the doctor editing is the one who created it
  if (
    prescription.medecin._id.toString() !== req.user.id &&
    req.user.role !== "admin"
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à modifier cette ordonnance",
        403
      )
    );
  }

  // Check if the prescription is within the 12-hour edit window
  const now = new Date();
  const createdAt = new Date(prescription.createdAt);
  const hoursDifference = Math.abs(now - createdAt) / 36e5; // Convert to hours

  if (hoursDifference >= 12) {
    return next(
      new AppError(
        "L'ordonnance ne peut plus être modifiée après 12 heures",
        400
      )
    );
  }

  // Update prescription
  const updatedPrescription = await Prescription.findByIdAndUpdate(
    id,
    { medications, note, expiresAt },
    { new: true, runValidators: true }
  );

  res.status(200).json({
    status: "success",
    data: {
      prescription: updatedPrescription,
    },
  });
});

// Get all prescriptions for a patient
exports.getPatientPrescriptions = catchAsync(
  async (req, res, next) => {
    const patientId = req.params.patientId || req.user.id;

    // Check if the user has permission to access these prescriptions
    if (
      patientId !== req.user.id &&
      req.user.role !== "medecin" &&
      req.user.role !== "admin"
    ) {
      return next(
        new AppError(
          "Vous n'êtes pas autorisé à accéder à ces ordonnances",
          403
        )
      );
    }

    const prescriptions = await Prescription.find({
      patient: patientId,
    })
      .sort({ createdAt: -1 })
      .populate({
        path: "medecin",
        select: "name lastName speciality",
      })
      .populate({
        path: "appointment",
        select: "startDate",
      });

    res.status(200).json({
      status: "success",
      results: prescriptions.length,
      data: {
        prescriptions,
      },
    });
  }
);

// Get all prescriptions created by a doctor
exports.getDoctorPrescriptions = catchAsync(
  async (req, res, next) => {
    const doctorId = req.params.doctorId || req.user.id;

    // Check if the user has permission to access these prescriptions
    if (doctorId !== req.user.id && req.user.role !== "admin") {
      return next(
        new AppError(
          "Vous n'êtes pas autorisé à accéder à ces ordonnances",
          403
        )
      );
    }

    const prescriptions = await Prescription.find({
      medecin: doctorId,
    })
      .sort({ createdAt: -1 })
      .populate({
        path: "patient",
        select: "name lastName",
      })
      .populate({
        path: "appointment",
        select: "startDate",
      });

    res.status(200).json({
      status: "success",
      results: prescriptions.length,
      data: {
        prescriptions,
      },
    });
  }
);

// Get a specific prescription by ID
exports.getPrescriptionById = catchAsync(async (req, res, next) => {
  const { id } = req.params;

  const prescription = await Prescription.findById(id)
    .populate({
      path: "patient",
      select: "name lastName email phoneNumber",
    })
    .populate({
      path: "medecin",
      select: "name lastName speciality",
    })
    .populate({
      path: "appointment",
      select: "startDate endDate",
    });

  if (!prescription) {
    return next(new AppError("Ordonnance non trouvée", 404));
  }

  // Check if the user has permission to access this prescription
  const isPatient =
    prescription.patient._id.toString() === req.user.id;
  const isDoctor =
    prescription.medecin._id.toString() === req.user.id;

  if (!isPatient && !isDoctor && req.user.role !== "admin") {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à accéder à cette ordonnance",
        403
      )
    );
  }

  res.status(200).json({
    status: "success",
    data: {
      prescription,
    },
  });
});

// Get prescription by appointment ID
exports.getPrescriptionByAppointmentId = catchAsync(
  async (req, res, next) => {
    const { appointmentId } = req.params;

    // Check if appointment exists
    const appointment = await Appointment.findById(appointmentId);
    if (!appointment) {
      return next(new AppError("Rendez-vous non trouvé", 404));
    }

    // Check if the user has permission to access this appointment's prescription
    const isPatient = appointment.patient.toString() === req.user.id;
    const isDoctor = appointment.medecin.toString() === req.user.id;

    if (!isPatient && !isDoctor && req.user.role !== "admin") {
      return next(
        new AppError(
          "Vous n'êtes pas autorisé à accéder à cette ordonnance",
          403
        )
      );
    }

    const prescription = await Prescription.findOne({
      appointment: appointmentId,
    })
      .populate({
        path: "patient",
        select: "name lastName",
      })
      .populate({
        path: "medecin",
        select: "name lastName speciality",
      });

    if (!prescription) {
      return res.status(200).json({
        status: "success",
        data: {
          prescription: null,
        },
      });
    }

    res.status(200).json({
      status: "success",
      data: {
        prescription,
      },
    });
  }
);

// Update a prescription (for status changes, etc.)
exports.updatePrescription = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const { status } = req.body;

  const prescription = await Prescription.findById(id);

  if (!prescription) {
    return next(new AppError("Ordonnance non trouvée", 404));
  }

  // Check if the user has permission to update this prescription
  if (
    prescription.medecin._id.toString() !== req.user.id &&
    req.user.role !== "admin"
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à modifier cette ordonnance",
        403
      )
    );
  }

  // Only allow updating certain fields
  const updatedPrescription = await Prescription.findByIdAndUpdate(
    id,
    { status },
    { new: true, runValidators: true }
  );

  res.status(200).json({
    status: "success",
    data: {
      prescription: updatedPrescription,
    },
  });
});
