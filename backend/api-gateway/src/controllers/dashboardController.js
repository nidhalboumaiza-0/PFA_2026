import axios from 'axios';

// Service URLs (internal Docker network)
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://user-service:3002';
const RDV_SERVICE_URL = process.env.RDV_SERVICE_URL || 'http://rdv-service:3003';
const MESSAGING_SERVICE_URL = process.env.MESSAGING_SERVICE_URL || 'http://messaging-service:3006';
const NOTIFICATION_SERVICE_URL = process.env.NOTIFICATION_SERVICE_URL || 'http://notification-service:3007';
const MEDICAL_RECORDS_SERVICE_URL = process.env.MEDICAL_RECORDS_SERVICE_URL || 'http://medical-records-service:3004';

// Helper to make internal service calls with timeout
const fetchServiceStats = async (url, token, timeout = 5000) => {
  try {
    const response = await axios.get(url, {
      headers: { Authorization: `Bearer ${token}` },
      timeout
    });
    return response.data;
  } catch (error) {
    console.error(`[DashboardStats] Failed to fetch from ${url}:`, error.message);
    return null;
  }
};

/**
 * Get system-wide dashboard statistics
 * GET /api/v1/admin/dashboard/stats
 */
export const getDashboardStats = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    console.log('[DashboardStats] Fetching system-wide statistics...');

    // Fetch stats from all services in parallel
    const [userStats, appointmentStats, messagingStats, notificationStats] = await Promise.all([
      fetchServiceStats(`${USER_SERVICE_URL}/api/v1/users/admin/stats`, token),
      fetchServiceStats(`${RDV_SERVICE_URL}/api/v1/appointments/admin/stats`, token),
      fetchServiceStats(`${MESSAGING_SERVICE_URL}/api/v1/messaging/admin/stats`, token),
      fetchServiceStats(`${NOTIFICATION_SERVICE_URL}/api/v1/notifications/admin/stats`, token)
    ]);

    // Build aggregated dashboard stats
    const dashboardStats = {
      // Platform Overview
      overview: {
        totalUsers: userStats?.overview?.totalUsers || 0,
        totalDoctors: userStats?.overview?.totalDoctors || 0,
        totalPatients: userStats?.overview?.totalPatients || 0,
        totalAppointments: appointmentStats?.overview?.total || 0,
        totalMessages: messagingStats?.overview?.totalMessages || 0,
        totalNotifications: notificationStats?.overview?.totalSent || 0,
        platformHealth: 'healthy'
      },

      // User Statistics
      users: userStats ? {
        total: userStats.overview?.totalUsers || 0,
        doctors: {
          total: userStats.overview?.totalDoctors || 0,
          active: userStats.doctors?.active || 0,
          verified: userStats.doctors?.verified || 0,
          pendingVerification: userStats.doctors?.pendingVerification || 0,
          verificationRate: userStats.doctors?.verificationRate || '0'
        },
        patients: {
          total: userStats.overview?.totalPatients || 0,
          active: userStats.patients?.active || 0
        },
        newRegistrations: userStats.newRegistrations || {
          today: { total: 0 },
          thisWeek: { total: 0 },
          thisMonth: { total: 0 }
        },
        specialtyDistribution: (userStats.specialtyDistribution || []).map(s => ({
          _id: s.specialty || s._id || 'Not Specified',
          count: s.count || 0
        })).filter(s => s._id && s._id !== 'null' && s._id !== 'undefined')
      } : null,

      // Appointment Statistics
      appointments: appointmentStats ? {
        total: appointmentStats.overview?.total || 0,
        byStatus: {
          pending: appointmentStats.overview?.pending || 0,
          confirmed: appointmentStats.overview?.confirmed || 0,
          completed: appointmentStats.overview?.completed || 0,
          cancelled: appointmentStats.overview?.cancelled || 0,
          rejected: appointmentStats.overview?.rejected || 0,
          noShow: appointmentStats.overview?.noShow || 0
        },
        completionRate: appointmentStats.overview?.completionRate || '0',
        today: appointmentStats.today || { total: 0, upcoming: 0 },
        thisWeek: appointmentStats.period?.thisWeek || 0,
        thisMonth: appointmentStats.period?.thisMonth || 0,
        topDoctors: (appointmentStats.topDoctors || []).slice(0, 5).map(d => ({
          doctorId: d._id || d.doctorId,
          name: d.doctor ? `${d.doctor.firstName || ''} ${d.doctor.lastName || ''}`.trim() : (d.name || 'Unknown Doctor'),
          count: d.appointmentCount || d.count || 0,
          completedCount: d.completedCount || 0,
          specialty: d.doctor?.specialty || d.specialty || '',
          profilePhoto: d.doctor?.profilePhoto || d.profilePhoto || ''
        })),
        busiestHours: appointmentStats.busiestHours?.slice(0, 5) || []
      } : null,

      // Messaging Statistics
      messaging: messagingStats ? {
        totalConversations: messagingStats.overview?.totalConversations || 0,
        totalMessages: messagingStats.overview?.totalMessages || 0,
        activeConversations: messagingStats.overview?.activeConversations || 0,
        messagesThisWeek: messagingStats.period?.thisWeek || 0,
        messagesThisMonth: messagingStats.period?.thisMonth || 0
      } : null,

      // Notification Statistics
      notifications: notificationStats ? {
        totalSent: notificationStats.overview?.totalSent || 0,
        byType: notificationStats.byType || {},
        deliveryRate: notificationStats.deliveryRate || '0',
        thisWeek: notificationStats.period?.thisWeek || 0,
        thisMonth: notificationStats.period?.thisMonth || 0
      } : null,

      // Activity Trends (combined)
      trends: {
        userRegistrations: userStats?.registrationTrend || { doctors: [], patients: [] },
        appointments: appointmentStats?.appointmentTrend || []
      },

      // Service Status
      serviceStatus: {
        userService: userStats ? 'healthy' : 'unavailable',
        rdvService: appointmentStats ? 'healthy' : 'unavailable',
        messagingService: messagingStats ? 'healthy' : 'unavailable',
        notificationService: notificationStats ? 'healthy' : 'unavailable'
      },

      // Metadata
      generatedAt: new Date().toISOString()
    };

    console.log('[DashboardStats] Statistics aggregated successfully');
    res.json(dashboardStats);

  } catch (error) {
    console.error('[DashboardStats] Error:', error);
    res.status(500).json({ 
      message: 'Failed to fetch dashboard statistics', 
      error: error.message 
    });
  }
};

