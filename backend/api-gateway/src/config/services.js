/**
 * Microservices Configuration
 */

const services = {
  auth: {
    url: process.env.AUTH_SERVICE_URL || 'http://127.0.0.1:3001',
    path: '/api/v1/auth',
    public: true // No authentication required
  },
  users: {
    url: process.env.USER_SERVICE_URL || 'http://127.0.0.1:3002',
    path: '/api/v1/users',
    public: false, // Authentication required
    socketPath: '/user-socket' // Socket.IO path for real-time admin updates
  },
  appointments: {
    url: process.env.RDV_SERVICE_URL || 'http://127.0.0.1:3003',
    path: '/api/v1/appointments',
    public: false
  },
  medical: {
    url: process.env.MEDICAL_SERVICE_URL || 'http://127.0.0.1:3004',
    path: '/api/v1/medical',
    public: false
  },
  referrals: {
    url: process.env.REFERRAL_SERVICE_URL || 'http://127.0.0.1:3005',
    path: '/api/v1/referrals',
    public: false
  },
  messages: {
    url: process.env.MESSAGING_SERVICE_URL || 'http://127.0.0.1:3006',
    path: '/api/v1/messages',
    public: false
  },
  messaging: {
    url: process.env.MESSAGING_SERVICE_URL || 'http://127.0.0.1:3006',
    path: '/api/v1/messaging',
    public: false,
    adminOnly: true // Admin routes for messaging stats
  },
  notifications: {
    url: process.env.NOTIFICATION_SERVICE_URL || 'http://127.0.0.1:3007',
    path: '/api/v1/notifications',
    public: false
  },
  audit: {
    url: process.env.AUDIT_SERVICE_URL || 'http://127.0.0.1:3008',
    path: '/api/v1/audit',
    public: false,
    adminOnly: true // Only admin can access
  }
};

export default services;
