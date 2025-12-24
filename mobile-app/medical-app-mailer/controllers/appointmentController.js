const Appointment = require("../models/appointmentModel");
const User = require("../models/userModel");
const Medecin = require("../models/medecinModel");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");

// Get available doctors in a specific area
exports.getAvailableDoctors = catchAsync(async (req, res, next) => {
  const { speciality, startDate, endDate, maxDistance } = req.body;

  if (!startDate || !endDate) {
    return next(
      new AppError(
        "Veuillez fournir les dates de début et de fin",
        400
      )
    );
  }

  const parsedStartDate = new Date(startDate);
  const parsedEndDate = new Date(endDate);

  if (isNaN(parsedStartDate) || isNaN(parsedEndDate)) {
    return next(new AppError("Format de date invalide", 400));
  }

  if (parsedStartDate < Date.now() || parsedEndDate < Date.now()) {
    return next(
      new AppError("Veuillez fournir une date future", 400)
    );
  }

  if (parsedStartDate >= parsedEndDate) {
    return next(
      new AppError(
        "La date de début doit être antérieure à la date de fin",
        400
      )
    );
  }

  // Find all appointments that overlap with the requested time range
  const overlappingAppointments = await Appointment.find({
    startDate: { $lte: parsedEndDate },
    endDate: { $gte: parsedStartDate },
    status: { $in: ["En attente", "Accepté"] },
  });

  // Get the IDs of doctors with overlapping appointments
  const busyDoctorIds = overlappingAppointments.map(
    (appointment) => appointment.medecin._id
  );

  // Build query to find available doctors
  let query = {
    role: "medecin",
    accountStatus: true,
  };

  // Add speciality filter if provided
  if (speciality) {
    query.speciality = speciality;
  }

  // Exclude doctors with overlapping appointments
  if (busyDoctorIds.length > 0) {
    query._id = { $nin: busyDoctorIds };
  }

  const availableDoctors = await Medecin.find(query);

  if (availableDoctors.length === 0) {
    return next(new AppError("Aucun médecin disponible trouvé", 404));
  }

  res.status(200).json({
    status: "success",
    results: availableDoctors.length,
    data: {
      doctors: availableDoctors,
    },
  });
});

// Create a new appointment
exports.createAppointment = catchAsync(async (req, res, next) => {
  const { startDate, serviceName, medecinId, motif, symptoms } =
    req.body;

  if (!startDate || !serviceName || !medecinId) {
    return next(
      new AppError(
        "Veuillez fournir toutes les informations nécessaires",
        400
      )
    );
  }

  const parsedStartDate = new Date(startDate);

  if (isNaN(parsedStartDate)) {
    return next(new AppError("Format de date invalide", 400));
  }

  if (parsedStartDate < Date.now()) {
    return next(
      new AppError("Veuillez fournir une date future", 400)
    );
  }

  // Check if doctor exists
  const doctor = await Medecin.findById(medecinId);
  if (!doctor) {
    return next(new AppError("Médecin non trouvé", 404));
  }

  // Calculate endDate based on doctor's appointmentDuration
  // The appointmentDuration is set in the doctor's profile (default is 30 minutes)
  const parsedEndDate = new Date(parsedStartDate);
  parsedEndDate.setMinutes(
    parsedEndDate.getMinutes() + doctor.appointmentDuration
  );

  // Log for debugging
  console.log(
    `Creating appointment with duration: ${doctor.appointmentDuration} minutes`
  );
  console.log(
    `Start time: ${parsedStartDate.toISOString()}, End time: ${parsedEndDate.toISOString()}`
  );

  // Check if doctor is available at the requested time
  const overlappingAppointments = await Appointment.find({
    medecin: medecinId,
    startDate: { $lte: parsedEndDate },
    endDate: { $gte: parsedStartDate },
    status: { $in: ["En attente", "Accepté"] },
  });

  if (overlappingAppointments.length > 0) {
    return next(
      new AppError("Le médecin n'est pas disponible à ce moment", 400)
    );
  }

  // Create appointment with calculated endDate
  const newAppointment = await Appointment.create({
    startDate: parsedStartDate,
    endDate: parsedEndDate,
    serviceName,
    patient: req.user.id,
    medecin: medecinId,
    status: "En attente",
    motif,
    symptoms,
  });

  res.status(201).json({
    status: "success",
    data: {
      appointment: newAppointment,
    },
  });
});

// Get patient's appointments
exports.getMyAppointmentsPatient = catchAsync(
  async (req, res, next) => {
    const appointments = await Appointment.find({
      patient: req.user.id,
    });

    res.status(200).json({
      status: "success",
      results: appointments.length,
      data: {
        appointments,
      },
    });
  }
);

