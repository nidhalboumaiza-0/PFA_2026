import { api } from './client';
import type { Review, ReviewSummary, PaginatedResponse } from './types';

export interface AdminReviewsResponse {
  reviews: Review[];
  pagination: {
    currentPage: number;
    totalPages: number;
    totalReviews: number;
    hasMore: boolean;
  };
  stats: {
    averageRating: number;
    totalReviews: number;
    distribution: {
      5: number;
      4: number;
      3: number;
      2: number;
      1: number;
    };
  };
}

export interface DoctorReviewStats {
  doctorId: string;
  averageRating: number;
  totalReviews: number;
  totalWithComments: number;
  distribution: {
    5: number;
    4: number;
    3: number;
    2: number;
    1: number;
  };
  latestReview: string;
  oldestReview: string;
}

export interface AdvancedStatsResponse {
  overall: {
    averageRating: number;
    totalReviews: number;
    totalWithComments: number;
    commentRate: number;
    distribution: {
      5: number;
      4: number;
      3: number;
      2: number;
      1: number;
    };
    positiveRate: number;
    negativeRate: number;
  };
  doctorStats: DoctorReviewStats[];
  reviewsOverTime: Array<{
    _id: string;
    count: number;
    avgRating: number;
  }>;
  topRatedDoctors: Array<{
    doctorId: string;
    averageRating: number;
    totalReviews: number;
  }>;
  lowestRatedDoctors: Array<{
    doctorId: string;
    averageRating: number;
    totalReviews: number;
  }>;
  recentReviews: Review[];
}

// Reviews Service
export const reviewsService = {
  async getAllReviews(page: number = 1, limit: number = 10, rating?: number, doctorId?: string): Promise<AdminReviewsResponse> {
    let url = `/reviews/admin?page=${page}&limit=${limit}`;
    if (rating) {
      url += `&rating=${rating}`;
    }
    if (doctorId) {
      url += `&doctorId=${doctorId}`;
    }
    const response = await api.get<AdminReviewsResponse>(url);
    return response;
  },

  async getAdvancedStats(): Promise<AdvancedStatsResponse> {
    return api.get<AdvancedStatsResponse>('/reviews/admin/stats');
  },

  async getDoctorReviews(doctorId: string, page: number = 1, limit: number = 10): Promise<{ reviews: Review[]; summary: ReviewSummary; pagination: any }> {
    return api.get<{ reviews: Review[]; summary: ReviewSummary; pagination: any }>(`/reviews/doctors/${doctorId}?page=${page}&limit=${limit}`);
  },

  async getAppointmentReview(appointmentId: string): Promise<{ review: Review }> {
    return api.get<{ review: Review }>(`/reviews/appointments/${appointmentId}`);
  },

  async deleteReview(reviewId: string): Promise<void> {
    return api.delete(`/reviews/admin/${reviewId}`);
  },
};
