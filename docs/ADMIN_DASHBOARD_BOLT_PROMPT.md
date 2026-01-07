# E-Santé Admin Dashboard - Bolt.new Prompt

Create a modern, responsive **REAL-TIME** admin dashboard for a healthcare application called "E-Santé" using **Next.js 14+ (App Router)**, **TypeScript**, **Tailwind CSS**, and **shadcn/ui** components.

## 🔴 KEY REQUIREMENTS:
1. **Real-time updates via Socket.IO** - Dashboard MUST update live without page refresh
2. **No database** - Connect to existing REST APIs only
3. **Professional UI** - Clean, modern healthcare theme

---

## ⚠️ IMPORTANT - NO DATABASE NEEDED

**DO NOT create any database, mock data, or backend logic.**

The backend is **already fully implemented** and running. Your job is to create **ONLY the frontend** that connects to our existing REST APIs.

- ❌ Do NOT create MongoDB/PostgreSQL/any database
- ❌ Do NOT create API routes with mock data
- ❌ Do NOT create fake/hardcoded data
- ✅ DO create a frontend that calls our existing API endpoints
- ✅ DO use fetch/axios to make HTTP requests to the real backend
- ✅ DO handle loading states, errors, and empty states

The APIs listed below are **real endpoints** from our running backend. Just connect to them!

---

## Authentication

The admin logs in and receives a JWT token. Store it in localStorage and include it in all API requests as:

```
Authorization: Bearer <token>
```

**Base URL:** `http://localhost:3000/api/v1`

**Login Endpoint:**
```
POST /auth/login
Body: { "email": "admin@esante.tn", "password": "Admin123!" }
Response: { "user": {...}, "tokens": { "accessToken": "...", "refreshToken": "..." } }
```

---

## Dashboard Pages & API Endpoints

### 1. Dashboard Home (`/admin`)

Display aggregated statistics cards and charts from all microservices.

**Main Dashboard Stats (Aggregated from all services):**
```
GET /admin/dashboard/stats
Response: {
  "overview": {
    "totalUsers": 150,
    "totalDoctors": 50,
    "totalPatients": 100,
    "totalAppointments": 500,
    "totalMessages": 10000,
    "totalNotifications": 5000,
    "platformHealth": "healthy"
  },
  "users": {
    "total": 150,
    "doctors": { "total": 50, "active": 48, "verified": 45, "pendingVerification": 5 },
    "patients": { "total": 100, "active": 95 },
    "newRegistrations": { "today": { "total": 5 }, "thisWeek": { "total": 25 }, "thisMonth": { "total": 80 } },
    "specialtyDistribution": [{ "_id": "Cardiology", "count": 10 }]
  },
  "appointments": {
    "total": 500,
    "byStatus": { "pending": 20, "confirmed": 50, "completed": 400, "cancelled": 30 },
    "completionRate": "80%",
    "today": { "total": 15, "upcoming": 10 },
    "thisWeek": 85,
    "thisMonth": 320,
    "topDoctors": [{ "doctorId": "...", "name": "Dr. Ahmed", "count": 50 }],
    "busiestHours": [{ "hour": 9, "count": 100 }]
  },
  "messaging": {
    "totalConversations": 500,
    "totalMessages": 10000,
    "activeConversations": 50
  },
  "notifications": {
    "totalSent": 5000,
    "deliveryRate": "95%",
    "unreadAlerts": 10
  }
}
```

**Quick Stats (Faster response for header):**
```
GET /admin/dashboard/quick-stats
Response: {
  "totalUsers": 150,
  "pendingVerifications": 5,
  "todayAppointments": 15,
  "unreadAlerts": 3
}
```

**Platform Health:**
```
GET /admin/dashboard/health
Response: {
  "services": {
    "auth-service": { "status": "healthy", "responseTime": 50 },
    "user-service": { "status": "healthy", "responseTime": 45 },
    "rdv-service": { "status": "healthy", "responseTime": 60 },
    "notification-service": { "status": "healthy", "responseTime": 40 },
    "messaging-service": { "status": "healthy", "responseTime": 55 },
    "medical-records-service": { "status": "healthy", "responseTime": 70 },
    "audit-service": { "status": "healthy", "responseTime": 35 }
  },
  "overall": "healthy"
}
```

