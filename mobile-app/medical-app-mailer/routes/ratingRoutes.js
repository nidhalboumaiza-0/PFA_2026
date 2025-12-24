const express = require("express");
const ratingController = require("../controllers/ratingController");
const authController = require("../controllers/authController");

const router = express.Router();

// Public route to get doctor ratings
router.get("/doctor/:doctorId", ratingController.getDoctorRatings);

// Public route to get doctor average rating
router.get(
  "/doctor/:doctorId/average",
  ratingController.getDoctorAverageRating
);

// Protect all routes after this middleware - require login
router.use(authController.protect);

// Submit a rating for a doctor (patients only)
router.post(
  "/",
  authController.restrictTo("patient"),
  ratingController.submitDoctorRating
);

// Check if patient has already rated a specific appointment
router.get(
  "/check-rated/:rendezVousId",
  authController.restrictTo("patient"),
  ratingController.hasPatientRatedAppointment
);

module.exports = router;
