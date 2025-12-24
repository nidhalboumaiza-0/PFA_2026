const express = require("express");
const prescriptionController = require("../controllers/prescriptionController");
const authController = require("../controllers/authController");

const router = express.Router();

// Protect all routes after this middleware - require login
router.use(authController.protect);

// Create a new prescription (doctors only)
router.post(
  "/",
  authController.restrictTo("medecin", "admin"),
  prescriptionController.createPrescription
);

// Get my prescriptions (as a patient)
router.get(
  "/my-prescriptions",
  authController.restrictTo("patient"),
  prescriptionController.getPatientPrescriptions
);

// Get prescriptions I've created (as a doctor)
router.get(
  "/my-created-prescriptions",
  authController.restrictTo("medecin"),
  prescriptionController.getDoctorPrescriptions
);

// Get prescription by appointment ID - specific route before generic ID route
router.get(
  "/appointment/:appointmentId",
  prescriptionController.getPrescriptionByAppointmentId
);

// Get all prescriptions for a patient
router.get(
  "/patient/:patientId",
  prescriptionController.getPatientPrescriptions
);

// Get all prescriptions created by a doctor
router.get(
  "/doctor/:doctorId",
  prescriptionController.getDoctorPrescriptions
);

// Update a prescription status (doctors only)
router.patch(
  "/status/:id",
  authController.restrictTo("medecin", "admin"),
  prescriptionController.updatePrescription
);

// Edit an existing prescription (doctors only)
router.patch(
  "/:id",
  authController.restrictTo("medecin", "admin"),
  prescriptionController.editPrescription
);

// Get a specific prescription by ID - generic route should come last
router.get("/:id", prescriptionController.getPrescriptionById);

module.exports = router;
 