import express from 'express';
import * as adminController from '../controllers/adminController.js';
import { auth, adminAuth } from '../../../../shared/index.js';

const router = express.Router();

// All admin routes require authentication + admin role
router.use(auth, adminAuth);

// User Management Routes
router.get('/users', adminController.getAllUsers);
router.get('/users/:id', adminController.getUserById);
router.put('/users/:id/status', adminController.updateUserStatus);
router.delete('/users/:id', adminController.deleteUser);

// Doctor Verification
router.put('/doctors/:id/verify', adminController.verifyDoctor);

// Statistics & Dashboard
router.get('/stats', adminController.getUserStats);
router.get('/recent-activity', adminController.getRecentActivity);

export default router;
