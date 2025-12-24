import express from 'express';
import * as userController from '../controllers/userController.js';
import { validatePatientProfile, validateDoctorProfile } from '../validators/userValidator.js';
import { auth, adminAuth } from '../../../../shared/index.js';
import upload from '../config/multer.js';

const router = express.Router();

// Get current user profile
router.get('/me', auth, userController.getCurrentUser);

// Update profiles
router.put('/patient/profile', auth, validatePatientProfile, userController.updatePatientProfile);
router.put('/doctor/profile', auth, validateDoctorProfile, userController.updateDoctorProfile);

// Upload photo
router.post('/upload-photo', auth, upload.single('photo'), userController.uploadProfilePhoto);

// Update OneSignal Player ID
router.patch('/updateOneSignalPlayerId', auth, userController.updateOneSignalPlayerId);

// Public doctor endpoints
router.get('/doctors/search', userController.searchDoctors);
router.get('/doctors/nearby', userController.getNearbyDoctors);
router.get('/doctors/:doctorId', userController.getDoctorById);

// Admin endpoints
router.put('/admin/verify-doctor/:doctorId', auth, adminAuth, userController.verifyDoctor);

export default router;
