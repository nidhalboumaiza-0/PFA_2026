# 🔴 REAL-TIME DASHBOARD UPDATE - Socket.IO Integration

**CRITICAL: The dashboard MUST be 100% real-time.** All data should update automatically via WebSocket connections without page refresh.

---

## Install Dependencies

```bash
npm install socket.io-client
```

---

## Socket Provider (Wrap your app with this)

Create this file and wrap your admin layout with `<SocketProvider>`:

```typescript
// providers/socket-provider.tsx
'use client';
import { createContext, useContext, useEffect, useState } from 'react';
import { io, Socket } from 'socket.io-client';

interface SocketContextType {
  notificationSocket: Socket | null;
  userSocket: Socket | null;
  appointmentSocket: Socket | null;
  isConnected: boolean;
}

const SocketContext = createContext<SocketContextType>({
  notificationSocket: null,
  userSocket: null,
  appointmentSocket: null,
  isConnected: false
});

export function SocketProvider({ children }: { children: React.ReactNode }) {
  const [sockets, setSockets] = useState<SocketContextType>({
    notificationSocket: null,
    userSocket: null,
    appointmentSocket: null,
    isConnected: false
  });

  useEffect(() => {
    const token = localStorage.getItem('accessToken');
    if (!token) return;

    // 1. Notification Socket (Port 3007)
    const notifSocket = io('http://localhost:3007', {
      auth: { token },
      transports: ['websocket', 'polling']
    });

    // 2. User Socket (via API Gateway)
    const usrSocket = io('http://localhost:3000/user-socket', {
      auth: { token },
      transports: ['websocket', 'polling']
    });

    // 3. Appointment Socket (via API Gateway)
    const rdvSocket = io('http://localhost:3000/rdv-socket', {
      auth: { token },
      transports: ['websocket', 'polling']
    });

    notifSocket.on('connect', () => {
      console.log('✅ Notification socket connected');
      setSockets(prev => ({ ...prev, isConnected: true }));
    });

    notifSocket.on('disconnect', () => {
      setSockets(prev => ({ ...prev, isConnected: false }));
    });

    setSockets({
      notificationSocket: notifSocket,
      userSocket: usrSocket,
      appointmentSocket: rdvSocket,
      isConnected: false
    });

    return () => {
      notifSocket.disconnect();
      usrSocket.disconnect();
      rdvSocket.disconnect();
    };
  }, []);

  return (
    <SocketContext.Provider value={sockets}>
      {children}
    </SocketContext.Provider>
  );
}

export const useSocket = () => useContext(SocketContext);
```

---

## Wrap Admin Layout

```typescript
// app/admin/layout.tsx
import { SocketProvider } from '@/providers/socket-provider';

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <SocketProvider>
      <div className="admin-layout">
        {/* Your sidebar, header, etc */}
        {children}
      </div>
    </SocketProvider>
  );
}
```

---

## Socket Events to Listen For

### 1. Notification Events (Port 3007)

```typescript
const { notificationSocket } = useSocket();

useEffect(() => {
  if (!notificationSocket) return;

  notificationSocket.on('new_notification', (notification) => {
    // Show toast notification
    // Update notification badge count
    // Add to notifications list
    toast.info(notification.title);
  });

  notificationSocket.on('admin_alert', (alert) => {
    // Show critical alert modal/toast
    // { title, body, priority, actionData }
    toast.error(`🚨 ${alert.title}: ${alert.body}`);
  });

  return () => {
    notificationSocket.off('new_notification');
    notificationSocket.off('admin_alert');
  };
}, [notificationSocket]);
```

### 2. User Events (/user-socket)

```typescript
const { userSocket } = useSocket();

useEffect(() => {
  if (!userSocket) return;

  userSocket.on('new_user_registered', (data) => {
    // { userId, email, role, name, timestamp }
    // Update user count, add to users list
    toast.success(`New ${data.role} registered: ${data.name}`);
  });

  userSocket.on('user_status_changed', (data) => {
    // { userId, isActive, reason }
    // Update user status in table
  });

  userSocket.on('doctor_verified', (data) => {
    // { doctorId, verifiedBy, timestamp }
    // Update pending verifications count
    toast.success('Doctor verified successfully');
  });

  userSocket.on('user_deleted', (data) => {
    // { userId }
    // Remove from users list
  });

  return () => {
    userSocket.off('new_user_registered');
    userSocket.off('user_status_changed');
    userSocket.off('doctor_verified');
    userSocket.off('user_deleted');
  };
}, [userSocket]);
```

