'use client';

import { useEffect, useState, useCallback, useRef } from 'react';
import { useSocket } from '@/components/providers/socket-provider';
import { dashboardService } from '@/lib/api';
import type { DashboardStats } from '@/lib/api';

export function useRealtimeStats() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const { notificationSocket, userSocket, appointmentSocket } = useSocket();
  const fetchedRef = useRef(false);

  const fetchStats = useCallback(async (forceRefresh = false) => {
    try {
      // Use cached data by default for fast loading
      const data = await dashboardService.getStats(forceRefresh);
      setStats(data);
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch stats:', error);
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    // Only fetch once on mount, use cache for subsequent renders
    if (!fetchedRef.current) {
      fetchedRef.current = true;
      fetchStats();
    }
  }, [fetchStats]);

  // Real-time updates
  useEffect(() => {
    if (!userSocket || !appointmentSocket || !notificationSocket) return;

    // User registered - increment count
    userSocket.on('new_user_registered', (data: any) => {
      setStats((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          overview: {
            ...prev.overview,
            totalUsers: (prev.overview.totalUsers || 0) + 1,
            totalDoctors:
              data.role === 'doctor'
                ? (prev.overview.totalDoctors || 0) + 1
                : prev.overview.totalDoctors,
            totalPatients:
              data.role === 'patient'
                ? (prev.overview.totalPatients || 0) + 1
                : prev.overview.totalPatients,
          },
          users: {
            ...prev.users,
            total: (prev.users.total || 0) + 1,
            doctors:
              data.role === 'doctor'
                ? {
                    ...prev.users.doctors,
                    total: (prev.users.doctors.total || 0) + 1,
                  }
                : prev.users.doctors,
            patients:
              data.role === 'patient'
                ? {
                    ...prev.users.patients,
                    total: (prev.users.patients.total || 0) + 1,
                  }
                : prev.users.patients,
          },
        };
      });
    });

    // Doctor verified - decrement pending
    userSocket.on('doctor_verified', () => {
      setStats((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          users: {
            ...prev.users,
            doctors: {
              ...prev.users.doctors,
              pendingVerification: Math.max(
                0,
                (prev.users.doctors.pendingVerification || 1) - 1
              ),
              verified: (prev.users.doctors.verified || 0) + 1,
            },
          },
        };
      });
    });

    // Appointment created - increment pending
    appointmentSocket.on('appointment_created', () => {
      setStats((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          overview: {
            ...prev.overview,
            totalAppointments: (prev.overview.totalAppointments || 0) + 1,
          },
          appointments: {
            ...prev.appointments,
            total: (prev.appointments.total || 0) + 1,
            byStatus: {
              ...prev.appointments.byStatus,
              pending: (prev.appointments.byStatus?.pending || 0) + 1,
            },
            today: {
              ...prev.appointments.today,
              total: (prev.appointments.today?.total || 0) + 1,
            },
          },
        };
      });
    });

    // Appointment status changed
    appointmentSocket.on('appointment_status_changed', (data: any) => {
      setStats((prev) => {
        if (!prev) return prev;
        const newStats = { ...prev };
        if (data.oldStatus && newStats.appointments?.byStatus) {
          newStats.appointments.byStatus[data.oldStatus] = Math.max(
            0,
            (newStats.appointments.byStatus[data.oldStatus] || 1) - 1
          );
        }
        if (data.newStatus && newStats.appointments?.byStatus) {
          newStats.appointments.byStatus[data.newStatus] =
            (newStats.appointments.byStatus[data.newStatus] || 0) + 1;
        }
        return newStats;
      });
    });

    // Admin alert - increment unread
    notificationSocket.on('admin_alert', () => {
      setStats((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          notifications: {
            ...prev.notifications,
            unreadAlerts: (prev.notifications.unreadAlerts || 0) + 1,
          },
        };
      });
    });

    return () => {
      userSocket.off('new_user_registered');
      userSocket.off('doctor_verified');
      appointmentSocket.off('appointment_created');
      appointmentSocket.off('appointment_status_changed');
      notificationSocket.off('admin_alert');
    };
  }, [userSocket, appointmentSocket, notificationSocket]);

  return { stats, loading, refetch: fetchStats };
}
