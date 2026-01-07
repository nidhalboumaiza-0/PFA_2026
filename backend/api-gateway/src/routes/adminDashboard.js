import express from 'express';
import { authenticateToken, requireAdmin } from '../middleware/auth.js';
import {
  getDashboardStats,
  getQuickStats,
  getPlatformHealth,
  getRecentActivity
} from '../controllers/dashboardController.js';

const router = express.Router();

// All dashboard routes require authentication and admin role
router.use(authenticateToken, requireAdmin);

/**
 * @route   GET /api/v1/admin/dashboard/stats
 * @desc    Get comprehensive system-wide statistics
 * @access  Admin only
 */
router.get('/stats', getDashboardStats);

/**
 * @route   GET /api/v1/admin/dashboard/quick-stats
 * @desc    Get quick stats for dashboard header (faster response)
 * @access  Admin only
 */
router.get('/quick-stats', getQuickStats);

/**
 * @route   GET /api/v1/admin/dashboard/health
 * @desc    Get platform health status for all services
 * @access  Admin only
 */
router.get('/health', getPlatformHealth);

/**
 * @route   GET /api/v1/admin/dashboard/recent-activity
 * @desc    Get recent activity across all services
 * @access  Admin only
 */
router.get('/recent-activity', getRecentActivity);

export default router;
