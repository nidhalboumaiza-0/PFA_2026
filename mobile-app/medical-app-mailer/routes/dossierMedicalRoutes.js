const express = require("express");
const dossierMedicalController = require("../controllers/dossierMedicalController");
const upload = require("../utils/upload");
const authController = require("../controllers/authController");

const router = express.Router();

// Apply the protect middleware based on environment
// In development mode, we'll skip authentication to make testing easier
if (process.env.NODE_ENV !== "development") {
  // Protect all routes in production
  router.use(authController.protect);
  console.log("Authentication is ENABLED for dossier medical routes");
} else {
  console.log(
    "Development mode: Authentication is DISABLED for dossier medical routes"
  );
}

// Routes for a patient's medical record
router
  .route("/:patientId")
  .get(dossierMedicalController.getDossierMedical);

// Routes for adding files to a patient's medical record
router
  .route("/:patientId/files")
  .post(
    upload.uploadSingleMedicalFile,
    dossierMedicalController.addFileToDossier
  );

router
  .route("/:patientId/multiple-files")
  .post(
    upload.uploadMultipleMedicalFiles,
    dossierMedicalController.addFilesToDossier
  );

// Routes for managing individual files in a patient's medical record
router
  .route("/:patientId/files/:fileId")
  .patch(dossierMedicalController.updateFileDescription)
  .delete(dossierMedicalController.deleteFile);

module.exports = router;
