const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const userController = require("../controllers/userController");

// Auth routes
router.post("/signup", authController.signUp);
router.post("/verifyAccount", authController.verifyAccount);
router.post("/login", authController.login);
router.post("/forgotPassword", authController.forgotPassword);
router.post("/verifyResetCode", authController.verifyResetCode);
router.patch("/resetPassword", authController.resetPassword);
router.post("/refreshToken", authController.refreshToken);

// Protected routes
router.use(authController.protect);

// User profile routes
router.get("/me", userController.getMe);
router.patch("/updateMe", userController.updateMe);
router.patch("/updateMyPassword", authController.updatePassword);
router.patch("/deactivateMe", userController.deactivateMe);
router.patch(
  "/updateOneSignalPlayerId",
  userController.updateOneSignalPlayerId
);

// Doctor specific routes
router.patch(
  "/updateWorkingTime",
  authController.restrictTo("medecin"),
  userController.updateWorkingTime
);

// Admin routes
router.get("/doctors", userController.getAllDoctors);

router.get("/doctors/:id", userController.getDoctor);

module.exports = router;