**Recent Activity (Cross-service):**
```
GET /admin/dashboard/recent-activity
Response: {
  "activities": [
    { "type": "user_registered", "description": "New patient registered", "timestamp": "..." },
    { "type": "appointment_created", "description": "Appointment booked", "timestamp": "..." },
    { "type": "doctor_verified", "description": "Dr. Ahmed verified", "timestamp": "..." }
  ]
}
```

---

### 2. User Management (`/admin/users`)

List, search, filter, and manage all users (patients & doctors).

```
GET /users/admin/users?page=1&limit=20&role=all&status=all&search=
Response: {
  "users": [
    {
      "_id": "...",
      "email": "...",
      "role": "patient|doctor",
      "isActive": true,
      "isEmailVerified": true,
      "createdAt": "...",
      "profile": {
        "firstName": "...",
        "lastName": "...",
        "phone": "..."
      }
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 150, "pages": 8 }
}
```

```
GET /users/admin/users/:id
Response: { "user": { ... full user details with profile ... } }
```

```
PUT /users/admin/users/:id/status
Body: { "isActive": true|false, "reason": "..." }
Response: { "message": "User status updated", "user": {...} }
```

```
DELETE /users/admin/users/:id
Response: { "message": "User deleted successfully" }
```

```
GET /users/admin/stats
Response: {
  "totalUsers": 150,
  "totalPatients": 100,
  "totalDoctors": 50,
  "activeUsers": 140,
  "verifiedUsers": 145,
  "newUsersToday": 5,
  "newUsersThisWeek": 25,
  "newUsersThisMonth": 80
}
```

---

### 3. Doctor Verification (`/admin/doctors`)

List pending doctor verifications and approve/reject them.

```
GET /users/admin/users?role=doctor&verified=pending
Response: { "users": [...doctors pending verification...] }
```

```
PUT /users/admin/doctors/:id/verify
Body: { "isVerified": true }
Response: { "message": "Doctor verified successfully" }
```

---

### 4. Appointments Management (`/admin/appointments`)

View and manage all appointments.

```
GET /appointments/admin/all?page=1&limit=20&status=all&date=
Response: {
  "appointments": [
    {
      "_id": "...",
      "patient": { "_id": "...", "firstName": "...", "lastName": "..." },
      "doctor": { "_id": "...", "firstName": "...", "lastName": "...", "specialty": "..." },
      "appointmentDate": "2026-01-10",
      "appointmentTime": "09:00",
      "status": "pending|confirmed|completed|cancelled",
      "createdAt": "..."
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 500 }
}
```

```
GET /appointments/admin/:id
Response: { "appointment": { ...full appointment details... } }
```

```
PUT /appointments/admin/:id/status
Body: { "status": "confirmed|cancelled", "reason": "..." }
Response: { "message": "Appointment updated", "appointment": {...} }
```

```
PUT /appointments/admin/:id/reschedule
Body: { "newDate": "2026-01-15", "newTime": "10:00", "reason": "..." }
Response: { "message": "Appointment rescheduled", "appointment": {...} }
```

```
DELETE /appointments/admin/:id
Response: { "message": "Appointment deleted" }
```

**Today's Appointments:**
```
GET /appointments/admin/today
Response: {
  "appointments": [...today's appointments...],
  "summary": { "total": 15, "pending": 3, "confirmed": 10, "completed": 2 }
}
```

**Pending Reschedule Requests:**
```
GET /appointments/admin/reschedule-requests
Response: {
  "requests": [
    {
      "_id": "...",
      "appointment": {...},
      "requestedDate": "2026-01-15",
      "requestedTime": "10:00",
      "reason": "Schedule conflict",
      "requestedBy": "patient|doctor",
      "createdAt": "..."
    }
  ]
}
```

**Recent Activity:**
```
GET /appointments/admin/recent-activity
Response: {
  "activities": [
    { "action": "created", "appointment": {...}, "timestamp": "..." },
    { "action": "confirmed", "appointment": {...}, "timestamp": "..." }
  ]
}
```

```
GET /appointments/admin/stats
Response: {
  "total": 500,
  "byStatus": { "pending": 20, "confirmed": 50, "completed": 400, "cancelled": 30 },
  "todayCount": 15,
  "thisWeekCount": 85,
  "thisMonthCount": 320
}
```

