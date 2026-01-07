import express from 'express';
import { auth, adminAuth } from '../../../../shared/index.js';
import {
  getMessagingStats,
  getRecentActivity,
  getAllConversations
} from '../controllers/adminController.js';

const router = express.Router();

// All admin routes require authentication and admin role
router.use(auth, adminAuth);

// Get messaging statistics
router.get('/stats', getMessagingStats);

// Get recent messaging activity
router.get('/recent-activity', getRecentActivity);

// Get all conversations (admin oversight)
router.get('/conversations', getAllConversations);

export default router;