/**
 * Get quick stats for dashboard header
 * GET /api/v1/admin/dashboard/quick-stats
 */
export const getQuickStats = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    // Fetch only user and appointment stats for quick view
    const [userStats, appointmentStats] = await Promise.all([
      fetchServiceStats(`${USER_SERVICE_URL}/api/v1/users/admin/stats`, token, 3000),
      fetchServiceStats(`${RDV_SERVICE_URL}/api/v1/appointments/admin/stats`, token, 3000)
    ]);

    const quickStats = {
      totalUsers: userStats?.overview?.totalUsers || 0,
      totalDoctors: userStats?.overview?.totalDoctors || 0,
      totalPatients: userStats?.overview?.totalPatients || 0,
      pendingVerifications: userStats?.doctors?.pendingVerification || 0,
      totalAppointments: appointmentStats?.overview?.total || 0,
      todayAppointments: appointmentStats?.today?.total || 0,
      pendingAppointments: appointmentStats?.overview?.pending || 0,
      completionRate: appointmentStats?.overview?.completionRate || '0',
      newUsersToday: userStats?.newRegistrations?.today?.total || 0,
      generatedAt: new Date().toISOString()
    };

    res.json(quickStats);

  } catch (error) {
    console.error('[QuickStats] Error:', error);
    res.status(500).json({ 
      message: 'Failed to fetch quick statistics', 
      error: error.message 
    });
  }
};

/**
 * Get platform health status
 * GET /api/v1/admin/dashboard/health
 */
export const getPlatformHealth = async (req, res) => {
  try {
    const services = [
      { name: 'user-service', url: `${USER_SERVICE_URL}/health` },
      { name: 'rdv-service', url: `${RDV_SERVICE_URL}/health` },
      { name: 'messaging-service', url: `${MESSAGING_SERVICE_URL}/health` },
      { name: 'notification-service', url: `${NOTIFICATION_SERVICE_URL}/health` },
      { name: 'medical-records-service', url: `${MEDICAL_RECORDS_SERVICE_URL}/health` }
    ];

    const healthChecks = await Promise.all(
      services.map(async (service) => {
        try {
          const start = Date.now();
          const response = await axios.get(service.url, { timeout: 3000 });
          const latency = Date.now() - start;
          
          return {
            name: service.name,
            status: response.status === 200 ? 'healthy' : 'degraded',
            latency,
            lastChecked: new Date().toISOString()
          };
        } catch (error) {
          return {
            name: service.name,
            status: 'unhealthy',
            error: error.message,
            lastChecked: new Date().toISOString()
          };
        }
      })
    );

    const healthyCount = healthChecks.filter(h => h.status === 'healthy').length;
    const totalServices = healthChecks.length;

    res.json({
      overallStatus: healthyCount === totalServices ? 'healthy' : 
                     healthyCount >= totalServices / 2 ? 'degraded' : 'critical',
      healthyServices: healthyCount,
      totalServices,
      services: healthChecks,
      checkedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('[PlatformHealth] Error:', error);
    res.status(500).json({ 
      message: 'Failed to check platform health', 
      error: error.message 
    });
  }
};

/**
 * Get recent activity across all services
 * GET /api/v1/admin/dashboard/recent-activity
 */
export const getRecentActivity = async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const { limit = 20 } = req.query;
    
    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    // Fetch recent activity from services in parallel
    const [userActivity, appointmentActivity] = await Promise.all([
      fetchServiceStats(`${USER_SERVICE_URL}/api/v1/users/admin/recent-activity?limit=${limit}`, token),
      fetchServiceStats(`${RDV_SERVICE_URL}/api/v1/appointments/admin/recent-activity?limit=${limit}`, token)
    ]);

    // Combine and sort by timestamp
    const activities = [];

    // Add user registrations
    if (userActivity?.recentActivity) {
      userActivity.recentActivity.forEach(user => {
        activities.push({
          type: 'user_registered',
          subtype: user.userType,
          data: {
            userId: user._id,
            name: `${user.firstName} ${user.lastName}`,
            userType: user.userType,
            profilePhoto: user.profilePhoto
          },
          timestamp: user.createdAt
        });
      });
    }

    // Add appointment activities
    if (appointmentActivity?.recentActivity) {
      appointmentActivity.recentActivity.forEach(apt => {
        activities.push({
          type: 'appointment_activity',
          subtype: apt.status,
          data: {
            appointmentId: apt._id,
            status: apt.status,
            date: apt.appointmentDate,
            time: apt.appointmentTime,
            doctor: apt.doctor,
            patient: apt.patient
          },
          timestamp: apt.updatedAt || apt.createdAt
        });
      });
    }

    // Sort by timestamp (newest first) and limit
    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    const limitedActivities = activities.slice(0, parseInt(limit));

    res.json({
      activities: limitedActivities,
      total: activities.length,
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('[RecentActivity] Error:', error);
    res.status(500).json({ 
      message: 'Failed to fetch recent activity', 
      error: error.message 
    });
  }
};