---

### 5. Audit Logs (`/admin/audit-logs`)

View system audit logs for security and compliance.

```
GET /audit/logs?page=1&limit=50&action=&category=&startDate=&endDate=
Response: {
  "logs": [
    {
      "_id": "...",
      "action": "USER_LOGIN|PATIENT_DATA_ACCESSED|APPOINTMENT_CREATED|...",
      "actionCategory": "authentication|patient_data|appointment|system",
      "performedBy": "user_id",
      "performedByName": "Dr. Ahmed",
      "performedByType": "doctor|patient|admin|system",
      "resourceType": "user|appointment|patient|...",
      "resourceId": "...",
      "description": "User logged in successfully",
      "ipAddress": "192.168.1.1",
      "userAgent": "Mozilla/5.0...",
      "isCritical": false,
      "timestamp": "2026-01-05T10:30:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 50, "total": 1000 }
}
```

```
GET /audit/logs/:id
Response: { "log": { ...full audit log details... } }
```

```
GET /audit/stats
Response: {
  "totalLogs": 5000,
  "criticalEvents": 10,
  "todayLogs": 150,
  "byCategory": {
    "authentication": 2000,
    "patient_data": 1500,
    "appointment": 1000,
    "system": 500
  }
}
```

**User Activity History:**
```
GET /audit/users/:userId/activity?page=1&limit=20&startDate=&endDate=
Response: {
  "logs": [...user's activity logs...],
  "pagination": { "page": 1, "limit": 20, "total": 100 }
}
```

**Patient Access Log (HIPAA Compliance):**
```
GET /audit/patients/:patientId/access-log?page=1&limit=20&startDate=&endDate=
Response: {
  "logs": [
    {
      "accessedBy": "Dr. Ahmed",
      "accessType": "view_medical_records",
      "timestamp": "...",
      "ipAddress": "..."
    }
  ],
  "pagination": {...}
}
```

**Security Events:**
```
GET /audit/security-events?page=1&limit=20&severity=&eventType=
Response: {
  "events": [
    {
      "_id": "...",
      "eventType": "failed_login|suspicious_access|permission_denied",
      "severity": "low|medium|high|critical",
      "description": "Multiple failed login attempts",
      "ipAddress": "...",
      "userId": "...",
      "timestamp": "..."
    }
  ],
  "pagination": {...}
}
```

**Mark Log as Reviewed:**
```
PUT /audit/logs/:logId/review
Body: { "reviewNotes": "Verified - legitimate access" }
Response: { "message": "Log marked as reviewed", "log": {...} }
```

**Export Audit Logs:**
```
GET /audit/export?format=csv|json&startDate=&endDate=&category=
Response: (File download or JSON array)
```

**HIPAA Compliance Report:**
```
GET /audit/compliance/hipaa-report?startDate=&endDate=
Response: {
  "period": { "start": "...", "end": "..." },
  "totalPatientDataAccess": 1500,
  "accessByRole": { "doctor": 1200, "admin": 300 },
  "sensitiveDataAccess": 500,
  "unauthorizedAttempts": 5,
  "complianceScore": 98.5,
  "recommendations": [...]
}
```

**Activity Report:**
```
GET /audit/compliance/activity-report?startDate=&endDate=
Response: {
  "period": { "start": "...", "end": "..." },
  "totalActions": 5000,
  "byCategory": {...},
  "peakHours": [...],
  "topUsers": [...]
}
```

---

### 6. Notifications (`/admin/notifications`)

View admin notifications and alerts.

```
GET /notifications/admin/notifications?page=1&limit=20
Response: {
  "notifications": [
    {
      "_id": "...",
      "title": "Critical Audit Event",
      "body": "Suspicious access pattern detected",
      "type": "admin_alert|system_alert",
      "priority": "urgent|high|medium|low",
      "isRead": false,
      "createdAt": "...",
      "actionData": { "auditLogId": "..." }
    }
  ],
  "pagination": {...}
}
```

```
GET /notifications/unread-count
Response: { "unreadCount": 5 }
```

```
PUT /notifications/:id/read
Response: { "message": "Marked as read" }
```

