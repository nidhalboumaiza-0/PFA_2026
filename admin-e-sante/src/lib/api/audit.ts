import { api } from './client';
import type {
  AuditLog,
  AuditLogParams,
  AuditStats,
  PaginatedResponse,
} from './types';

// Audit Logs Service
export const auditService = {
  async getLogs(params?: AuditLogParams): Promise<PaginatedResponse<AuditLog>> {
    const queryParams = new URLSearchParams();
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.action) queryParams.append('action', params.action);
    if (params?.category) queryParams.append('category', params.category);
    if (params?.startDate) queryParams.append('startDate', params.startDate);
    if (params?.endDate) queryParams.append('endDate', params.endDate);

    const queryString = queryParams.toString();
    return api.get<PaginatedResponse<AuditLog>>(`/audit/logs${queryString ? `?${queryString}` : ''}`);
  },

  async getLogById(id: string): Promise<{ log: AuditLog }> {
    return api.get<{ log: AuditLog }>(`/audit/logs/${id}`);
  },

  async getStats(): Promise<AuditStats> {
    return api.get<AuditStats>('/audit/stats');
  },

  async getUserActivity(userId: string, params?: { page?: number; limit?: number; startDate?: string; endDate?: string }): Promise<PaginatedResponse<AuditLog>> {
    const queryParams = new URLSearchParams();
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.startDate) queryParams.append('startDate', params.startDate);
    if (params?.endDate) queryParams.append('endDate', params.endDate);

    const queryString = queryParams.toString();
    return api.get<PaginatedResponse<AuditLog>>(`/audit/users/${userId}/activity${queryString ? `?${queryString}` : ''}`);
  },

  async getPatientAccessLog(patientId: string, params?: { page?: number; limit?: number; startDate?: string; endDate?: string }): Promise<{ logs: Array<any>; pagination: any }> {
    const queryParams = new URLSearchParams();
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.startDate) queryParams.append('startDate', params.startDate);
    if (params?.endDate) queryParams.append('endDate', params.endDate);

    const queryString = queryParams.toString();
    return api.get<{ logs: Array<any>; pagination: any }>(`/audit/patients/${patientId}/access-log${queryString ? `?${queryString}` : ''}`);
  },

  async getSecurityEvents(params?: { page?: number; limit?: number; severity?: string; eventType?: string }): Promise<{ events: Array<any>; pagination: any }> {
    const queryParams = new URLSearchParams();
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.severity) queryParams.append('severity', params.severity);
    if (params?.eventType) queryParams.append('eventType', params.eventType);

    const queryString = queryParams.toString();
    return api.get<{ events: Array<any>; pagination: any }>(`/audit/security-events${queryString ? `?${queryString}` : ''}`);
  },

  async markAsReviewed(logId: string, notes: string): Promise<{ message: string; log: AuditLog }> {
    return api.put<{ message: string; log: AuditLog }>(`/audit/logs/${logId}/review`, { reviewNotes: notes });
  },

  async exportLogs(params?: { format?: string; startDate?: string; endDate?: string; category?: string }): Promise<any> {
    const queryParams = new URLSearchParams();
    if (params?.format) queryParams.append('format', params.format);
    if (params?.startDate) queryParams.append('startDate', params.startDate);
    if (params?.endDate) queryParams.append('endDate', params.endDate);
    if (params?.category) queryParams.append('category', params.category);

    const queryString = queryParams.toString();
    return api.get<any>(`/audit/export${queryString ? `?${queryString}` : ''}`);
  },

  async getHipaaComplianceReport(params?: { startDate?: string; endDate?: string }): Promise<any> {
    const queryParams = new URLSearchParams();
    if (params?.startDate) queryParams.append('startDate', params.startDate);
    if (params?.endDate) queryParams.append('endDate', params.endDate);

    const queryString = queryParams.toString();
    return api.get<any>(`/audit/compliance/hipaa-report${queryString ? `?${queryString}` : ''}`);
  },

  async getActivityReport(params?: { startDate?: string; endDate?: string }): Promise<any> {
    const queryParams = new URLSearchParams();
    if (params?.startDate) queryParams.append('startDate', params.startDate);
    if (params?.endDate) queryParams.append('endDate', params.endDate);

    const queryString = queryParams.toString();
    return api.get<any>(`/audit/compliance/activity-report${queryString ? `?${queryString}` : ''}`);
  },
};
