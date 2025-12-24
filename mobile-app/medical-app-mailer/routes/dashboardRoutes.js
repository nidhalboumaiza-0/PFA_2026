const express = require("express");
const dashboardController = require("../controllers/dashboardController");
const authController = require("../controllers/authController");

const router = express.Router();

// Protect all routes after this middleware - require login
router.use(authController.protect);

// Restrict to doctor role
router.use(authController.restrictTo("medecin", "admin"));

// Get upcoming appointments for a doctor
router.get(
  "/upcoming-appointments",
  dashboardController.getUpcomingAppointments
);
router.get(
  "/upcoming-appointments/:doctorId",
  dashboardController.getUpcomingAppointments
);

// Count appointments by status for a doctor
router.get(
  "/appointments-count",
  dashboardController.getAppointmentsCountByStatus
);
router.get(
  "/appointments-count/:doctorId",
  dashboardController.getAppointmentsCountByStatus
);

// Count total patients for a doctor
router.get(
  "/total-patients",
  dashboardController.getTotalPatientsCount
);
router.get(
  "/total-patients/:doctorId",
  dashboardController.getTotalPatientsCount
);

// Get complete dashboard statistics for a doctor
router.get("/stats", dashboardController.getDoctorDashboardStats);
router.get(
  "/stats/:doctorId",
  dashboardController.getDoctorDashboardStats
);

// Get doctor's patients with pagination
router.get("/patients", dashboardController.getDoctorPatients);
router.get(
  "/patients/:doctorId",
  dashboardController.getDoctorPatients
);

module.exports = router;