```
PUT /notifications/mark-all-read
Response: { "message": "All marked as read" }
```

```
GET /notifications/admin/stats
Response: {
  "totalNotifications": 150,
  "unreadNotifications": 30,
  "notificationsToday": 5,
  "typeDistribution": [{ "_id": "admin_alert", "count": 10 }]
}
```

**Recent Notification Activity:**
```
GET /notifications/admin/recent-activity
Response: {
  "activities": [
    {
      "type": "push_sent",
      "recipient": { "name": "...", "role": "patient" },
      "title": "Appointment Reminder",
      "timestamp": "..."
    }
  ]
}
```

**User Preferences Summary:**
```
GET /notifications/admin/preferences-summary
Response: {
  "totalUsers": 150,
  "pushEnabled": 140,
  "emailEnabled": 130,
  "smsEnabled": 50,
  "preferences": {
    "appointments": { "push": 140, "email": 130, "sms": 50 },
    "messages": { "push": 135, "email": 100, "sms": 30 },
    "prescriptions": { "push": 140, "email": 125, "sms": 45 }
  }
}
```

---

### 7. Medical Records Overview (`/admin/medical-records`)

View statistics on medical records (read-only for privacy).

```
GET /medical/admin/stats
Response: {
  "totalConsultations": 2000,
  "totalPrescriptions": 1500,
  "consultationsThisMonth": 200,
  "prescriptionsThisMonth": 150
}
```

**Consultation Statistics (for doctors):**
```
GET /medical/statistics/consultations
Response: {
  "statistics": {
    "total": 500,
    "byMonth": [{ "month": "2026-01", "count": 50 }],
    "avgDuration": 25,
    "topDiagnoses": [{ "diagnosis": "Hypertension", "count": 50 }]
  }
}
```

**Document Statistics:**
```
GET /medical/documents/statistics
Response: {
  "statistics": {
    "totalDocuments": 1000,
    "byCategory": { "lab_results": 400, "imaging": 300, "reports": 300 },
    "storageUsed": "5.2 GB"
  }
}
```

---

### 8. Referrals Management (`/admin/referrals`)

View and monitor doctor referrals across the platform.

Note: Referrals are doctor-to-doctor operations. Admin can view statistics and monitor activity.

**Referral Statistics (Doctor endpoint - useful for admin dashboard):**
```
GET /referrals/statistics
Response: {
  "overview": {
    "totalSent": 50,
    "totalReceived": 30,
    "pendingReferrals": 10,
    "acceptedReferrals": 40,
    "completedReferrals": 35
  },
  "bySpecialty": [
    { "specialty": "Cardiology", "count": 15 },
    { "specialty": "Dermatology", "count": 10 }
  ],
  "recentReferrals": [
    {
      "_id": "...",
      "patient": { "firstName": "...", "lastName": "..." },
      "referringDoctor": { "firstName": "...", "lastName": "...", "specialty": "..." },
      "targetDoctor": { "firstName": "...", "lastName": "...", "specialty": "..." },
      "status": "pending|accepted|rejected|completed|cancelled",
      "priority": "routine|urgent|emergency",
      "reason": "Cardiac evaluation needed",
      "createdAt": "..."
    }
  ]
}
```

**List Sent Referrals:**
```
GET /referrals/sent?page=1&limit=20&status=&priority=
Response: {
  "referrals": [...],
  "pagination": { "page": 1, "limit": 20, "total": 50 }
}
```

**List Received Referrals:**
```
GET /referrals/received?page=1&limit=20&status=&priority=
Response: {
  "referrals": [...],
  "pagination": { "page": 1, "limit": 20, "total": 30 }
}
```

---

### 9. Doctor Reviews (`/admin/reviews`)

View and moderate patient reviews for doctors.

**Get Doctor Reviews (Public):**
```
GET /reviews/doctors/:doctorId?page=1&limit=10
Response: {
  "reviews": [
    {
      "_id": "...",
      "patient": { "firstName": "...", "lastName": "..." },
      "rating": 5,
      "comment": "Excellent doctor, very professional",
      "appointmentId": "...",
      "createdAt": "...",
      "isEdited": false
    }
  ],
  "summary": {
    "averageRating": 4.8,
    "totalReviews": 50,
    "ratingDistribution": { "5": 40, "4": 8, "3": 2, "2": 0, "1": 0 }
  },
  "pagination": { "page": 1, "limit": 10, "total": 50 }
}
```

