const MedicalRecord = require("../models/medicalRecordModel");
const User = require("../models/userModel");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");

// Get a patient's medical record
exports.getMedicalRecord = catchAsync(async (req, res, next) => {
  const patientId = req.params.patientId || req.user.id;

  // Check if user has permission to access this medical record
  if (
    patientId !== req.user.id &&
    req.user.role !== "medecin" &&
    req.user.role !== "admin"
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à accéder à ce dossier médical",
        403
      )
    );
  }

  // Check if patient exists
  const patient = await User.findOne({
    _id: patientId,
    role: "patient",
  });
  if (!patient) {
    return next(new AppError("Patient non trouvé", 404));
  }

  // Find or create medical record
  let medicalRecord = await MedicalRecord.findOne({
    patient: patientId,
  });

  if (!medicalRecord) {
    // Create an empty medical record if none exists
    medicalRecord = await MedicalRecord.create({
      patient: patientId,
      files: [],
    });
  }

  res.status(200).json({
    status: "success",
    data: {
      medicalRecord,
    },
  });
});

// Add a file to a patient's medical record
exports.addFileToMedicalRecord = catchAsync(
  async (req, res, next) => {
    const { patientId } = req.params;

    // Check if user has permission to modify this medical record
    if (
      req.user.role !== "medecin" &&
      req.user.role !== "admin" &&
      patientId !== req.user.id
    ) {
      return next(
        new AppError(
          "Vous n'êtes pas autorisé à modifier ce dossier médical",
          403
        )
      );
    }

    // Check if patient exists
    const patient = await User.findOne({
      _id: patientId,
      role: "patient",
    });
    if (!patient) {
      return next(new AppError("Patient non trouvé", 404));
    }

    // Check if file was uploaded
    if (!req.file) {
      return next(new AppError("Veuillez fournir un fichier", 400));
    }

    const { description } = req.body;

    // Find or create medical record
    let medicalRecord = await MedicalRecord.findOne({
      patient: patientId,
    });

    if (!medicalRecord) {
      medicalRecord = await MedicalRecord.create({
        patient: patientId,
        files: [],
      });
    }

    // Add new file
    const newFile = {
      filename: req.file.filename,
      originalName: req.file.originalname,
      path: req.file.path,
      mimetype: req.file.mimetype,
      size: req.file.size,
      description: description || "",
      uploadedBy: req.user.id,
      uploadedAt: Date.now(),
    };

    medicalRecord.files.push(newFile);
    await medicalRecord.save();

    res.status(201).json({
      status: "success",
      data: {
        medicalRecord,
      },
    });
  }
);

// Add multiple files to a patient's medical record
exports.addFilesToMedicalRecord = catchAsync(
  async (req, res, next) => {
    const { patientId } = req.params;

    // Check if user has permission to modify this medical record
    if (
      req.user.role !== "medecin" &&
      req.user.role !== "admin" &&
      patientId !== req.user.id
    ) {
      return next(
        new AppError(
          "Vous n'êtes pas autorisé à modifier ce dossier médical",
          403
        )
      );
    }

    // Check if patient exists
    const patient = await User.findOne({
      _id: patientId,
      role: "patient",
    });
    if (!patient) {
      return next(new AppError("Patient non trouvé", 404));
    }

    // Check if files were uploaded
    if (!req.files || req.files.length === 0) {
      return next(
        new AppError("Veuillez fournir au moins un fichier", 400)
      );
    }

    // Parse descriptions if provided
    let descriptions = {};
    if (req.body.descriptions) {
      try {
        descriptions = JSON.parse(req.body.descriptions);
      } catch (e) {
        return next(
          new AppError("Format de descriptions invalide", 400)
        );
      }
    }

    // Find or create medical record
    let medicalRecord = await MedicalRecord.findOne({
      patient: patientId,
    });

    if (!medicalRecord) {
      medicalRecord = await MedicalRecord.create({
        patient: patientId,
        files: [],
      });
    }

    // Add new files
    for (const file of req.files) {
      const newFile = {
        filename: file.filename,
        originalName: file.originalname,
        path: file.path,
        mimetype: file.mimetype,
        size: file.size,
        description: descriptions[file.originalname] || "",
        uploadedBy: req.user.id,
        uploadedAt: Date.now(),
      };

      medicalRecord.files.push(newFile);
    }

    await medicalRecord.save();

    res.status(201).json({
      status: "success",
      data: {
        medicalRecord,
      },
    });
  }
);

// Delete a file from a patient's medical record
exports.deleteFile = catchAsync(async (req, res, next) => {
  const { patientId, fileId } = req.params;

  // Check if user has permission to modify this medical record
  if (
    req.user.role !== "medecin" &&
    req.user.role !== "admin" &&
    patientId !== req.user.id
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à modifier ce dossier médical",
        403
      )
    );
  }

  // Find medical record
  const medicalRecord = await MedicalRecord.findOne({
    patient: patientId,
  });

  if (!medicalRecord) {
    return next(new AppError("Dossier médical non trouvé", 404));
  }

  // Find file index
  const fileIndex = medicalRecord.files.findIndex(
    (file) => file._id.toString() === fileId
  );

  if (fileIndex === -1) {
    return next(new AppError("Fichier non trouvé", 404));
  }

  // Remove file
  medicalRecord.files.splice(fileIndex, 1);
  await medicalRecord.save();

  res.status(200).json({
    status: "success",
    data: null,
  });
});

// Update a file's description
exports.updateFileDescription = catchAsync(async (req, res, next) => {
  const { patientId, fileId } = req.params;
  const { description } = req.body;

  // Check if user has permission to modify this medical record
  if (
    req.user.role !== "medecin" &&
    req.user.role !== "admin" &&
    patientId !== req.user.id
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à modifier ce dossier médical",
        403
      )
    );
  }

  // Find medical record
  const medicalRecord = await MedicalRecord.findOne({
    patient: patientId,
  });

  if (!medicalRecord) {
    return next(new AppError("Dossier médical non trouvé", 404));
  }

  // Find file
  const file = medicalRecord.files.id(fileId);

  if (!file) {
    return next(new AppError("Fichier non trouvé", 404));
  }

  // Update description
  file.description = description;
  await medicalRecord.save();

  res.status(200).json({
    status: "success",
    data: {
      file,
    },
  });
});

// Check if a patient has a medical record
exports.hasMedicalRecord = catchAsync(async (req, res, next) => {
  const patientId = req.params.patientId || req.user.id;

  // Check if user has permission to access this information
  if (
    patientId !== req.user.id &&
    req.user.role !== "medecin" &&
    req.user.role !== "admin"
  ) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à accéder à cette information",
        403
      )
    );
  }

  // Find medical record
  const medicalRecord = await MedicalRecord.findOne({
    patient: patientId,
  });

  const hasMedicalRecord = !!(
    medicalRecord && medicalRecord.files.length > 0
  );

  res.status(200).json({
    status: "success",
    data: {
      hasMedicalRecord,
    },
  });
});
