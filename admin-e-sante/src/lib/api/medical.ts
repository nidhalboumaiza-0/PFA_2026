import { api } from './client';
import type { MedicalRecordsStats } from './types';

// Medical Records Service
export const medicalService = {
  async getStats(): Promise<MedicalRecordsStats> {
    return api.get<MedicalRecordsStats>('/medical/admin/stats');
  },

  async getConsultationStatistics(): Promise<{ statistics: any }> {
    return api.get<{ statistics: any }>('/medical/statistics/consultations');
  },

  async getDocumentStatistics(): Promise<{ statistics: any }> {
    return api.get<{ statistics: any }>('/medical/documents/statistics');
  },
};
