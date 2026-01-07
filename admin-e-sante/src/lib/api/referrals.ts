import { api } from './client';
import type {
  Referral,
  ReferralStats,
  PaginatedResponse,
} from './types';

// Referrals Service
export const referralsService = {
  async getStatistics(): Promise<ReferralStats> {
    return api.get<ReferralStats>('/referrals/statistics');
  },

  async getSentReferrals(params?: { page?: number; limit?: number; status?: string; priority?: string }): Promise<PaginatedResponse<Referral>> {
    const queryParams = new URLSearchParams();
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.status) queryParams.append('status', params.status);
    if (params?.priority) queryParams.append('priority', params.priority);

    const queryString = queryParams.toString();
    return api.get<PaginatedResponse<Referral>>(`/referrals/sent${queryString ? `?${queryString}` : ''}`);
  },

  async getReceivedReferrals(params?: { page?: number; limit?: number; status?: string; priority?: string }): Promise<PaginatedResponse<Referral>> {
    const queryParams = new URLSearchParams();
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());
    if (params?.status) queryParams.append('status', params.status);
    if (params?.priority) queryParams.append('priority', params.priority);

    const queryString = queryParams.toString();
    return api.get<PaginatedResponse<Referral>>(`/referrals/received${queryString ? `?${queryString}` : ''}`);
  },
};