**Get Review for Appointment:**
```
GET /reviews/appointments/:appointmentId
Response: {
  "review": {
    "_id": "...",
    "rating": 5,
    "comment": "...",
    "patient": {...},
    "doctor": {...},
    "createdAt": "..."
  }
}
```

---

### 10. Messaging Overview (`/admin/messaging`)

View messaging statistics and conversations.

```
GET /messages/admin/stats
Response: {
  "overview": {
    "totalConversations": 500,
    "totalMessages": 10000,
    "activeConversations": 50,
    "uniqueParticipants": 200
  },
  "period": {
    "today": { "messages": 100, "newConversations": 5 },
    "thisWeek": { "messages": 500, "newConversations": 25 },
    "thisMonth": { "messages": 2000, "newConversations": 100 }
  },
  "topParticipants": [
    { "userId": "...", "name": "Dr. Ahmed", "messageCount": 150 }
  ]
}
```

**Recent Messaging Activity:**
```
GET /messages/admin/recent-activity
Response: {
  "activities": [
    {
      "type": "message_sent",
      "conversation": "...",
      "sender": { "name": "...", "role": "doctor" },
      "recipient": { "name": "...", "role": "patient" },
      "timestamp": "..."
    }
  ]
}
```

**All Conversations (Admin Oversight):**
```
GET /messages/admin/conversations?page=1&limit=20
Response: {
  "conversations": [
    {
      "_id": "...",
      "participants": [
        { "_id": "...", "name": "Dr. Ahmed", "role": "doctor" },
        { "_id": "...", "name": "Patient Name", "role": "patient" }
      ],
      "lastMessage": {
        "content": "...",
        "sender": "...",
        "timestamp": "..."
      },
      "messageCount": 50,
      "createdAt": "...",
      "updatedAt": "..."
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 500 }
}
```

---

## UI Requirements

### Sidebar Navigation

- Dashboard (Home) - `/admin`
- Users (with badge for pending verifications) - `/admin/users`
- Doctor Verification - `/admin/doctors`
- Appointments - `/admin/appointments`
- Referrals - `/admin/referrals`
- Reviews - `/admin/reviews`
- Audit Logs - `/admin/audit-logs`
- Notifications (with unread badge) - `/admin/notifications`
- Medical Records - `/admin/medical-records`
- Messaging - `/admin/messaging`
- Platform Health - `/admin/health`
- Settings - `/admin/settings`

### Header

- Search bar (search users, appointments)
- Notification bell with unread count
- Platform health indicator (green/yellow/red)
- Admin profile dropdown (logout)

### Dashboard Cards

- Total Users, Patients, Doctors
- Today's Appointments
- Pending Verifications (link to doctor verification page)
- Critical Alerts
- Active Referrals
- Platform Health Status

### Tables

- Sortable columns
- Pagination
- Search/filter
- Row actions (view, edit, delete)

### Charts (use Recharts)

- User growth (line chart)
- Appointments by status (pie chart)
- Activity over time (bar chart)

### Real-time Updates (Socket.IO) - ⚠️ CRITICAL REQUIREMENT!

**THE DASHBOARD MUST BE 100% REAL-TIME.** All data displayed should update automatically via WebSocket connections. Do NOT rely only on polling or manual refresh.

**Install socket.io-client:**
```bash
npm install socket.io-client
```

**Create a Socket Provider (wrap your app with this):**
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

Multiple WebSocket connections for different real-time features:

**1. Notifications (Port 3007):**
```javascript
import { io } from 'socket.io-client';

const notificationSocket = io('http://localhost:3007', {
  auth: { token: adminToken },
  transports: ['websocket']
});

notificationSocket.on('new_notification', (notification) => {
  // Update notification badge and show toast
});

notificationSocket.on('admin_alert', (alert) => {
  // Show critical admin alert
});
```

