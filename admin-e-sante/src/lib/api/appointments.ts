import { api } from './client';
import { apiCache, CACHE_KEYS, CACHE_TTL } from './cache';
import type {
  Appointment,
  AppointmentListParams,
  AppointmentStats,
  PaginatedResponse,
} from './types';

// Backend response type (different from generic PaginatedResponse)
interface AppointmentsListResponse {
  appointments: Appointment[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface DoctorAppointmentStats {
  doctorId: string;
  doctor: {
    _id: string;
    firstName: string;
    lastName: string;
    specialty?: string;
    profilePhoto?: string;
    city?: string;
    state?: string;
  } | null;
  total: number;
  completed: number;
  cancelled: number;
  noShow: number;
  pending: number;
  confirmed: number;
  completionRate: number;
  lastAppointment: string;
  firstAppointment: string;
}

export interface PatientAppointmentStats {
  patientId: string;
  patient: {
    _id: string;
    firstName: string;
    lastName: string;
    profilePhoto?: string;
    city?: string;
    state?: string;
  } | null;
  total: number;
  completed: number;
  cancelled: number;
  noShow: number;
  lastAppointment: string;
  uniqueDoctors: number;
}

export interface RegionStats {
  region: string;
  city: string;
  state: string;
  total: number;
  completed: number;
  cancelled: number;
  doctors: number;
  completionRate: string;
}

export interface AdvancedAnalyticsResponse {
  overview: {
    total: number;
    completed: number;
    pending: number;
    confirmed: number;
    cancelled: number;
    rejected: number;
    noShow: number;
    referrals: number;
    rescheduled: number;
  };
  reliability: {
    completionRate: number;
    cancellationRate: number;
    noShowRate: number;
    referralRate: number;
    rescheduleRate: number;
    weeklyGrowth: number;
    thisWeekTotal: number;
    lastWeekTotal: number;
  };
  doctorStats: DoctorAppointmentStats[];
  patientStats: PatientAppointmentStats[];
  regionStats: RegionStats[];
  trends: {
    daily: Array<{ _id: string; total: number; completed: number; cancelled: number }>;
    busiestDays: Array<{ day: string; dayIndex: number; count: number }>;
    peakHours: Array<{ time: string; count: number }>;
  };
  generatedAt: string;
}

// Appointments Service with caching
export const appointmentsService = {
  async getAllAppointments(params?: AppointmentListParams): Promise<PaginatedResponse<Appointment>> {
    const queryParams = new URLSearchParams();
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.status) queryParams.append('status', params.status);
    if (params?.date) queryParams.append('date', params.date);
    if (params?.doctorId) queryParams.append('doctorId', params.doctorId);
    if (params?.patientId) queryParams.append('patientId', params.patientId);

    const cacheKey = CACHE_KEYS.APPOINTMENTS_LIST(
      params?.page || 1,
      params?.status || 'all',
      params?.doctorId || params?.patientId || ''
    );

    const response = await apiCache.getOrFetch(
      cacheKey,
      async () => {
        const queryString = queryParams.toString();
        return api.get<AppointmentsListResponse>(`/appointments/admin/appointments${queryString ? `?${queryString}` : ''}`);
      },
      CACHE_TTL.SHORT
    );
    
    return {
      data: response.appointments || [],
      pagination: response.pagination,
    };
  },

  async getAppointmentById(id: string): Promise<{ appointment: Appointment }> {
    return apiCache.getOrFetch(
      `appointments:${id}`,
      () => api.get<{ appointment: Appointment }>(`/appointments/admin/appointments/${id}`),
      CACHE_TTL.MEDIUM
    );
  },

  async updateAppointmentStatus(id: string, status: { status: string; reason?: string }): Promise<{ message: string; appointment: Appointment }> {
    apiCache.invalidatePattern('^appointments:');
    return api.put<{ message: string; appointment: Appointment }>(`/appointments/admin/appointments/${id}/status`, status);
  },

  async rescheduleAppointment(id: string, data: { newDate: string; newTime: string; reason?: string }): Promise<{ message: string; appointment: Appointment }> {
    apiCache.invalidatePattern('^appointments:');
    return api.put<{ message: string; appointment: Appointment }>(`/appointments/admin/appointments/${id}/reschedule`, data);
  },

  async deleteAppointment(id: string): Promise<{ message: string }> {
    apiCache.invalidatePattern('^appointments:');
    return api.delete<{ message: string }>(`/appointments/admin/appointments/${id}`);
  },

  async getTodayAppointments(): Promise<{ appointments: Appointment[]; summary: Record<string, number> }> {
    return apiCache.getOrFetch(
      'appointments:today',
      () => api.get<{ appointments: Appointment[]; summary: Record<string, number> }>('/appointments/admin/today'),
      CACHE_TTL.SHORT
    );
  },

  async getRescheduleRequests(): Promise<{ requests: Array<any> }> {
    return api.get<{ requests: Array<any> }>('/appointments/admin/reschedule-requests');
  },

  async getRecentActivity(): Promise<{ activities: Array<any> }> {
    return api.get<{ activities: Array<any> }>('/appointments/admin/recent-activity');
  },

  async getStats(): Promise<AppointmentStats> {
    return apiCache.getOrFetch(
      'appointments:stats',
      () => api.get<AppointmentStats>('/appointments/admin/stats'),
      CACHE_TTL.MEDIUM
    );
  },

  async getAdvancedAnalytics(): Promise<AdvancedAnalyticsResponse> {
    return apiCache.getOrFetch(
      'appointments:analytics',
      () => api.get<AdvancedAnalyticsResponse>('/appointments/admin/analytics'),
      CACHE_TTL.LONG
    );
  },

  invalidateCache(): void {
    apiCache.invalidatePattern('^appointments:');
  },
};
