const Speciality = require("../models/specialityModel");
const Medecin = require("../models/medecinModel");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");

// Get all specialties
exports.getAllSpecialities = catchAsync(async (req, res, next) => {
  const specialities = await Speciality.find();

  res.status(200).json({
    status: "success",
    results: specialities.length,
    data: {
      specialities,
    },
  });
});

// Get a single specialty by ID
exports.getSpeciality = catchAsync(async (req, res, next) => {
  const speciality = await Speciality.findById(req.params.id);

  if (!speciality) {
    return next(new AppError("Spécialité non trouvée", 404));
  }

  res.status(200).json({
    status: "success",
    data: {
      speciality,
    },
  });
});

// Create a new specialty (admin only)
exports.createSpeciality = catchAsync(async (req, res, next) => {
  // Check if user is admin
  if (req.user.role !== "admin") {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à créer des spécialités",
        403
      )
    );
  }

  const { name, description, icon } = req.body;

  // Check if specialty already exists
  const existingSpeciality = await Speciality.findOne({ name });
  if (existingSpeciality) {
    return next(new AppError("Cette spécialité existe déjà", 400));
  }

  const speciality = await Speciality.create({
    name,
    description,
    icon,
  });

  res.status(201).json({
    status: "success",
    data: {
      speciality,
    },
  });
});

// Update a specialty (admin only)
exports.updateSpeciality = catchAsync(async (req, res, next) => {
  // Check if user is admin
  if (req.user.role !== "admin") {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à modifier des spécialités",
        403
      )
    );
  }

  const speciality = await Speciality.findByIdAndUpdate(
    req.params.id,
    req.body,
    {
      new: true,
      runValidators: true,
    }
  );

  if (!speciality) {
    return next(new AppError("Spécialité non trouvée", 404));
  }

  res.status(200).json({
    status: "success",
    data: {
      speciality,
    },
  });
});

// Delete a specialty (admin only)
exports.deleteSpeciality = catchAsync(async (req, res, next) => {
  // Check if user is admin
  if (req.user.role !== "admin") {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à supprimer des spécialités",
        403
      )
    );
  }

  // Check if any doctors are using this specialty
  const doctorsWithSpeciality = await Medecin.countDocuments({
    speciality: req.params.id,
  });

  if (doctorsWithSpeciality > 0) {
    return next(
      new AppError(
        `Cette spécialité est utilisée par ${doctorsWithSpeciality} médecin(s) et ne peut pas être supprimée`,
        400
      )
    );
  }

  const speciality = await Speciality.findByIdAndDelete(
    req.params.id
  );

  if (!speciality) {
    return next(new AppError("Spécialité non trouvée", 404));
  }

  res.status(204).json({
    status: "success",
    data: null,
  });
});

// Get doctors by specialty
exports.getDoctorsBySpeciality = catchAsync(
  async (req, res, next) => {
    const { id } = req.params;

    // Check if specialty exists
    const speciality = await Speciality.findById(id);
    if (!speciality) {
      return next(new AppError("Spécialité non trouvée", 404));
    }

    // Find doctors with this specialty
    const doctors = await Medecin.find({
      speciality: id,
      role: "medecin",
      accountStatus: true,
    }).select(
      "name lastName profilePicture averageRating numberOfRatings appointmentDuration"
    );

    res.status(200).json({
      status: "success",
      results: doctors.length,
      data: {
        speciality,
        doctors,
      },
    });
  }
);