**2. User Management Updates (via API Gateway):**
```javascript
const userSocket = io('http://localhost:3000/user-socket', {
  auth: { token: adminToken },
  transports: ['websocket']
});

userSocket.on('user_status_changed', (data) => {
  // { userId, isActive, reason }
  // Refresh user list or update status badge
});

userSocket.on('doctor_verified', (data) => {
  // { doctorId, verifiedBy }
  // Update pending verifications count
});

userSocket.on('new_user_registered', (data) => {
  // { userId, role, name }
  // Update user count
});
```

**3. Appointment Updates (via API Gateway):**
```javascript
const rdvSocket = io('http://localhost:3000/rdv-socket', {
  auth: { token: adminToken },
  transports: ['websocket']
});

rdvSocket.on('appointment_created', (data) => {
  // Refresh appointment list
});

rdvSocket.on('appointment_status_changed', (data) => {
  // { appointmentId, newStatus, updatedBy }
});

rdvSocket.on('reschedule_requested', (data) => {
  // Update reschedule requests count
});

rdvSocket.on('appointment_cancelled', (data) => {
  // { appointmentId, reason }
  // Update appointment in list
});

rdvSocket.on('appointment_rescheduled', (data) => {
  // { appointmentId, newDate, newTime }
  // Update appointment in list
});
```

**Example: Real-time Hook for Dashboard Stats:**
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

  // Listen for real-time updates
  useEffect(() => {
    if (!userSocket || !appointmentSocket || !notificationSocket) return;

    // User events - update counts in real-time
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

    // Appointment events
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

    appointmentSocket.on('appointment_status_changed', (data) => {
      // Update status counts based on the change
      setStats((prev: any) => {
        const newStats = { ...prev };
        // Decrement old status, increment new status
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

    // Notification events
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

**Real-time Tables - Use this pattern:**
```typescript
// Example: Users table with real-time updates
function UsersTable() {
  const [users, setUsers] = useState([]);
  const { userSocket } = useSocket();

  useEffect(() => {
    fetchUsers();
  }, []);

  useEffect(() => {
    if (!userSocket) return;

    userSocket.on('new_user_registered', (newUser) => {
      setUsers(prev => [newUser, ...prev]); // Add to top of list
      toast.success(`New user registered: ${newUser.name}`);
    });

    userSocket.on('user_status_changed', (data) => {
      setUsers(prev => prev.map(u => 
        u._id === data.userId ? { ...u, isActive: data.isActive } : u
      ));
    });

    userSocket.on('user_deleted', (data) => {
      setUsers(prev => prev.filter(u => u._id !== data.userId));
    });

    return () => {
      userSocket.off('new_user_registered');
      userSocket.off('user_status_changed');
      userSocket.off('user_deleted');
    };
  }, [userSocket]);

  return <DataTable data={users} />;
}
```

**Show Connection Status in Header:**
```typescript
function ConnectionIndicator() {
  const { isConnected } = useSocket();
  return (
    <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`} />
  );
}
```

### Design

- Clean, medical/healthcare theme
- Primary color: Blue (#2563eb)
- Use cards, shadows, rounded corners
- Dark mode support
- Responsive (mobile-friendly sidebar)

---

## Sample Test Credentials

```
Email: admin@esante.tn
Password: Admin123!
```

---

## ⚠️ REMINDER - Frontend Only!

This project is **FRONTEND ONLY**. 

1. Create React/Next.js components that fetch data from the APIs above
2. Use `fetch` or `axios` to call the real backend at `http://localhost:3000/api/v1`
3. Store the JWT token from login and include it in Authorization header
4. Handle all API responses (success, error, loading states)
5. DO NOT create any database schemas, models, or mock API routes

The backend microservices are already running with:
- Auth Service (authentication)
- User Service (user management)
- RDV Service (appointments)
- Notification Service (notifications)
- Audit Service (audit logs)
- Medical Records Service
- Messaging Service

All you need to do is build the UI and connect it to these existing APIs!

---

## Priority Colors

```javascript
const priorityColors = {
  urgent: 'red',
  high: 'orange',
  medium: 'yellow',
  low: 'gray'
};
```

## Status Colors

```javascript
const statusColors = {
  pending: 'yellow',
  confirmed: 'blue',
  completed: 'green',
  cancelled: 'red'
};
```

## User Role Colors

```javascript
const roleColors = {
  patient: 'blue',
  doctor: 'green',
  admin: 'purple'
};
```
