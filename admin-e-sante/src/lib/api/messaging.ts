import { api } from './client';
import type { MessageStats, PaginatedResponse } from './types';

// Messaging Service
export const messagingService = {
  async getStats(): Promise<MessageStats> {
    return api.get<MessageStats>('/messaging/admin/stats');
  },

  async getRecentActivity(): Promise<{ activities: Array<any> }> {
    return api.get<{ activities: Array<any> }>('/messaging/admin/recent-activity');
  },

  async getAllConversations(page: number = 1, limit: number = 20): Promise<PaginatedResponse<any>> {
    return api.get<PaginatedResponse<any>>(`/messaging/admin/conversations?page=${page}&limit=${limit}`);
  },
};
