const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const appointmentController = require("../controllers/appointmentController");

// All routes are protected
router.use(authController.protect);

// Routes for both patients and doctors
router.post(
  "/getAvailableDoctors",
  appointmentController.getAvailableDoctors
);

// Patient routes
router.post(
  "/createAppointment",
  authController.restrictTo("patient"),
  appointmentController.createAppointment
);

router.get(
  "/myAppointments",
  authController.restrictTo("patient"),
  appointmentController.getMyAppointmentsPatient
);

router.patch(
  "/cancelAppointment/:id",
  authController.restrictTo("patient"),
  appointmentController.cancelAppointmentPatient
);

router.post(
  "/rateDoctor",
  authController.restrictTo("patient"),
  appointmentController.rateDoctor
);

// Doctor routes
router.get(
  "/doctorAppointments",
  authController.restrictTo("medecin"),
  appointmentController.getMyAppointmentsDoctor
);

router.post(
  "/doctorAppointmentsForDay",
  authController.restrictTo("medecin"),
  appointmentController.getDoctorAppointmentsForDay
);

router.patch(
  "/acceptAppointment/:id",
  authController.restrictTo("medecin"),
  appointmentController.acceptAppointment
);

router.patch(
  "/refuseAppointment/:id",
  authController.restrictTo("medecin"),
  appointmentController.refuseAppointment
);

module.exports = router;
