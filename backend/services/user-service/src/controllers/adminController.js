import Doctor from '../models/Doctor.js';
import Patient from '../models/Patient.js';
import { mongoose, kafkaProducer } from '../../../../shared/index.js';
import { getIO } from '../socket/index.js';

/**
 * Transform Doctor/Patient document to frontend User format
 */
const transformToUserFormat = (doc, userType) => ({
  _id: doc._id,
  userId: doc.userId,
  email: doc.email || `${doc.firstName?.toLowerCase().replace(/\s+/g, '')}.${doc.lastName?.toLowerCase().replace(/\s+/g, '')}@esante.tn`,
  role: userType,
  isActive: doc.isActive !== false,
  isEmailVerified: doc.isEmailVerified || true,
  createdAt: doc.createdAt,
  updatedAt: doc.updatedAt,
  profile: {
    firstName: doc.firstName,
    lastName: doc.lastName,
    phone: doc.phone,
    profilePhoto: doc.profilePhoto,
    // Doctor-specific fields
    specialty: doc.specialty,
    subSpecialty: doc.subSpecialty,
    licenseNumber: doc.licenseNumber,
    yearsOfExperience: doc.yearsOfExperience,
    education: doc.education,
    languages: doc.languages,
    clinicName: doc.clinicName,
    clinicAddress: doc.clinicAddress,
    about: doc.about,
    consultationFee: doc.consultationFee,
    acceptsInsurance: doc.acceptsInsurance,
    rating: doc.rating,
    totalReviews: doc.totalReviews,
    // Patient-specific fields
    dateOfBirth: doc.dateOfBirth,
    gender: doc.gender,
    bloodType: doc.bloodType,
    allergies: doc.allergies,
    chronicConditions: doc.chronicConditions,
    emergencyContact: doc.emergencyContact,
    address: doc.address
  },
  // Keep original fields for compatibility
  userType: userType,
  isVerified: doc.isVerified
});

/**
 * Get all users with pagination and filters
 * GET /api/v1/users/admin/users
 */
export const getAllUsers = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      role,
      search,
      isActive,
      isVerified,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOptions = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    // Build query for each model
    const buildQuery = (searchFields) => {
      const query = {};
      
      if (search) {
        query.$or = searchFields.map(field => ({
          [field]: { $regex: search, $options: 'i' }
        }));
      }
      
      if (isActive !== undefined) {
        query.isActive = isActive === 'true';
      }
      
      return query;
    };

    let users = [];
    let total = 0;

    if (!role || role === 'all') {
      // Get both doctors and patients
      const doctorQuery = buildQuery(['firstName', 'lastName', 'specialty', 'phone']);
      if (isVerified !== undefined) {
        doctorQuery.isVerified = isVerified === 'true';
      }
      
      const patientQuery = buildQuery(['firstName', 'lastName', 'phone']);

      const [doctors, patients, doctorCount, patientCount] = await Promise.all([
        Doctor.find(doctorQuery).sort(sortOptions).lean(),
        Patient.find(patientQuery).sort(sortOptions).lean(),
        Doctor.countDocuments(doctorQuery),
        Patient.countDocuments(patientQuery)
      ]);

      // Transform to frontend User format
      const doctorsWithRole = doctors.map(d => transformToUserFormat(d, 'doctor'));
      const patientsWithRole = patients.map(p => transformToUserFormat(p, 'patient'));

      // Combine and sort
      users = [...doctorsWithRole, ...patientsWithRole]
        .sort((a, b) => {
          const aVal = a[sortBy] || a.profile?.[sortBy];
          const bVal = b[sortBy] || b.profile?.[sortBy];
          return sortOrder === 'asc' 
            ? (aVal > bVal ? 1 : -1)
            : (aVal < bVal ? 1 : -1);
        })
        .slice(skip, skip + parseInt(limit));

      total = doctorCount + patientCount;

    } else if (role === 'doctor') {
      const query = buildQuery(['firstName', 'lastName', 'specialty', 'phone']);
      if (isVerified !== undefined) {
        query.isVerified = isVerified === 'true';
      }

      [users, total] = await Promise.all([
        Doctor.find(query).sort(sortOptions).skip(skip).limit(parseInt(limit)).lean(),
        Doctor.countDocuments(query)
      ]);
      users = users.map(d => transformToUserFormat(d, 'doctor'));

    } else if (role === 'patient') {
      const query = buildQuery(['firstName', 'lastName', 'phone']);

      [users, total] = await Promise.all([
        Patient.find(query).sort(sortOptions).skip(skip).limit(parseInt(limit)).lean(),
        Patient.countDocuments(query)
      ]);
      users = users.map(p => transformToUserFormat(p, 'patient'));
    }

    res.json({
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('[AdminController.getAllUsers] Error:', error);
    res.status(500).json({ message: 'Failed to fetch users', error: error.message });
  }
};

