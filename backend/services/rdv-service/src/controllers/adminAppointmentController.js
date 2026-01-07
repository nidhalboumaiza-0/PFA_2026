import Appointment from '../models/Appointment.js';
import TimeSlot from '../models/TimeSlot.js';
import { mongoose, kafkaProducer, TOPICS, createEvent } from '../../../../shared/index.js';
import { getIO } from '../socket/index.js';
import {
  fetchDoctorProfile,
  fetchPatientProfile,
  normalizeDateToStartOfDay,
  normalizeDateToEndOfDay
} from '../utils/appointmentHelpers.js';

/**
 * Get all appointments with pagination and filters
 * GET /api/v1/appointments/admin/appointments
 */
export const getAllAppointments = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      doctorId,
      patientId,
      dateFrom,
      dateTo,
      search,
      sortBy = 'appointmentDate',
      sortOrder = 'desc'
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOptions = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    // Build query
    const query = {};

    if (status && status !== 'all') {
      query.status = status;
    }

    if (doctorId) {
      query.doctorId = new mongoose.Types.ObjectId(doctorId);
    }

    if (patientId) {
      query.patientId = new mongoose.Types.ObjectId(patientId);
    }

    if (dateFrom || dateTo) {
      query.appointmentDate = {};
      if (dateFrom) {
        query.appointmentDate.$gte = normalizeDateToStartOfDay(dateFrom);
      }
      if (dateTo) {
        query.appointmentDate.$lte = normalizeDateToEndOfDay(dateTo);
      }
    }

    // Execute query
    const [appointments, total] = await Promise.all([
      Appointment.find(query)
        .sort(sortOptions)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Appointment.countDocuments(query)
    ]);

    // Fetch doctor and patient profiles for each appointment
    const enrichedAppointments = await Promise.all(
      appointments.map(async (apt) => {
        const [doctor, patient] = await Promise.all([
          fetchDoctorProfile(apt.doctorId.toString()).catch(() => null),
          fetchPatientProfile(apt.patientId.toString()).catch(() => null)
        ]);

        return {
          ...apt,
          doctor: doctor ? {
            _id: doctor._id,
            firstName: doctor.firstName,
            lastName: doctor.lastName,
            specialty: doctor.specialty,
            profilePhoto: doctor.profilePhoto
          } : null,
          patient: patient ? {
            _id: patient._id,
            firstName: patient.firstName,
            lastName: patient.lastName,
            profilePhoto: patient.profilePhoto
          } : null
        };
      })
    );

    res.json({
      appointments: enrichedAppointments,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('[AdminAppointmentController.getAllAppointments] Error:', error);
    res.status(500).json({ message: 'Failed to fetch appointments', error: error.message });
  }
};

/**
 * Get appointment by ID with full details
 * GET /api/v1/appointments/admin/appointments/:id
 */
export const getAppointmentById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid appointment ID' });
    }

    const appointment = await Appointment.findById(id).lean();

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found' });
    }

    // Fetch full doctor and patient profiles
    const [doctor, patient] = await Promise.all([
      fetchDoctorProfile(appointment.doctorId.toString()).catch(() => null),
      fetchPatientProfile(appointment.patientId.toString()).catch(() => null)
    ]);

    res.json({
      appointment: {
        ...appointment,
        doctor,
        patient
      }
    });

  } catch (error) {
    console.error('[AdminAppointmentController.getAppointmentById] Error:', error);
    res.status(500).json({ message: 'Failed to fetch appointment', error: error.message });
  }
};

/**
 * Update appointment status (admin override)
 * PUT /api/v1/appointments/admin/appointments/:id/status
 */
