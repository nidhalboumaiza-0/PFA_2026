// API Configuration
export const API_BASE_URL = 'http://localhost:3000/api/v1';

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

// Auth Types
export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  user: User;
  accessToken: string;
  refreshToken: string;
  sessionId?: string;
}

export interface User {
  _id: string;
  email: string;
  role: 'admin' | 'doctor' | 'patient';
  isActive: boolean;
  isEmailVerified: boolean;
  createdAt: string;
  updatedAt?: string;
  userType?: string;
  isVerified?: boolean;
  profile?: {
    firstName: string;
    lastName: string;
    phone?: string;
    profilePhoto?: string;
    // Doctor-specific fields
    specialty?: string;
    subSpecialty?: string;
    licenseNumber?: string;
    yearsOfExperience?: number;
    education?: Array<{ degree: string; institution: string; year: number }>;
    languages?: string[];
    clinicName?: string;
    clinicAddress?: {
      street?: string;
      city?: string;
      state?: string;
      zipCode?: string;
      country?: string;
    };
    about?: string;
    consultationFee?: number;
    acceptsInsurance?: boolean;
    rating?: number;
    totalReviews?: number;
    // Patient-specific fields
    dateOfBirth?: string;
    gender?: string;
    bloodType?: string;
    allergies?: string[];
    chronicConditions?: string[];
    emergencyContact?: {
      name?: string;
      relationship?: string;
      phone?: string;
    };
    address?: {
      street?: string;
      city?: string;
      state?: string;
      zipCode?: string;
      country?: string;
    };
  };
}

// Dashboard Types
export interface DashboardStats {
  overview: {
    totalUsers: number;
    totalDoctors: number;
    totalPatients: number;
    totalAppointments: number;
    totalMessages: number;
    totalNotifications: number;
    platformHealth: string;
  };
  users: {
    total: number;
    doctors: {
      total: number;
      active: number;
      verified: number;
      pendingVerification: number;
    };
    patients: {
      total: number;
      active: number;
    };
    newRegistrations: {
      today: { total: number };
      thisWeek: { total: number };
      thisMonth: { total: number };
    };
    specialtyDistribution: Array<{ _id: string; count: number }>;
  };
  appointments: {
    total: number;
    byStatus: Record<string, number>;
    completionRate: string;
    today: {
      total: number;
      upcoming: number;
    };
    thisWeek: number;
    thisMonth: number;
    topDoctors: Array<{ doctorId: string; name: string; count: number }>;
    busiestHours: Array<{ time?: string; hour?: number; count: number }>;
  };
  messaging: {
    totalConversations: number;
    totalMessages: number;
    activeConversations: number;
  };
  notifications: {
    totalSent: number;
    deliveryRate: string;
    unreadAlerts: number;
  };
  trends?: {
    userRegistrations?: {
      doctors: Array<{ _id: string; count: number }>;
      patients: Array<{ _id: string; count: number }>;
    };
    appointments?: Array<{
      _id: string;
      total: number;
      statuses: Array<{ status: string; count: number }>;
    }>;
  };
}

export interface QuickStats {
  totalUsers: number;
  pendingVerifications: number;
  todayAppointments: number;
  unreadAlerts: number;
}

// User Types
export interface UserListParams {
  page?: number;
  limit?: number;
  role?: string;
  status?: string;
  search?: string;
}

export interface UserStats {
  totalUsers: number;
  totalPatients: number;
  totalDoctors: number;
  activeUsers: number;
  verifiedUsers: number;
  newUsersToday: number;
  newUsersThisWeek: number;
  newUsersThisMonth: number;
}

// Appointment Types
export interface Appointment {
  _id: string;
  patient: {
    _id: string;
    firstName: string;
    lastName: string;
  };
  doctor: {
    _id: string;
    firstName: string;
    lastName: string;
    specialty?: string;
  };
  appointmentDate: string;
  appointmentTime: string;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  createdAt: string;
}

export interface AppointmentListParams {
  page?: number;
  limit?: number;
  status?: string;
  date?: string;
  doctorId?: string;
  patientId?: string;
}

export interface AppointmentStats {
  total: number;
  byStatus: Record<string, number>;
  todayCount: number;
  thisWeekCount: number;
  thisMonthCount: number;
}

// Audit Log Types
export interface AuditLog {
  _id: string;
  action: string;
  actionCategory: string;
  performedBy: string;
  performedByName: string;
  performedByType: string;
  resourceType: string;
  resourceId: string;
  description: string;
  ipAddress: string;
  userAgent: string;
  isCritical: boolean;
  timestamp: string;
}

export interface AuditLogParams {
  page?: number;
  limit?: number;
  action?: string;
  category?: string;
  startDate?: string;
  endDate?: string;
}

export interface AuditStats {
  totalLogs: number;
  criticalEvents: number;
  todayLogs: number;
  byCategory: Record<string, number>;
}

// Notification Types
export interface Notification {
  _id: string;
  title: string;
  body: string;
  type: string;
  priority: 'urgent' | 'high' | 'medium' | 'low';
  isRead: boolean;
  createdAt: string;
  actionData?: Record<string, any>;
}

export interface NotificationStats {
  totalNotifications: number;
  unreadNotifications: number;
  notificationsToday: number;
  typeDistribution: Array<{ _id: string; count: number }>;
}

// Platform Health Types
export interface ServiceHealth {
  status: 'healthy' | 'degraded' | 'unhealthy';
  responseTime: number;
}

export interface PlatformHealth {
  services: Record<string, ServiceHealth>;
  overall: 'healthy' | 'degraded' | 'unhealthy';
}

// Messaging Types
export interface MessageStats {
  overview: {
    totalConversations: number;
    totalMessages: number;
    activeConversations: number;
    uniqueParticipants: number;
  };
  period: {
    today: { messages: number; newConversations: number };
    thisWeek: { messages: number; newConversations: number };
    thisMonth: { messages: number; newConversations: number };
  };
  topParticipants: Array<{ userId: string; name: string; messageCount: number }>;
}

// Medical Records Types
export interface MedicalRecordsStats {
  totalConsultations: number;
  totalPrescriptions: number;
  consultationsThisMonth: number;
  prescriptionsThisMonth: number;
}

// Referral Types
export interface Referral {
  _id: string;
  patient: {
    firstName: string;
    lastName: string;
  };
  referringDoctor: {
    firstName: string;
    lastName: string;
    specialty: string;
  };
  targetDoctor: {
    firstName: string;
    lastName: string;
    specialty: string;
  };
  status: string;
  priority: 'routine' | 'urgent' | 'emergency';
  reason: string;
  createdAt: string;
}

export interface ReferralStats {
  overview: {
    totalSent: number;
    totalReceived: number;
    pendingReferrals: number;
    acceptedReferrals: number;
    completedReferrals: number;
  };
  bySpecialty: Array<{ specialty: string; count: number }>;
  recentReferrals: Referral[];
}

// Review Types
export interface Review {
  _id: string;
  appointmentId: string;
  patientId: string;
  doctorId: string;
  rating: number;
  comment: string | null;
  createdAt: string;
  updatedAt?: string;
  // Optional populated fields
  patient?: {
    firstName: string;
    lastName: string;
  };
  isEdited?: boolean;
}

export interface ReviewSummary {
  averageRating: number;
  totalReviews: number;
  ratingDistribution: Record<string, number>;
}