/**
 * Get user by ID (doctor or patient)
 * GET /api/v1/users/admin/users/:id
 */
export const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const { type } = req.query; // 'doctor' or 'patient'

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    let user;
    if (type === 'doctor') {
      user = await Doctor.findById(id).lean();
    } else if (type === 'patient') {
      user = await Patient.findById(id).lean();
    } else {
      // Try both
      user = await Doctor.findById(id).lean();
      if (user) {
        user.userType = 'doctor';
      } else {
        user = await Patient.findById(id).lean();
        if (user) user.userType = 'patient';
      }
    }

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ user });

  } catch (error) {
    console.error('[AdminController.getUserById] Error:', error);
    res.status(500).json({ message: 'Failed to fetch user', error: error.message });
  }
};

/**
 * Update user status (activate/deactivate)
 * PUT /api/v1/users/admin/users/:id/status
 */
export const updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive, type, reason } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({ message: 'isActive must be a boolean' });
    }

    let user;
    let Model;
    
    if (type === 'doctor') {
      Model = Doctor;
    } else if (type === 'patient') {
      Model = Patient;
    } else {
      // Try to find in both
      user = await Doctor.findById(id);
      if (user) {
        Model = Doctor;
        type === 'doctor';
      } else {
        user = await Patient.findById(id);
        if (user) {
          Model = Patient;
        }
      }
    }

    if (!Model && !user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user = await Model.findByIdAndUpdate(
      id,
      { 
        isActive,
        statusUpdatedAt: new Date(),
        statusReason: reason || null
      },
      { new: true }
    ).lean();

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const userType = Model === Doctor ? 'doctor' : 'patient';

    // Emit real-time update to admin dashboard
    const io = getIO();
    if (io) {
      io.to('admin_users').emit('user_status_changed', {
        userId: id,
        userType,
        isActive,
        reason,
        updatedAt: new Date().toISOString(),
        user: { ...user, userType }
      });
    }

    // Publish Kafka event for audit
    try {
      await kafkaProducer.publishEvent('user-events', {
        type: 'USER_STATUS_CHANGED',
        userId: user.userId,
        profileId: id,
        userType,
        isActive,
        reason,
        changedBy: req.user.id,
        timestamp: new Date().toISOString()
      });
    } catch (kafkaError) {
      console.error('[AdminController.updateUserStatus] Kafka error:', kafkaError);
    }

    res.json({
      message: `User ${isActive ? 'activated' : 'deactivated'} successfully`,
      user: { ...user, userType }
    });

  } catch (error) {
    console.error('[AdminController.updateUserStatus] Error:', error);
    res.status(500).json({ message: 'Failed to update user status', error: error.message });
  }
};

/**
 * Verify doctor account
 * PUT /api/v1/users/admin/doctors/:id/verify
 */