export const updateAppointmentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, reason, notes } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid appointment ID' });
    }

    const validStatuses = ['pending', 'confirmed', 'rejected', 'cancelled', 'completed', 'no-show'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        message: 'Invalid status', 
        validStatuses 
      });
    }

    const updateData = {
      status,
      adminNotes: notes,
      adminUpdatedAt: new Date(),
      adminUpdatedBy: req.user.id
    };

    // Add status-specific fields
    if (status === 'cancelled') {
      updateData.cancellationReason = reason || 'Cancelled by admin';
      updateData.cancelledBy = 'admin';
      updateData.cancelledAt = new Date();
    } else if (status === 'rejected') {
      updateData.rejectionReason = reason || 'Rejected by admin';
      updateData.rejectedAt = new Date();
    } else if (status === 'confirmed') {
      updateData.confirmedAt = new Date();
    } else if (status === 'completed') {
      updateData.completedAt = new Date();
    }

    const appointment = await Appointment.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    ).lean();

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found' });
    }

    // Fetch profiles for response
    const [doctor, patient] = await Promise.all([
      fetchDoctorProfile(appointment.doctorId.toString()).catch(() => null),
      fetchPatientProfile(appointment.patientId.toString()).catch(() => null)
    ]);

    const enrichedAppointment = {
      ...appointment,
      doctor: doctor ? {
        _id: doctor._id,
        firstName: doctor.firstName,
        lastName: doctor.lastName,
        specialty: doctor.specialty,
        profilePhoto: doctor.profilePhoto
      } : null,
      patient: patient ? {
        _id: patient._id,
        firstName: patient.firstName,
        lastName: patient.lastName,
        profilePhoto: patient.profilePhoto
      } : null
    };

    // Emit real-time update
    const io = getIO();
    if (io) {
      io.to('admin_appointments').emit('appointment_status_changed', {
        appointmentId: id,
        status,
        reason,
        updatedBy: 'admin',
        updatedAt: new Date().toISOString(),
        appointment: enrichedAppointment
      });
    }

    // Publish Kafka event
    try {
      await kafkaProducer.sendEvent(
        TOPICS.RDV.APPOINTMENT_UPDATED || 'rdv.appointment.updated',
        createEvent('appointment.admin_status_changed', {
          appointmentId: id,
          status,
          reason,
          adminId: req.user.id,
          timestamp: new Date().toISOString()
        })
      );
    } catch (kafkaError) {
      console.error('[AdminAppointmentController.updateAppointmentStatus] Kafka error:', kafkaError);
    }

    res.json({
      message: `Appointment status updated to ${status}`,
      appointment: enrichedAppointment
    });

  } catch (error) {
    console.error('[AdminAppointmentController.updateAppointmentStatus] Error:', error);
    res.status(500).json({ message: 'Failed to update appointment status', error: error.message });
  }
};

/**
 * Reschedule appointment (admin override)
 * PUT /api/v1/appointments/admin/appointments/:id/reschedule
 */
export const rescheduleAppointment = async (req, res) => {
  try {
    const { id } = req.params;
    const { newDate, newTime, reason } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid appointment ID' });
    }

    if (!newDate || !newTime) {
      return res.status(400).json({ message: 'New date and time are required' });
    }

    const appointment = await Appointment.findById(id);

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found' });
    }

    // Store previous date/time
    const previousDate = appointment.appointmentDate;
    const previousTime = appointment.appointmentTime;

    // Update appointment
    appointment.previousDate = previousDate;
    appointment.previousTime = previousTime;
    appointment.appointmentDate = normalizeDateToStartOfDay(newDate);
    appointment.appointmentTime = newTime;
    appointment.isRescheduled = true;
    appointment.rescheduledBy = 'admin';
    appointment.rescheduledAt = new Date();
    appointment.rescheduleReason = reason || 'Rescheduled by admin';
    appointment.rescheduleCount = (appointment.rescheduleCount || 0) + 1;
    appointment.status = 'confirmed'; // Auto-confirm admin reschedules

    await appointment.save();

    // Fetch profiles
    const [doctor, patient] = await Promise.all([
      fetchDoctorProfile(appointment.doctorId.toString()).catch(() => null),
      fetchPatientProfile(appointment.patientId.toString()).catch(() => null)
    ]);

    const enrichedAppointment = {
      ...appointment.toObject(),
      doctor: doctor ? {
        _id: doctor._id,
        firstName: doctor.firstName,
        lastName: doctor.lastName,
        specialty: doctor.specialty,
        profilePhoto: doctor.profilePhoto
      } : null,
      patient: patient ? {
        _id: patient._id,
        firstName: patient.firstName,
        lastName: patient.lastName,
        profilePhoto: patient.profilePhoto
      } : null
    };

    // Emit real-time update
    const io = getIO();
    if (io) {
      io.to('admin_appointments').emit('appointment_rescheduled', {
        appointmentId: id,
        previousDate,
        previousTime,
        newDate: appointment.appointmentDate,
        newTime: appointment.appointmentTime,
        rescheduledBy: 'admin',
        updatedAt: new Date().toISOString(),
        appointment: enrichedAppointment
      });
    }

    // Publish Kafka event
    try {
      await kafkaProducer.sendEvent(
        TOPICS.RDV.APPOINTMENT_RESCHEDULED || 'rdv.appointment.rescheduled',
        createEvent('appointment.admin_rescheduled', {
          appointmentId: id,
          previousDate,
          previousTime,
          newDate: appointment.appointmentDate,
          newTime: appointment.appointmentTime,
          adminId: req.user.id,
          timestamp: new Date().toISOString()
        })
      );
    } catch (kafkaError) {
      console.error('[AdminAppointmentController.rescheduleAppointment] Kafka error:', kafkaError);
    }

    res.json({
      message: 'Appointment rescheduled successfully',
      appointment: enrichedAppointment
    });

  } catch (error) {
    console.error('[AdminAppointmentController.rescheduleAppointment] Error:', error);
    res.status(500).json({ message: 'Failed to reschedule appointment', error: error.message });
  }
};

