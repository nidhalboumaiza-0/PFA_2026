const express = require("express");
const specialityController = require("../controllers/specialityController");
const authController = require("../controllers/authController");

const router = express.Router();

// Public routes
router.get("/", specialityController.getAllSpecialities);
router.get("/:id", specialityController.getSpeciality);
router.get(
  "/:id/doctors",
  specialityController.getDoctorsBySpeciality
);

// Protect and restrict routes after this middleware
router.use(authController.protect);
router.use(authController.restrictTo("admin"));

// Admin only routes
router.post("/", specialityController.createSpeciality);
router.patch("/:id", specialityController.updateSpeciality);
router.delete("/:id", specialityController.deleteSpeciality);

module.exports = router;