export const verifyDoctor = async (req, res) => {
  try {
    const { id } = req.params;
    const { isVerified, notes } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid doctor ID' });
    }

    const doctor = await Doctor.findByIdAndUpdate(
      id,
      { 
        isVerified: isVerified !== false,
        verifiedAt: isVerified !== false ? new Date() : null,
        verifiedBy: req.user.id,
        verificationNotes: notes || null
      },
      { new: true }
    ).lean();

    if (!doctor) {
      return res.status(404).json({ message: 'Doctor not found' });
    }

    // Emit real-time update
    const io = getIO();
    if (io) {
      io.to('admin_users').emit('doctor_verified', {
        doctorId: id,
        isVerified: doctor.isVerified,
        verifiedAt: doctor.verifiedAt,
        doctor: { ...doctor, userType: 'doctor' }
      });
    }

    // Publish Kafka event
    try {
      await kafkaProducer.publishEvent('user-events', {
        type: 'DOCTOR_VERIFIED',
        doctorId: id,
        userId: doctor.userId,
        isVerified: doctor.isVerified,
        verifiedBy: req.user.id,
        timestamp: new Date().toISOString()
      });
    } catch (kafkaError) {
      console.error('[AdminController.verifyDoctor] Kafka error:', kafkaError);
    }

    res.json({
      message: `Doctor ${doctor.isVerified ? 'verified' : 'unverified'} successfully`,
      doctor: { ...doctor, userType: 'doctor' }
    });

  } catch (error) {
    console.error('[AdminController.verifyDoctor] Error:', error);
    res.status(500).json({ message: 'Failed to verify doctor', error: error.message });
  }
};

/**
 * Delete user (soft delete - just deactivate)
 * DELETE /api/v1/users/admin/users/:id
 */
export const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { type, reason, hardDelete = false } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid user ID' });
    }

    let Model;
    if (type === 'doctor') {
      Model = Doctor;
    } else if (type === 'patient') {
      Model = Patient;
    } else {
      // Try to find in both
      const doctor = await Doctor.findById(id);
      if (doctor) {
        Model = Doctor;
      } else {
        Model = Patient;
      }
    }

    let user;
    const userType = Model === Doctor ? 'doctor' : 'patient';

    if (hardDelete) {
      // Permanent delete (use with caution)
      user = await Model.findByIdAndDelete(id).lean();
    } else {
      // Soft delete - just mark as inactive and deleted
      user = await Model.findByIdAndUpdate(
        id,
        { 
          isActive: false,
          isDeleted: true,
          deletedAt: new Date(),
          deletedBy: req.user.id,
          deleteReason: reason || null
        },
        { new: true }
      ).lean();
    }

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Emit real-time update
    const io = getIO();
    if (io) {
      io.to('admin_users').emit('user_deleted', {
        userId: id,
        userType,
        hardDelete,
        deletedAt: new Date().toISOString()
      });
    }

    // Publish Kafka event
    try {
      await kafkaProducer.publishEvent('user-events', {
        type: 'USER_DELETED',
        userId: user.userId,
        profileId: id,
        userType,
        hardDelete,
        reason,
        deletedBy: req.user.id,
        timestamp: new Date().toISOString()
      });
    } catch (kafkaError) {
      console.error('[AdminController.deleteUser] Kafka error:', kafkaError);
    }

    res.json({
      message: `User ${hardDelete ? 'permanently deleted' : 'deleted'} successfully`,
      userId: id
    });

  } catch (error) {
    console.error('[AdminController.deleteUser] Error:', error);
    res.status(500).json({ message: 'Failed to delete user', error: error.message });
  }
};

/**
 * Get user statistics for admin dashboard
 * GET /api/v1/users/admin/stats
 */