/**
 * Delete appointment (admin only)
 * DELETE /api/v1/appointments/admin/appointments/:id
 */
export const deleteAppointment = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason, hardDelete = false } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid appointment ID' });
    }

    let appointment;

    if (hardDelete) {
      // Permanent delete
      appointment = await Appointment.findByIdAndDelete(id).lean();
    } else {
      // Soft delete - mark as cancelled
      appointment = await Appointment.findByIdAndUpdate(
        id,
        {
          status: 'cancelled',
          cancellationReason: reason || 'Deleted by admin',
          cancelledBy: 'admin',
          cancelledAt: new Date(),
          isDeleted: true,
          deletedAt: new Date(),
          deletedBy: req.user.id
        },
        { new: true }
      ).lean();
    }

    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found' });
    }

    // Emit real-time update
    const io = getIO();
    if (io) {
      io.to('admin_appointments').emit('appointment_deleted', {
        appointmentId: id,
        hardDelete,
        deletedAt: new Date().toISOString()
      });
    }

    // Publish Kafka event
    try {
      await kafkaProducer.sendEvent(
        TOPICS.RDV.APPOINTMENT_CANCELLED || 'rdv.appointment.cancelled',
        createEvent('appointment.admin_deleted', {
          appointmentId: id,
          hardDelete,
          reason,
          adminId: req.user.id,
          timestamp: new Date().toISOString()
        })
      );
    } catch (kafkaError) {
      console.error('[AdminAppointmentController.deleteAppointment] Kafka error:', kafkaError);
    }

    res.json({
      message: `Appointment ${hardDelete ? 'permanently deleted' : 'deleted'} successfully`,
      appointmentId: id
    });

  } catch (error) {
    console.error('[AdminAppointmentController.deleteAppointment] Error:', error);
    res.status(500).json({ message: 'Failed to delete appointment', error: error.message });
  }
};

/**
 * Get appointment statistics for admin dashboard
 * GET /api/v1/appointments/admin/stats
 */