// Cancel patient's appointment
exports.cancelAppointmentPatient = catchAsync(
  async (req, res, next) => {
    const appointment = await Appointment.findOne({
      _id: req.params.id,
      patient: req.user.id,
      status: { $in: ["En attente", "Accepté"] },
    });

    if (!appointment) {
      return next(
        new AppError("Rendez-vous non trouvé ou déjà annulé", 404)
      );
    }

    appointment.status = "Annulé";
    await appointment.save();

    res.status(200).json({
      status: "success",
      message: "Rendez-vous annulé avec succès",
      data: {
        appointment,
      },
    });
  }
);

// Rate a doctor after appointment
exports.rateDoctor = catchAsync(async (req, res, next) => {
  const { appointmentId, rating } = req.body;

  if (!appointmentId || !rating || rating < 1 || rating > 5) {
    return next(
      new AppError(
        "Veuillez fournir un identifiant de rendez-vous et une note valide (1-5)",
        400
      )
    );
  }

  const appointment = await Appointment.findOne({
    _id: appointmentId,
    patient: req.user.id,
    status: "Accepté",
  });

  if (!appointment) {
    return next(
      new AppError(
        "Rendez-vous non trouvé ou non éligible pour une évaluation",
        404
      )
    );
  }

  // Check if appointment has ended
  if (new Date(appointment.endDate) > new Date()) {
    return next(
      new AppError(
        "Vous ne pouvez évaluer qu'après la fin du rendez-vous",
        400
      )
    );
  }

  const doctor = await Medecin.findById(appointment.medecin);
  if (!doctor) {
    return next(new AppError("Médecin non trouvé", 404));
  }

  // Add rating to doctor's ratings array
  doctor.rating.push(rating);
  await doctor.save({ validateBeforeSave: false });

  res.status(200).json({
    status: "success",
    message: "Merci pour votre évaluation",
  });
});

// Get doctor's appointments
exports.getMyAppointmentsDoctor = catchAsync(
  async (req, res, next) => {
    const appointments = await Appointment.find({
      medecin: req.user.id,
    });

    res.status(200).json({
      status: "success",
      results: appointments.length,
      data: {
        appointments,
      },
    });
  }
);

// Get doctor's appointments for a specific day
exports.getDoctorAppointmentsForDay = catchAsync(
  async (req, res, next) => {
    const { date } = req.body;

    if (!date) {
      return next(new AppError("Veuillez fournir une date", 400));
    }

    const selectedDate = new Date(date);

    if (isNaN(selectedDate)) {
      return next(new AppError("Format de date invalide", 400));
    }

    // Set time to beginning of day
    const startOfDay = new Date(selectedDate);
    startOfDay.setHours(0, 0, 0, 0);

    // Set time to end of day
    const endOfDay = new Date(selectedDate);
    endOfDay.setHours(23, 59, 59, 999);

    const appointments = await Appointment.find({
      medecin: req.user.id,
      startDate: { $gte: startOfDay, $lte: endOfDay },
    });

    res.status(200).json({
      status: "success",
      results: appointments.length,
      data: {
        appointments,
      },
    });
  }
);

// Accept an appointment (doctor only)
exports.acceptAppointment = catchAsync(async (req, res, next) => {
  const appointment = await Appointment.findOne({
    _id: req.params.id,
    medecin: req.user.id,
    status: "En attente",
  });

  if (!appointment) {
    return next(
      new AppError("Rendez-vous non trouvé ou déjà traité", 404)
    );
  }

  appointment.status = "Accepté";
  await appointment.save();

  // Add appointment to doctor's appointments array
  const doctor = await Medecin.findById(req.user.id);
  doctor.appointments.push(appointment._id);
  await doctor.save({ validateBeforeSave: false });

  res.status(200).json({
    status: "success",
    message: "Rendez-vous accepté avec succès",
    data: {
      appointment,
    },
  });
});

// Refuse an appointment (doctor only)
exports.refuseAppointment = catchAsync(async (req, res, next) => {
  const appointment = await Appointment.findOne({
    _id: req.params.id,
    medecin: req.user.id,
    status: "En attente",
  });

  if (!appointment) {
    return next(
      new AppError("Rendez-vous non trouvé ou déjà traité", 404)
    );
  }

  appointment.status = "Refusé";
  await appointment.save();

  res.status(200).json({
    status: "success",
    message: "Rendez-vous refusé avec succès",
    data: {
      appointment,
    },
  });
});
