const User = require("../models/userModel");
const Patient = require("../models/patientModel");
const Medecin = require("../models/medecinModel");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");

// Filter object to only allow certain fields to be updated
const filterObj = (obj, ...allowedFields) => {
  const newObj = {};
  Object.keys(obj).forEach((el) => {
    if (allowedFields.includes(el)) newObj[el] = obj[el];
  });
  return newObj;
};

// Get current user profile
exports.getMe = catchAsync(async (req, res, next) => {
  const user = await User.findById(req.user.id);

  if (!user) {
    return next(new AppError("Utilisateur non trouvé", 404));
  }

  res.status(200).json({
    status: "success",
    data: {
      user,
    },
  });
});

// Update current user profile
exports.updateMe = catchAsync(async (req, res, next) => {
  // 1) Create error if user tries to update password
  if (req.body.password || req.body.passwordConfirm) {
    return next(
      new AppError(
        "Cette route n'est pas pour les mises à jour de mot de passe. Veuillez utiliser /updateMyPassword.",
        400
      )
    );
  }

  // 2) Filter unwanted fields that should not be updated
  const filteredBody = filterObj(
    req.body,
    "name",
    "lastName",
    "phoneNumber",
    "dateOfBirth"
  );

  // Add role-specific fields to filteredBody
  if (req.user.role === "patient" && req.body.antecedent) {
    filteredBody.antecedent = req.body.antecedent;
  } else if (req.user.role === "medecin") {
    if (req.body.speciality)
      filteredBody.speciality = req.body.speciality;
    if (req.body.numLicence)
      filteredBody.numLicence = req.body.numLicence;
    if (req.body.appointmentDuration) {
      // Ensure appointmentDuration is a number and within reasonable limits
      const duration = parseInt(req.body.appointmentDuration);
      if (isNaN(duration) || duration < 5 || duration > 180) {
        return next(
          new AppError(
            "La durée de consultation doit être comprise entre 5 et 180 minutes",
            400
          )
        );
      }
      filteredBody.appointmentDuration = duration;
    }
  }

  // 3) Update user document
  const updatedUser = await User.findByIdAndUpdate(
    req.user.id,
    filteredBody,
    {
      new: true,
      runValidators: true,
    }
  );

  res.status(200).json({
    status: "success",
    data: {
      user: updatedUser,
    },
  });
});

// Deactivate current user account
exports.deactivateMe = catchAsync(async (req, res, next) => {
  await User.findByIdAndUpdate(req.user.id, { accountStatus: false });

  res.status(200).json({
    status: "success",
    message: "Votre compte a été désactivé avec succès",
  });
});

// Update doctor's working times
exports.updateWorkingTime = catchAsync(async (req, res, next) => {
  if (req.user.role !== "medecin") {
    return next(
      new AppError(
        "Cette fonctionnalité est réservée aux médecins",
        403
      )
    );
  }

  const { workingTime } = req.body;

  if (!workingTime || !Array.isArray(workingTime)) {
    return next(
      new AppError(
        "Veuillez fournir des horaires de travail valides",
        400
      )
    );
  }

  // Validate each working time entry
  for (const time of workingTime) {
    if (
      !time.day ||
      time.day < 0 ||
      time.day > 6 ||
      !time.start ||
      !time.end
    ) {
      return next(
        new AppError(
          "Format d'horaire de travail invalide. Chaque entrée doit avoir un jour (0-6), une heure de début et une heure de fin",
          400
        )
      );
    }
  }

  const doctor = await Medecin.findByIdAndUpdate(
    req.user.id,
    { workingTime },
    { new: true, runValidators: true }
  );

  res.status(200).json({
    status: "success",
    data: {
      user: doctor,
    },
  });
});

// Get all doctors
exports.getAllDoctors = catchAsync(async (req, res, next) => {
  const doctors = await Medecin.find({
    role: "medecin",
    accountStatus: true,
  });

  res.status(200).json({
    status: "success",
    results: doctors.length,
    data: {
      doctors,
    },
  });
});

// Get a specific doctor by ID
exports.getDoctor = catchAsync(async (req, res, next) => {
  const doctor = await Medecin.findOne({
    _id: req.params.id,
    role: "medecin",
    accountStatus: true,
  });

  if (!doctor) {
    return next(new AppError("Médecin non trouvé", 404));
  }

  res.status(200).json({
    status: "success",
    data: {
      doctor,
    },
  });
});

// Update OneSignal Player ID
exports.updateOneSignalPlayerId = catchAsync(
  async (req, res, next) => {
    const { oneSignalPlayerId } = req.body;

    if (!oneSignalPlayerId) {
      return next(
        new AppError("OneSignal Player ID is required", 400)
      );
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { oneSignalPlayerId },
      { new: true, runValidators: true }
    );

    if (!user) {
      return next(new AppError("No user found with that ID", 404));
    }

    res.status(200).json({
      status: "success",
      message: "OneSignal Player ID updated successfully",
      data: {
        oneSignalPlayerId: user.oneSignalPlayerId,
      },
    });
  }
);
