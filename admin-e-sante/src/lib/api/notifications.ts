import { api } from './client';
import type {
  Notification,
  NotificationStats,
  PaginatedResponse,
} from './types';

// Backend response type (different from generic PaginatedResponse)
interface NotificationsListResponse {
  notifications: Notification[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

// Notifications Service
export const notificationsService = {
  async getNotifications(page: number = 1, limit: number = 20): Promise<PaginatedResponse<Notification>> {
    const response = await api.get<NotificationsListResponse>(`/notifications/admin/notifications?page=${page}&limit=${limit}`);
    // Transform backend response to match PaginatedResponse<Notification>
    return {
      data: response.notifications || [],
      pagination: response.pagination,
    };
  },

  async getUnreadCount(): Promise<{ unreadCount: number }> {
    return api.get<{ unreadCount: number }>('/notifications/unread-count');
  },

  async markAsRead(id: string): Promise<{ message: string }> {
    return api.put<{ message: string }>(`/notifications/${id}/read`);
  },

  async markAllAsRead(): Promise<{ message: string }> {
    return api.put<{ message: string }>('/notifications/mark-all-read');
  },

  async getStats(): Promise<NotificationStats> {
    return api.get<NotificationStats>('/notifications/admin/stats');
  },

  async getRecentActivity(): Promise<{ activities: Array<any> }> {
    return api.get<{ activities: Array<any> }>('/notifications/admin/recent-activity');
  },

  async getPreferencesSummary(): Promise<any> {
    return api.get<any>('/notifications/admin/preferences-summary');
  },
};