### 3. Appointment Events (/rdv-socket)

```typescript
const { appointmentSocket } = useSocket();

useEffect(() => {
  if (!appointmentSocket) return;

  appointmentSocket.on('appointment_created', (data) => {
    // { appointment }
    // Update today's appointments count, add to list
    toast.info('New appointment booked');
  });

  appointmentSocket.on('appointment_status_changed', (data) => {
    // { appointmentId, newStatus, oldStatus, updatedBy }
    // Update appointment in table, update stats
  });

  appointmentSocket.on('appointment_cancelled', (data) => {
    // { appointmentId, reason }
    toast.warning('Appointment cancelled');
  });

  appointmentSocket.on('reschedule_requested', (data) => {
    // { appointmentId, requestedDate, requestedTime, reason }
    // Update reschedule requests badge
    toast.info('New reschedule request');
  });

  appointmentSocket.on('appointment_rescheduled', (data) => {
    // { appointmentId, newDate, newTime }
  });

  return () => {
    appointmentSocket.off('appointment_created');
    appointmentSocket.off('appointment_status_changed');
    appointmentSocket.off('appointment_cancelled');
    appointmentSocket.off('reschedule_requested');
    appointmentSocket.off('appointment_rescheduled');
  };
}, [appointmentSocket]);
```

---

## Real-time Dashboard Stats Hook

```typescript
// hooks/useRealtimeStats.ts
import { useEffect, useState, useCallback } from 'react';
import { useSocket } from '@/providers/socket-provider';

export function useRealtimeStats() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const { notificationSocket, userSocket, appointmentSocket } = useSocket();

  const fetchStats = useCallback(async () => {
    const token = localStorage.getItem('accessToken');
    const res = await fetch('http://localhost:3000/api/v1/admin/dashboard/stats', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setStats(data);
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchStats();
  }, [fetchStats]);

  // Real-time updates
  useEffect(() => {
    if (!userSocket || !appointmentSocket || !notificationSocket) return;

    // User registered - increment count
    userSocket.on('new_user_registered', (data) => {
      setStats((prev: any) => ({
        ...prev,
        overview: {
          ...prev?.overview,
          totalUsers: (prev?.overview?.totalUsers || 0) + 1,
          [`total${data.role === 'doctor' ? 'Doctors' : 'Patients'}`]: 
            (prev?.overview?.[`total${data.role === 'doctor' ? 'Doctors' : 'Patients'}`] || 0) + 1
        }
      }));
    });

    // Doctor verified - decrement pending
    userSocket.on('doctor_verified', () => {
      setStats((prev: any) => ({
        ...prev,
        users: {
          ...prev?.users,
          doctors: {
            ...prev?.users?.doctors,
            pendingVerification: Math.max(0, (prev?.users?.doctors?.pendingVerification || 1) - 1),
            verified: (prev?.users?.doctors?.verified || 0) + 1
          }
        }
      }));
    });

    // Appointment created - increment pending
    appointmentSocket.on('appointment_created', () => {
      setStats((prev: any) => ({
        ...prev,
        appointments: {
          ...prev?.appointments,
          total: (prev?.appointments?.total || 0) + 1,
          byStatus: {
            ...prev?.appointments?.byStatus,
            pending: (prev?.appointments?.byStatus?.pending || 0) + 1
          }
        }
      }));
    });

    // Appointment status changed
    appointmentSocket.on('appointment_status_changed', (data) => {
      setStats((prev: any) => {
        const newStats = { ...prev };
        if (data.oldStatus && newStats.appointments?.byStatus) {
          newStats.appointments.byStatus[data.oldStatus] = 
            Math.max(0, (newStats.appointments.byStatus[data.oldStatus] || 1) - 1);
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
      setStats((prev: any) => ({
        ...prev,
        notifications: {
          ...prev?.notifications,
          unreadAlerts: (prev?.notifications?.unreadAlerts || 0) + 1
        }
      }));
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
```

---

## Real-time Table Example (Users Page)

