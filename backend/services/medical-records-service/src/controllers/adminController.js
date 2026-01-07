import Consultation from '../models/Consultation.js';
import Prescription from '../models/Prescription.js';
import { sendError, sendSuccess } from '../../../../shared/index.js';

/**
 * Get Admin Statistics for Medical Records
 * GET /api/v1/medical/admin/stats
 */
export const getAdminStats = async (req, res, next) => {
  try {
    // Get current date info for "this month" calculations
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);

    // Get total counts
    const [totalConsultations, totalPrescriptions] = await Promise.all([
      Consultation.countDocuments(),
      Prescription.countDocuments()
    ]);

    // Get this month's counts
    const [consultationsThisMonth, prescriptionsThisMonth] = await Promise.all([
      Consultation.countDocuments({
        createdAt: { $gte: startOfMonth, $lte: endOfMonth }
      }),
      Prescription.countDocuments({
        createdAt: { $gte: startOfMonth, $lte: endOfMonth }
      })
    ]);

    return sendSuccess(res, 200, 'Admin statistics retrieved successfully', {
      totalConsultations,
      totalPrescriptions,
      consultationsThisMonth,
      prescriptionsThisMonth
    });
  } catch (error) {
    console.error('Error getting admin stats:', error);
    next(error);
  }
};