export const getAppointmentStats = async (req, res) => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const thisWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);

    const [
      totalAppointments,
      pendingAppointments,
      confirmedAppointments,
      completedAppointments,
      cancelledAppointments,
      rejectedAppointments,
      noShowAppointments,
      todayAppointments,
      upcomingAppointments,
      thisWeekAppointments,
      thisMonthAppointments
    ] = await Promise.all([
      Appointment.countDocuments(),
      Appointment.countDocuments({ status: 'pending' }),
      Appointment.countDocuments({ status: 'confirmed' }),
      Appointment.countDocuments({ status: 'completed' }),
      Appointment.countDocuments({ status: 'cancelled' }),
      Appointment.countDocuments({ status: 'rejected' }),
      Appointment.countDocuments({ status: 'no-show' }),
      Appointment.countDocuments({
        appointmentDate: { $gte: today, $lt: tomorrow }
      }),
      Appointment.countDocuments({
        appointmentDate: { $gte: today },
        status: { $in: ['pending', 'confirmed'] }
      }),
      Appointment.countDocuments({
        createdAt: { $gte: thisWeek }
      }),
      Appointment.countDocuments({
        createdAt: { $gte: thisMonth }
      })
    ]);

    // Get appointments by status for pie chart
    const statusDistribution = await Appointment.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } }
    ]);

    // Get appointment trend (last 30 days)
    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);

    const appointmentTrend = await Appointment.aggregate([
      {
        $match: {
          createdAt: { $gte: thirtyDaysAgo }
        }
      },
      {
        $group: {
          _id: {
            date: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            status: '$status'
          },
          count: { $sum: 1 }
        }
      },
      {
        $group: {
          _id: '$_id.date',
          statuses: {
            $push: {
              status: '$_id.status',
              count: '$count'
            }
          },
          total: { $sum: '$count' }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // Get top doctors by appointments
    const topDoctors = await Appointment.aggregate([
      {
        $group: {
          _id: '$doctorId',
          appointmentCount: { $sum: 1 },
          completedCount: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          }
        }
      },
      { $sort: { appointmentCount: -1 } },
      { $limit: 10 }
    ]);

    // Fetch doctor profiles for top doctors
    const topDoctorsEnriched = await Promise.all(
      topDoctors.map(async (doc) => {
        const doctor = await fetchDoctorProfile(doc._id.toString()).catch(() => null);
        return {
          ...doc,
          doctor: doctor ? {
            _id: doctor._id,
            firstName: doctor.firstName,
            lastName: doctor.lastName,
            specialty: doctor.specialty,
            profilePhoto: doctor.profilePhoto
          } : null
        };
      })
    );

    // Get busiest hours
    const busiestHours = await Appointment.aggregate([
      {
        $group: {
          _id: '$appointmentTime',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    // Calculate completion rate
    const totalResolved = completedAppointments + cancelledAppointments + rejectedAppointments + noShowAppointments;
    const completionRate = totalResolved > 0 
      ? ((completedAppointments / totalResolved) * 100).toFixed(1) 
      : 0;

    const stats = {
      overview: {
        total: totalAppointments,
        pending: pendingAppointments,
        confirmed: confirmedAppointments,
        completed: completedAppointments,
        cancelled: cancelledAppointments,
        rejected: rejectedAppointments,
        noShow: noShowAppointments,
        completionRate
      },
      today: {
        total: todayAppointments,
        upcoming: upcomingAppointments
      },
      period: {
        thisWeek: thisWeekAppointments,
        thisMonth: thisMonthAppointments
      },
      statusDistribution: statusDistribution.map(s => ({
        status: s._id,
        count: s.count
      })),
      appointmentTrend,
      topDoctors: topDoctorsEnriched,
      busiestHours: busiestHours.map(h => ({
        time: h._id,
        count: h.count
      })),
      generatedAt: new Date().toISOString()
    };

    res.json(stats);

  } catch (error) {
    console.error('[AdminAppointmentController.getAppointmentStats] Error:', error);
    res.status(500).json({ message: 'Failed to fetch appointment stats', error: error.message });
  }
};

/**
 * Get recent appointment activity
 * GET /api/v1/appointments/admin/recent-activity
 */
export const getRecentActivity = async (req, res) => {
  try {
    const { limit = 20 } = req.query;

    const recentAppointments = await Appointment.find()
      .sort({ updatedAt: -1 })
      .limit(parseInt(limit))
      .lean();

    // Enrich with profiles
    const enrichedActivity = await Promise.all(
      recentAppointments.map(async (apt) => {
        const [doctor, patient] = await Promise.all([
          fetchDoctorProfile(apt.doctorId.toString()).catch(() => null),
          fetchPatientProfile(apt.patientId.toString()).catch(() => null)
        ]);

        return {
          _id: apt._id,
          status: apt.status,
          appointmentDate: apt.appointmentDate,
          appointmentTime: apt.appointmentTime,
          createdAt: apt.createdAt,
          updatedAt: apt.updatedAt,
          doctor: doctor ? {
            _id: doctor._id,
            firstName: doctor.firstName,
            lastName: doctor.lastName,
            specialty: doctor.specialty,
            profilePhoto: doctor.profilePhoto
          } : null,
          patient: patient ? {
            _id: patient._id,
            firstName: patient.firstName,
            lastName: patient.lastName,
            profilePhoto: patient.profilePhoto
          } : null
        };
      })
    );

    res.json({ recentActivity: enrichedActivity });

  } catch (error) {
    console.error('[AdminAppointmentController.getRecentActivity] Error:', error);
    res.status(500).json({ message: 'Failed to fetch recent activity', error: error.message });
  }
};

/**
 * Get today's appointments for dashboard
 * GET /api/v1/appointments/admin/today
 */
export const getTodayAppointments = async (req, res) => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);

    const appointments = await Appointment.find({
      appointmentDate: { $gte: today, $lt: tomorrow }
    })
      .sort({ appointmentTime: 1 })
      .lean();

    // Enrich with profiles
    const enrichedAppointments = await Promise.all(
      appointments.map(async (apt) => {
        const [doctor, patient] = await Promise.all([
          fetchDoctorProfile(apt.doctorId.toString()).catch(() => null),
          fetchPatientProfile(apt.patientId.toString()).catch(() => null)
        ]);

        return {
          ...apt,
          doctor: doctor ? {
            _id: doctor._id,
            firstName: doctor.firstName,
            lastName: doctor.lastName,
            specialty: doctor.specialty,
            profilePhoto: doctor.profilePhoto
          } : null,
          patient: patient ? {
            _id: patient._id,
            firstName: patient.firstName,
            lastName: patient.lastName,
            profilePhoto: patient.profilePhoto
          } : null
        };
      })
    );

    // Group by status
    const byStatus = {
      pending: enrichedAppointments.filter(a => a.status === 'pending'),
      confirmed: enrichedAppointments.filter(a => a.status === 'confirmed'),
      completed: enrichedAppointments.filter(a => a.status === 'completed'),
      cancelled: enrichedAppointments.filter(a => a.status === 'cancelled'),
      noShow: enrichedAppointments.filter(a => a.status === 'no-show')
    };

    res.json({
      total: appointments.length,
      appointments: enrichedAppointments,
      byStatus
    });

  } catch (error) {
    console.error('[AdminAppointmentController.getTodayAppointments] Error:', error);
    res.status(500).json({ message: 'Failed to fetch today appointments', error: error.message });
  }
};

/**
 * Get pending reschedule requests
 * GET /api/v1/appointments/admin/reschedule-requests
 */
export const getPendingRescheduleRequests = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [requests, total] = await Promise.all([
      Appointment.find({
        'rescheduleRequest.status': 'pending'
      })
        .sort({ 'rescheduleRequest.requestedAt': -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Appointment.countDocuments({
        'rescheduleRequest.status': 'pending'
      })
    ]);

    // Enrich with profiles
    const enrichedRequests = await Promise.all(
      requests.map(async (apt) => {
        const [doctor, patient] = await Promise.all([
          fetchDoctorProfile(apt.doctorId.toString()).catch(() => null),
          fetchPatientProfile(apt.patientId.toString()).catch(() => null)
        ]);

        return {
          ...apt,
          doctor: doctor ? {
            _id: doctor._id,
            firstName: doctor.firstName,
            lastName: doctor.lastName,
            specialty: doctor.specialty
          } : null,
          patient: patient ? {
            _id: patient._id,
            firstName: patient.firstName,
            lastName: patient.lastName
          } : null
        };
      })
    );

    res.json({
      requests: enrichedRequests,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('[AdminAppointmentController.getPendingRescheduleRequests] Error:', error);
    res.status(500).json({ message: 'Failed to fetch reschedule requests', error: error.message });
  }
};

/**
 * Get advanced analytics for admin dashboard
 * GET /api/v1/appointments/admin/analytics
 */
export const getAdvancedAnalytics = async (req, res) => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);

    // ============================
    // OVERALL PLATFORM STATS
    // ============================
    const overallStats = await Appointment.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
          pending: { $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] } },
          confirmed: { $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] } },
          cancelled: { $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] } },
          rejected: { $sum: { $cond: [{ $eq: ['$status', 'rejected'] }, 1, 0] } },
          noShow: { $sum: { $cond: [{ $eq: ['$status', 'no-show'] }, 1, 0] } },
          referrals: { $sum: { $cond: ['$isReferral', 1, 0] } },
          rescheduled: { $sum: { $cond: ['$isRescheduled', 1, 0] } }
        }
      }
    ]);

    // ============================
    // APPOINTMENTS BY DOCTOR
    // ============================
    const appointmentsByDoctor = await Appointment.aggregate([
      {
        $group: {
          _id: '$doctorId',
          total: { $sum: 1 },
          completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
          cancelled: { $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] } },
          noShow: { $sum: { $cond: [{ $eq: ['$status', 'no-show'] }, 1, 0] } },
          pending: { $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] } },
          confirmed: { $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] } },
          lastAppointment: { $max: '$appointmentDate' },
          firstAppointment: { $min: '$appointmentDate' }
        }
      },
      { $sort: { total: -1 } }
    ]);

    // Enrich with doctor profiles
    const doctorStatsEnriched = await Promise.all(
      appointmentsByDoctor.map(async (stat) => {
        const doctor = await fetchDoctorProfile(stat._id.toString()).catch(() => null);
        const completionRate = (stat.completed + stat.cancelled + stat.noShow) > 0
          ? ((stat.completed / (stat.completed + stat.cancelled + stat.noShow)) * 100).toFixed(1)
          : 0;
        return {
          doctorId: stat._id,
          doctor: doctor ? {
            _id: doctor._id,
            firstName: doctor.firstName,
            lastName: doctor.lastName,
            specialty: doctor.specialty,
            profilePhoto: doctor.profilePhoto,
            city: doctor.city,
            state: doctor.state
          } : null,
          total: stat.total,
          completed: stat.completed,
          cancelled: stat.cancelled,
          noShow: stat.noShow,
          pending: stat.pending,
          confirmed: stat.confirmed,
          completionRate: parseFloat(completionRate),
          lastAppointment: stat.lastAppointment,
          firstAppointment: stat.firstAppointment
        };
      })
    );

    // ============================
    // APPOINTMENTS BY PATIENT
    // ============================
    const appointmentsByPatient = await Appointment.aggregate([
      {
        $group: {
          _id: '$patientId',
          total: { $sum: 1 },
          completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
          cancelled: { $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] } },
          noShow: { $sum: { $cond: [{ $eq: ['$status', 'no-show'] }, 1, 0] } },
          lastAppointment: { $max: '$appointmentDate' },
          uniqueDoctors: { $addToSet: '$doctorId' }
        }
      },
      { $sort: { total: -1 } },
      { $limit: 50 }
    ]);

    // Enrich with patient profiles
    const patientStatsEnriched = await Promise.all(
      appointmentsByPatient.map(async (stat) => {
        const patient = await fetchPatientProfile(stat._id.toString()).catch(() => null);
        return {
          patientId: stat._id,
          patient: patient ? {
            _id: patient._id,
            firstName: patient.firstName,
            lastName: patient.lastName,
            profilePhoto: patient.profilePhoto,
            city: patient.city,
            state: patient.state
          } : null,
          total: stat.total,
          completed: stat.completed,
          cancelled: stat.cancelled,
          noShow: stat.noShow,
          lastAppointment: stat.lastAppointment,
          uniqueDoctors: stat.uniqueDoctors.length
        };
      })
    );

    // ============================
    // APPOINTMENTS BY REGION (based on doctor location)
    // ============================
    // First, get all unique doctors and their locations
    const allDoctorIds = [...new Set(appointmentsByDoctor.map(d => d._id.toString()))];
    const doctorLocations = {};
    
    await Promise.all(
      allDoctorIds.map(async (id) => {
        const doctor = await fetchDoctorProfile(id).catch(() => null);
        if (doctor && (doctor.city || doctor.state)) {
          doctorLocations[id] = {
            city: doctor.city || 'Unknown',
            state: doctor.state || 'Unknown'
          };
        }
      })
    );

    // Aggregate by region
    const regionStats = {};
    appointmentsByDoctor.forEach(stat => {
      const location = doctorLocations[stat._id.toString()];
      const region = location ? `${location.city}, ${location.state}` : 'Unknown';
      
      if (!regionStats[region]) {
        regionStats[region] = {
          region,
          city: location?.city || 'Unknown',
          state: location?.state || 'Unknown',
          total: 0,
          completed: 0,
          cancelled: 0,
          doctors: new Set()
        };
      }
      
      regionStats[region].total += stat.total;
      regionStats[region].completed += stat.completed;
      regionStats[region].cancelled += stat.cancelled;
      regionStats[region].doctors.add(stat._id.toString());
    });

    const regionStatsArray = Object.values(regionStats)
      .map(r => ({
        ...r,
        doctors: r.doctors.size,
        completionRate: r.total > 0 ? ((r.completed / r.total) * 100).toFixed(1) : 0
      }))
      .sort((a, b) => b.total - a.total);

    // ============================
    // TIME-BASED ANALYTICS
    // ============================
    // Daily trend (last 30 days)
    const dailyTrend = await Appointment.aggregate([
      {
        $match: {
          createdAt: { $gte: thirtyDaysAgo }
        }
      },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          total: { $sum: 1 },
          completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
          cancelled: { $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] } }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // Weekly comparison
    const thisWeekStats = await Appointment.aggregate([
      {
        $match: {
          createdAt: { $gte: sevenDaysAgo }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } }
        }
      }
    ]);

    const previousWeekStart = new Date(sevenDaysAgo.getTime() - 7 * 24 * 60 * 60 * 1000);
    const lastWeekStats = await Appointment.aggregate([
      {
        $match: {
          createdAt: { $gte: previousWeekStart, $lt: sevenDaysAgo }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } }
        }
      }
    ]);

    // Busiest days of week
    const busiestDays = await Appointment.aggregate([
      {
        $group: {
          _id: { $dayOfWeek: '$appointmentDate' },
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } }
    ]);

    const dayNames = ['', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const busiestDaysFormatted = busiestDays.map(d => ({
      day: dayNames[d._id],
      dayIndex: d._id,
      count: d.count
    }));

    // Peak hours
    const peakHours = await Appointment.aggregate([
      {
        $group: {
          _id: '$appointmentTime',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    // ============================
    // PLATFORM RELIABILITY METRICS
    // ============================
    const overall = overallStats[0] || {
      total: 0, completed: 0, pending: 0, confirmed: 0,
      cancelled: 0, rejected: 0, noShow: 0, referrals: 0, rescheduled: 0
    };

    const totalResolved = overall.completed + overall.cancelled + overall.rejected + overall.noShow;
    const completionRate = totalResolved > 0 ? ((overall.completed / totalResolved) * 100).toFixed(1) : 0;
    const cancellationRate = overall.total > 0 ? ((overall.cancelled / overall.total) * 100).toFixed(1) : 0;
    const noShowRate = overall.total > 0 ? ((overall.noShow / overall.total) * 100).toFixed(1) : 0;
    const referralRate = overall.total > 0 ? ((overall.referrals / overall.total) * 100).toFixed(1) : 0;
    const rescheduleRate = overall.total > 0 ? ((overall.rescheduled / overall.total) * 100).toFixed(1) : 0;

    // Week over week growth
    const thisWeek = thisWeekStats[0] || { total: 0, completed: 0 };
    const lastWeek = lastWeekStats[0] || { total: 0, completed: 0 };
    const weeklyGrowth = lastWeek.total > 0 
      ? (((thisWeek.total - lastWeek.total) / lastWeek.total) * 100).toFixed(1)
      : thisWeek.total > 0 ? 100 : 0;

    res.json({
      overview: {
        total: overall.total,
        completed: overall.completed,
        pending: overall.pending,
        confirmed: overall.confirmed,
        cancelled: overall.cancelled,
        rejected: overall.rejected,
        noShow: overall.noShow,
        referrals: overall.referrals,
        rescheduled: overall.rescheduled
      },
      reliability: {
        completionRate: parseFloat(completionRate),
        cancellationRate: parseFloat(cancellationRate),
        noShowRate: parseFloat(noShowRate),
        referralRate: parseFloat(referralRate),
        rescheduleRate: parseFloat(rescheduleRate),
        weeklyGrowth: parseFloat(weeklyGrowth),
        thisWeekTotal: thisWeek.total,
        lastWeekTotal: lastWeek.total
      },
      doctorStats: doctorStatsEnriched,
      patientStats: patientStatsEnriched,
      regionStats: regionStatsArray,
      trends: {
        daily: dailyTrend,
        busiestDays: busiestDaysFormatted,
        peakHours: peakHours.map(h => ({ time: h._id, count: h.count }))
      },
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('[AdminAppointmentController.getAdvancedAnalytics] Error:', error);
    res.status(500).json({ message: 'Failed to fetch analytics', error: error.message });
  }
};