```typescript
// app/admin/users/page.tsx
'use client';
import { useEffect, useState } from 'react';
import { useSocket } from '@/providers/socket-provider';
import { toast } from 'sonner';

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const { userSocket } = useSocket();

  // Initial fetch
  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    const token = localStorage.getItem('accessToken');
    const res = await fetch('http://localhost:3000/api/v1/users/admin/users', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setUsers(data.users);
    setLoading(false);
  };

  // Real-time updates
  useEffect(() => {
    if (!userSocket) return;

    userSocket.on('new_user_registered', (newUser) => {
      setUsers(prev => [newUser, ...prev]);
      toast.success(`New user registered: ${newUser.name}`);
    });

    userSocket.on('user_status_changed', (data) => {
      setUsers(prev => prev.map(u => 
        u._id === data.userId ? { ...u, isActive: data.isActive } : u
      ));
      toast.info(`User status updated`);
    });

    userSocket.on('user_deleted', (data) => {
      setUsers(prev => prev.filter(u => u._id !== data.userId));
      toast.warning(`User deleted`);
    });

    return () => {
      userSocket.off('new_user_registered');
      userSocket.off('user_status_changed');
      userSocket.off('user_deleted');
    };
  }, [userSocket]);

  return (
    <div>
      {/* Your DataTable component with users */}
    </div>
  );
}
```

---

## Real-time Appointments Table

```typescript
// app/admin/appointments/page.tsx
'use client';
import { useEffect, useState } from 'react';
import { useSocket } from '@/providers/socket-provider';
import { toast } from 'sonner';

export default function AppointmentsPage() {
  const [appointments, setAppointments] = useState<any[]>([]);
  const { appointmentSocket } = useSocket();

  useEffect(() => {
    fetchAppointments();
  }, []);

  useEffect(() => {
    if (!appointmentSocket) return;

    appointmentSocket.on('appointment_created', (data) => {
      setAppointments(prev => [data.appointment, ...prev]);
      toast.success('New appointment booked');
    });

    appointmentSocket.on('appointment_status_changed', (data) => {
      setAppointments(prev => prev.map(a => 
        a._id === data.appointmentId ? { ...a, status: data.newStatus } : a
      ));
    });

    appointmentSocket.on('appointment_cancelled', (data) => {
      setAppointments(prev => prev.map(a => 
        a._id === data.appointmentId ? { ...a, status: 'cancelled' } : a
      ));
    });

    return () => {
      appointmentSocket.off('appointment_created');
      appointmentSocket.off('appointment_status_changed');
      appointmentSocket.off('appointment_cancelled');
    };
  }, [appointmentSocket]);

  return (
    <div>
      {/* Your appointments table */}
    </div>
  );
}
```

---

## Connection Status Indicator (Header)

Show users when real-time is connected:

```typescript
// components/connection-indicator.tsx
'use client';
import { useSocket } from '@/providers/socket-provider';

export function ConnectionIndicator() {
  const { isConnected } = useSocket();
  
  return (
    <div className="flex items-center gap-2">
      <div className={`w-2 h-2 rounded-full animate-pulse ${
        isConnected ? 'bg-green-500' : 'bg-red-500'
      }`} />
      <span className="text-xs text-muted-foreground">
        {isConnected ? 'Live' : 'Disconnected'}
      </span>
    </div>
  );
}
```

---

## Notification Bell with Real-time Badge

```typescript
// components/notification-bell.tsx
'use client';
import { useEffect, useState } from 'react';
import { Bell } from 'lucide-react';
import { useSocket } from '@/providers/socket-provider';

export function NotificationBell() {
  const [unreadCount, setUnreadCount] = useState(0);
  const { notificationSocket } = useSocket();

  // Fetch initial count
  useEffect(() => {
    fetchUnreadCount();
  }, []);

  // Real-time updates
  useEffect(() => {
    if (!notificationSocket) return;

    notificationSocket.on('new_notification', () => {
      setUnreadCount(prev => prev + 1);
    });

    notificationSocket.on('admin_alert', () => {
      setUnreadCount(prev => prev + 1);
    });

    return () => {
      notificationSocket.off('new_notification');
      notificationSocket.off('admin_alert');
    };
  }, [notificationSocket]);

  const fetchUnreadCount = async () => {
    const token = localStorage.getItem('accessToken');
    const res = await fetch('http://localhost:3000/api/v1/notifications/unread-count', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    setUnreadCount(data.unreadCount);
  };

  return (
    <button className="relative">
      <Bell className="h-5 w-5" />
      {unreadCount > 0 && (
        <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-4 w-4 flex items-center justify-center">
          {unreadCount > 99 ? '99+' : unreadCount}
        </span>
      )}
    </button>
  );
}
```

---

## Summary

1. **Install**: `npm install socket.io-client`
2. **Create**: `providers/socket-provider.tsx` 
3. **Wrap**: Admin layout with `<SocketProvider>`
4. **Use**: `useSocket()` hook in any component
5. **Listen**: To socket events and update state in real-time
6. **Show**: Connection status indicator in header

All tables, stats cards, and badges will update automatically when data changes on the backend! 🚀
