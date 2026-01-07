import { api } from './client';
import { apiCache, CACHE_KEYS, CACHE_TTL } from './cache';
import type {
  User,
  UserListParams,
  UserStats,
  PaginatedResponse,
} from './types';

// Backend response type (different from frontend expected type)
interface UsersListResponse {
  users: User[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

// Users Service with caching
export const usersService = {
  async getUsers(params?: UserListParams): Promise<PaginatedResponse<User>> {
    const queryParams = new URLSearchParams();
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.role) queryParams.append('role', params.role);
    if (params?.status) queryParams.append('status', params.status);
    if (params?.search) queryParams.append('search', params.search);

    const cacheKey = CACHE_KEYS.USERS_LIST(
      params?.page || 1,
      params?.role || 'all',
      params?.status || 'all',
      params?.search || ''
    );

    const response = await apiCache.getOrFetch(
      cacheKey,
      async () => {
        const queryString = queryParams.toString();
        return api.get<UsersListResponse>(`/users/admin/users${queryString ? `?${queryString}` : ''}`);
      },
      CACHE_TTL.SHORT
    );
    
    // Transform backend response to match frontend expected format
    return {
      data: response.users || [],
      pagination: response.pagination
    };
  },

  async getUserById(id: string): Promise<{ user: User }> {
    return apiCache.getOrFetch(
      `users:${id}`,
      () => api.get<{ user: User }>(`/users/admin/users/${id}`),
      CACHE_TTL.MEDIUM
    );
  },

  async updateUserStatus(id: string, status: { isActive: boolean; reason?: string }): Promise<{ message: string; user: User }> {
    // Invalidate user caches after update
    apiCache.invalidatePattern('^users:');
    return api.put<{ message: string; user: User }>(`/users/admin/users/${id}/status`, status);
  },

  async deleteUser(id: string): Promise<{ message: string }> {
    // Invalidate user caches after delete
    apiCache.invalidatePattern('^users:');
    return api.delete<{ message: string }>(`/users/admin/users/${id}`);
  },

  async getStats(): Promise<UserStats> {
    return apiCache.getOrFetch(
      'users:stats',
      () => api.get<UserStats>('/users/admin/stats'),
      CACHE_TTL.MEDIUM
    );
  },

  async verifyDoctor(id: string, isVerified: boolean): Promise<{ message: string }> {
    // Invalidate user caches after verification
    apiCache.invalidatePattern('^users:');
    return api.put<{ message: string }>(`/users/admin/doctors/${id}/verify`, { isVerified });
  },

  // Force refresh users list
  invalidateCache(): void {
    apiCache.invalidatePattern('^users:');
  },
};
