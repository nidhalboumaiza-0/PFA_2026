const express = require("express");
const medicalRecordController = require("../controllers/medicalRecordController");
const authController = require("../controllers/authController");
const uploadUtils = require("../utils/upload");

const router = express.Router();

// Protect all routes - require login
router.use(authController.protect);

// Get a patient's medical record
router.get(
  "/patient/:patientId",
  medicalRecordController.getMedicalRecord
);

// Get my medical record
router.get("/my-record", medicalRecordController.getMedicalRecord);

// Check if a patient has a medical record
router.get(
  "/has-record/:patientId",
  medicalRecordController.hasMedicalRecord
);

// Check if I have a medical record
router.get(
  "/has-my-record",
  medicalRecordController.hasMedicalRecord
);

// Add a file to a patient's medical record
router.post(
  "/patient/:patientId/files",
  uploadUtils.uploadSingleMedicalFile,
  medicalRecordController.addFileToMedicalRecord
);

// Add multiple files to a patient's medical record
router.post(
  "/patient/:patientId/multiple-files",
  uploadUtils.uploadMultipleMedicalFiles,
  medicalRecordController.addFilesToMedicalRecord
);

// Delete a file from a patient's medical record
router.delete(
  "/patient/:patientId/files/:fileId",
  medicalRecordController.deleteFile
);

// Update a file's description
router.patch(
  "/patient/:patientId/files/:fileId",
  medicalRecordController.updateFileDescription
);

module.exports = router;
 