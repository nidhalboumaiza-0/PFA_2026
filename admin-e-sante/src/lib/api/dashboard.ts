import { api } from './client';
import { apiCache, CACHE_KEYS, CACHE_TTL } from './cache';
import type {
  DashboardStats,
  QuickStats,
  PlatformHealth,
} from './types';

// Dashboard Service with caching
export const dashboardService = {
  async getStats(forceRefresh = false): Promise<DashboardStats> {
    if (forceRefresh) {
      apiCache.invalidate(CACHE_KEYS.DASHBOARD_STATS);
    }
    return apiCache.getOrFetch(
      CACHE_KEYS.DASHBOARD_STATS,
      () => api.get<DashboardStats>('/admin/dashboard/stats'),
      CACHE_TTL.MEDIUM
    );
  },

  async getQuickStats(): Promise<QuickStats> {
    return apiCache.getOrFetch(
      'dashboard:quick-stats',
      () => api.get<QuickStats>('/admin/dashboard/quick-stats'),
      CACHE_TTL.SHORT
    );
  },

  async getHealth(forceRefresh = false): Promise<PlatformHealth> {
    if (forceRefresh) {
      apiCache.invalidate(CACHE_KEYS.DASHBOARD_HEALTH);
    }
    return apiCache.getOrFetch(
      CACHE_KEYS.DASHBOARD_HEALTH,
      () => api.get<PlatformHealth>('/admin/dashboard/health'),
      CACHE_TTL.SHORT
    );
  },

  async getRecentActivity(): Promise<{ activities: Array<any> }> {
    return apiCache.getOrFetch(
      'dashboard:recent-activity',
      () => api.get<{ activities: Array<any> }>('/admin/dashboard/recent-activity'),
      CACHE_TTL.MEDIUM
    );
  },

  // Force refresh all dashboard data
  refreshAll(): void {
    apiCache.invalidatePattern('^dashboard:');
  },
};