export const getUserStats = async (req, res) => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const thisWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      totalDoctors,
      totalPatients,
      activeDoctors,
      activePatients,
      verifiedDoctors,
      pendingVerification,
      newDoctorsToday,
      newPatientsToday,
      newDoctorsThisWeek,
      newPatientsThisWeek,
      newDoctorsThisMonth,
      newPatientsThisMonth
    ] = await Promise.all([
      Doctor.countDocuments(),
      Patient.countDocuments(),
      Doctor.countDocuments({ isActive: { $ne: false } }),
      Patient.countDocuments({ isActive: { $ne: false } }),
      Doctor.countDocuments({ isVerified: true }),
      Doctor.countDocuments({ isVerified: { $ne: true } }),
      Doctor.countDocuments({ createdAt: { $gte: today } }),
      Patient.countDocuments({ createdAt: { $gte: today } }),
      Doctor.countDocuments({ createdAt: { $gte: thisWeek } }),
      Patient.countDocuments({ createdAt: { $gte: thisWeek } }),
      Doctor.countDocuments({ createdAt: { $gte: thisMonth } }),
      Patient.countDocuments({ createdAt: { $gte: thisMonth } })
    ]);

    // Get specialty distribution
    const specialtyDistribution = await Doctor.aggregate([
      { $group: { _id: '$specialty', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    // Get registration trend (last 30 days)
    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
    
    const [doctorTrend, patientTrend] = await Promise.all([
      Doctor.aggregate([
        { $match: { createdAt: { $gte: thirtyDaysAgo } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            count: { $sum: 1 }
          }
        },
        { $sort: { _id: 1 } }
      ]),
      Patient.aggregate([
        { $match: { createdAt: { $gte: thirtyDaysAgo } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            count: { $sum: 1 }
          }
        },
        { $sort: { _id: 1 } }
      ])
    ]);

    const stats = {
      overview: {
        totalUsers: totalDoctors + totalPatients,
        totalDoctors,
        totalPatients,
        activeDoctors,
        activePatients,
        inactiveUsers: (totalDoctors - activeDoctors) + (totalPatients - activePatients)
      },
      doctors: {
        total: totalDoctors,
        active: activeDoctors,
        verified: verifiedDoctors,
        pendingVerification,
        verificationRate: totalDoctors > 0 ? ((verifiedDoctors / totalDoctors) * 100).toFixed(1) : 0
      },
      patients: {
        total: totalPatients,
        active: activePatients
      },
      newRegistrations: {
        today: {
          doctors: newDoctorsToday,
          patients: newPatientsToday,
          total: newDoctorsToday + newPatientsToday
        },
        thisWeek: {
          doctors: newDoctorsThisWeek,
          patients: newPatientsThisWeek,
          total: newDoctorsThisWeek + newPatientsThisWeek
        },
        thisMonth: {
          doctors: newDoctorsThisMonth,
          patients: newPatientsThisMonth,
          total: newDoctorsThisMonth + newPatientsThisMonth
        }
      },
      specialtyDistribution: specialtyDistribution.map(s => ({
        specialty: s._id,
        count: s.count
      })),
      registrationTrend: {
        doctors: doctorTrend,
        patients: patientTrend
      },
      generatedAt: new Date().toISOString()
    };

    res.json(stats);

  } catch (error) {
    console.error('[AdminController.getUserStats] Error:', error);
    res.status(500).json({ message: 'Failed to fetch user stats', error: error.message });
  }
};

/**
 * Get recent user activity
 * GET /api/v1/users/admin/recent-activity
 */
export const getRecentActivity = async (req, res) => {
  try {
    const { limit = 20 } = req.query;

    const [recentDoctors, recentPatients] = await Promise.all([
      Doctor.find()
        .sort({ createdAt: -1 })
        .limit(parseInt(limit))
        .select('firstName lastName specialty isVerified isActive createdAt profilePhoto')
        .lean(),
      Patient.find()
        .sort({ createdAt: -1 })
        .limit(parseInt(limit))
        .select('firstName lastName gender isActive createdAt profilePhoto')
        .lean()
    ]);

    const recentDoctorsWithType = recentDoctors.map(d => ({ ...d, userType: 'doctor' }));
    const recentPatientsWithType = recentPatients.map(p => ({ ...p, userType: 'patient' }));

    // Combine and sort by createdAt
    const recentActivity = [...recentDoctorsWithType, ...recentPatientsWithType]
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, parseInt(limit));

    res.json({ recentActivity });

  } catch (error) {
    console.error('[AdminController.getRecentActivity] Error:', error);
    res.status(500).json({ message: 'Failed to fetch recent activity', error: error.message });
  }
};
