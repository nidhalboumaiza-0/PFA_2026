# Admin Dashboard Frontend - User Management Module

## 🎯 Project Overview

Build a modern, responsive **Admin Dashboard** for the **E-Santé Healthcare Platform** using **Next.js 14+ (App Router)**. This is **Part 1: User Management Module** - a real-time admin interface to manage all platform users (doctors and patients).

> **Note:** This document contains three parts:
> - **Part 1: User Management** - Managing doctors and patients with real-time Socket.IO
> - **Part 2: Appointment Oversight** - Managing appointments with real-time updates
> - **Part 3: Dashboard Stats** - System-wide statistics and platform health monitoring

The dashboard should feature **smooth animations**, **real-time data updates via Socket.IO**, and a **clean, professional healthcare-focused design**.

---

## 🎨 Color Palette

### Primary Colors
| Name | Hex | Usage |
|------|-----|-------|
| **Primary Blue** | `#2563EB` | Primary buttons, links, active states |
| **Primary Blue Light** | `#3B82F6` | Hover states, secondary elements |
| **Primary Blue Dark** | `#1D4ED8` | Active/pressed states |

### Secondary Colors
| Name | Hex | Usage |
|------|-----|-------|
| **Teal/Cyan** | `#14B8A6` | Success states, verified badges, online indicators |
| **Teal Light** | `#2DD4BF` | Hover states for success elements |

### Neutral Colors
| Name | Hex | Usage |
|------|-----|-------|
| **Background** | `#F8FAFC` | Main page background |
| **Card Background** | `#FFFFFF` | Cards, modals, panels |
| **Border** | `#E2E8F0` | Borders, dividers |
| **Text Primary** | `#1E293B` | Main text, headings |
| **Text Secondary** | `#64748B` | Secondary text, labels |
| **Text Muted** | `#94A3B8` | Placeholder, disabled text |

### Status Colors
| Name | Hex | Usage |
|------|-----|-------|
| **Success** | `#10B981` | Active users, verified, success messages |
| **Warning** | `#F59E0B` | Pending verification, warnings |
| **Error** | `#EF4444` | Inactive users, errors, delete actions |
| **Info** | `#3B82F6` | Information badges, tooltips |

### Gradients
```css
/* Primary gradient for headers/hero sections */
background: linear-gradient(135deg, #2563EB 0%, #14B8A6 100%);

/* Soft gradient for cards */
background: linear-gradient(180deg, #FFFFFF 0%, #F8FAFC 100%);

/* Sidebar gradient */
background: linear-gradient(180deg, #1E293B 0%, #0F172A 100%);
```

---

## 🏗️ Tech Stack Requirements

- **Framework**: Next.js 14+ with App Router
- **Styling**: Tailwind CSS + CSS Modules for complex animations
- **State Management**: Zustand or React Query (TanStack Query)
- **Real-time**: Socket.IO Client
- **Charts**: Recharts or Chart.js
- **Animations**: Framer Motion
- **Icons**: Lucide React or Heroicons
- **Tables**: TanStack Table (React Table v8)
- **Forms**: React Hook Form + Zod validation
- **Toasts**: React Hot Toast or Sonner
- **Date handling**: date-fns

---

## 📡 API Configuration

### Base URL
```
API_BASE_URL=http://localhost:3000/api/v1
SOCKET_URL=http://localhost:3000
SOCKET_PATH=/user-socket
```

### Authentication
All API requests require a JWT token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

The admin user must have `role: "admin"` in their JWT payload.

---

## 🔌 REST API Endpoints

### 1. Get All Users (Paginated)
```http
GET /users/admin/users
```

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | number | 1 | Page number |
| `limit` | number | 20 | Items per page |
| `role` | string | "all" | Filter: "all", "doctor", "patient" |
| `search` | string | - | Search by name, phone, specialty |
| `isActive` | boolean | - | Filter by active status |
| `isVerified` | boolean | - | Filter doctors by verification |
| `sortBy` | string | "createdAt" | Sort field |
| `sortOrder` | string | "desc" | "asc" or "desc" |

**Response:**
```json
{
  "users": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "userId": "auth-user-id-123",
      "firstName": "Dr. Ahmed",
      "lastName": "Ben Ali",
      "phone": "+216 20 123 456",
      "specialty": "Cardiologie",
      "isActive": true,
      "isVerified": true,
      "profilePhoto": "https://s3.amazonaws.com/...",
      "createdAt": "2026-01-01T10:00:00.000Z",
      "userType": "doctor"
    },
    {
      "_id": "507f1f77bcf86cd799439012",
      "userId": "auth-user-id-456",
      "firstName": "Fatma",
      "lastName": "Trabelsi",
      "phone": "+216 20 789 012",
      "gender": "female",
      "isActive": true,
      "profilePhoto": null,
      "createdAt": "2026-01-02T14:30:00.000Z",
      "userType": "patient"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "pages": 8
  }
}
```

---

### 2. Get User by ID
```http
GET /users/admin/users/:id?type=doctor
```

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `type` | string | Optional: "doctor" or "patient" |

**Response:**
```json
{
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "userId": "auth-user-id-123",
    "firstName": "Dr. Ahmed",
    "lastName": "Ben Ali",
    "phone": "+216 20 123 456",
    "specialty": "Cardiologie",
    "experience": 15,
    "education": ["Faculté de Médecine de Tunis", "Spécialisation Paris"],
    "languages": ["Français", "Arabe", "Anglais"],
    "about": "Cardiologue expérimenté...",
    "address": { "city": "Tunis", "country": "Tunisia" },
    "isActive": true,
    "isVerified": true,
    "verifiedAt": "2026-01-01T12:00:00.000Z",
    "rating": 4.8,
    "reviewCount": 45,
    "profilePhoto": "https://s3.amazonaws.com/...",
    "createdAt": "2026-01-01T10:00:00.000Z",
    "userType": "doctor"
  }
}
```

---

### 3. Update User Status (Activate/Deactivate)
```http
PUT /users/admin/users/:id/status
```

**Request Body:**
```json
{
  "isActive": false,
  "type": "doctor",
  "reason": "Violation of terms of service"
}
```

**Response:**
```json
{
  "message": "User deactivated successfully",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "isActive": false,
    "statusUpdatedAt": "2026-01-05T15:30:00.000Z",
    "statusReason": "Violation of terms of service",
    "userType": "doctor"
  }
}
```

---

### 4. Verify Doctor
```http
PUT /users/admin/doctors/:id/verify
```

**Request Body:**
```json
{
  "isVerified": true,
  "notes": "All documents verified successfully"
}
```

**Response:**
```json
{
  "message": "Doctor verified successfully",
  "doctor": {
    "_id": "507f1f77bcf86cd799439011",
    "isVerified": true,
    "verifiedAt": "2026-01-05T15:30:00.000Z",
    "verifiedBy": "admin-user-id",
    "verificationNotes": "All documents verified successfully",
    "userType": "doctor"
  }
}
```

---

### 5. Delete User
```http
DELETE /users/admin/users/:id
```

**Request Body:**
```json
{
  "type": "patient",
  "reason": "User requested account deletion",
  "hardDelete": false
}
```

**Response:**
```json
{
  "message": "User deleted successfully",
  "userId": "507f1f77bcf86cd799439011"
}
```

---

### 6. Get User Statistics
```http
GET /users/admin/stats
```

**Response:**
```json
{
  "overview": {
    "totalUsers": 1250,
    "totalDoctors": 250,
    "totalPatients": 1000,
    "activeDoctors": 230,
    "activePatients": 950,
    "inactiveUsers": 70
  },
  "doctors": {
    "total": 250,
    "active": 230,
    "verified": 200,
    "pendingVerification": 50,
    "verificationRate": "80.0"
  },
  "patients": {
    "total": 1000,
    "active": 950
  },
  "newRegistrations": {
    "today": {
      "doctors": 3,
      "patients": 12,
      "total": 15
    },
    "thisWeek": {
      "doctors": 15,
      "patients": 85,
      "total": 100
    },
    "thisMonth": {
      "doctors": 45,
      "patients": 320,
      "total": 365
    }
  },
  "specialtyDistribution": [
    { "specialty": "Cardiologie", "count": 35 },
    { "specialty": "Dermatologie", "count": 28 },
    { "specialty": "Pédiatrie", "count": 25 },
    { "specialty": "Neurologie", "count": 20 }
  ],
  "registrationTrend": {
    "doctors": [
      { "_id": "2026-01-01", "count": 2 },
      { "_id": "2026-01-02", "count": 1 },
      { "_id": "2026-01-03", "count": 3 }
    ],
    "patients": [
      { "_id": "2026-01-01", "count": 15 },
      { "_id": "2026-01-02", "count": 12 },
      { "_id": "2026-01-03", "count": 18 }
    ]
  },
  "generatedAt": "2026-01-05T15:30:00.000Z"
}
```

---

### 7. Get Recent Activity
```http
GET /users/admin/recent-activity?limit=20
```

**Response:**
```json
{
  "recentActivity": [
    {
      "_id": "507f1f77bcf86cd799439012",
      "firstName": "Fatma",
      "lastName": "Trabelsi",
      "gender": "female",
      "isActive": true,
      "profilePhoto": null,
      "createdAt": "2026-01-05T14:30:00.000Z",
      "userType": "patient"
    },
    {
      "_id": "507f1f77bcf86cd799439011",
      "firstName": "Dr. Ahmed",
      "lastName": "Ben Ali",
      "specialty": "Cardiologie",
      "isVerified": true,
      "isActive": true,
      "profilePhoto": "https://...",
      "createdAt": "2026-01-05T10:00:00.000Z",
      "userType": "doctor"
    }
  ]
}
```

---

## 🔴 Socket.IO Real-Time Events

### Connection Setup
```typescript
import { io, Socket } from 'socket.io-client';

const socket = io('http://localhost:3000', {
  path: '/user-socket',
  auth: {
    token: 'your-jwt-token'
  }
});

// Join admin room after connection
socket.on('connect', () => {
  socket.emit('join_admin_room');
});

socket.on('joined_admin_room', (data) => {
  console.log('Joined admin room:', data);
});
```

### Events to Listen (Server → Client)

#### 1. New User Registered
```typescript
socket.on('new_user_registered', (data) => {
  // data structure:
  {
    userType: 'doctor' | 'patient',
    userId: string,
    profileId: string,
    firstName: string,
    lastName: string,
    email: string,
    specialty?: string,  // for doctors
    timestamp: string
  }
});
```
**UI Action**: Show toast notification, update stats counters with animation, add new row to table with highlight animation.

#### 2. User Status Changed
```typescript
socket.on('user_status_changed', (data) => {
  // data structure:
  {
    userId: string,
    userType: 'doctor' | 'patient',
    isActive: boolean,
    reason?: string,
    updatedAt: string,
    user: { /* full user object */ }
  }
});
```
**UI Action**: Update user row in table with status badge animation, show toast.

#### 3. Doctor Verified
```typescript
socket.on('doctor_verified', (data) => {
  // data structure:
  {
    doctorId: string,
    isVerified: boolean,
    verifiedAt: string,
    doctor: { /* full doctor object */ }
  }
});
```
**UI Action**: Update doctor row, animate verification badge, update pending verification count.

#### 4. User Deleted
```typescript
socket.on('user_deleted', (data) => {
  // data structure:
  {
    userId: string,
    userType: 'doctor' | 'patient',
    hardDelete: boolean,
    deletedAt: string
  }
});
```
**UI Action**: Animate row removal from table, update stats.

#### 5. Stats Updated
```typescript
socket.on('stats_updated', (data) => {
  // Full stats object (same as GET /stats response)
});
```
**UI Action**: Animate counter updates on dashboard cards.

### Events to Emit (Client → Server)

```typescript
// Join admin room
socket.emit('join_admin_room');

// Subscribe to updates
socket.emit('subscribe_user_updates');

// Unsubscribe
socket.emit('unsubscribe_user_updates');

// Get online admin count
socket.emit('get_admin_count');
socket.on('admin_count', (data) => {
  console.log('Admins online:', data.count);
});
```

---

## 📱 UI/UX Requirements

### Layout Structure
```
┌─────────────────────────────────────────────────────────────┐
│  SIDEBAR (Fixed)          │  MAIN CONTENT                   │
│  ┌────────────────────┐   │  ┌─────────────────────────────┐│
│  │  Logo              │   │  │  Header (Breadcrumb, User)  ││
│  │  ─────────────     │   │  └─────────────────────────────┘│
│  │  📊 Dashboard      │   │  ┌─────────────────────────────┐│
│  │  👥 Users ◀──────  │   │  │  Stats Cards (Animated)     ││
│  │  📅 Appointments   │   │  │  [Total] [Doctors] [Patients]││
│  │  📝 Records        │   │  └─────────────────────────────┘│
│  │  🔔 Notifications  │   │  ┌─────────────────────────────┐│
│  │  ⚙️ Settings       │   │  │  Users Table with Filters   ││
│  │                    │   │  │  Search | Role | Status     ││
│  │  ─────────────     │   │  │  ─────────────────────────  ││
│  │  Admin Profile     │   │  │  [User rows with actions]   ││
│  └────────────────────┘   │  └─────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Page Components

#### 1. Dashboard Overview Cards
- **Total Users** - Large number with animated counter
- **Total Doctors** - With verified/pending breakdown
- **Total Patients** - With active/inactive ratio
- **New Today** - Real-time counter with pulse animation
- **Pending Verifications** - Warning badge if > 0

Each card should have:
- Icon with gradient background
- Main number with count-up animation
- Percentage change indicator (↑ or ↓)
- Subtle shadow and hover lift effect

#### 2. Charts Section
- **Registration Trend** - Line chart (last 30 days) with dual lines for doctors/patients
- **Specialty Distribution** - Donut/pie chart with interactive legend
- **User Activity** - Bar chart showing daily activity

#### 3. Users Data Table
Features:
- **Search bar** with debounced input (300ms)
- **Filter dropdowns**: Role, Status, Verification
- **Sortable columns**: Click header to sort
- **Pagination**: Show 10/20/50 per page
- **Bulk actions**: Select multiple users
- **Row actions**: View, Edit Status, Verify (doctors), Delete

Table columns:
| Column | Description |
|--------|-------------|
| Checkbox | For bulk selection |
| User | Avatar + Name + Email |
| Type | Badge (Doctor/Patient) |
| Phone | Phone number |
| Status | Active/Inactive badge |
| Verified | Only for doctors - checkmark or pending |
| Joined | Relative date (e.g., "2 days ago") |
| Actions | Dropdown menu |

#### 4. User Detail Drawer/Modal
Slide-in panel showing:
- Profile photo (or avatar placeholder)
- Full name and contact info
- User type badge
- Status controls (toggle active)
- Verification controls (for doctors)
- Account timeline (created, verified, etc.)
- Delete button with confirmation

#### 5. Real-time Activity Feed
Small panel showing:
- Live feed of new registrations
- Status changes
- Recent actions
- Each item with user avatar, action, timestamp
- Auto-scroll with new items appearing at top with animation

---

## ✨ Animation Requirements

### Using Framer Motion

#### 1. Page Transitions
```typescript
const pageVariants = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -20 }
};
```

#### 2. Card Entry Animation
```typescript
const cardVariants = {
  hidden: { opacity: 0, scale: 0.95 },
  visible: (i: number) => ({
    opacity: 1,
    scale: 1,
    transition: {
      delay: i * 0.1,
      duration: 0.4,
      ease: "easeOut"
    }
  })
};
```

#### 3. Counter Animation
Use a count-up library or custom hook for animated numbers:
```typescript
// Stats should animate from 0 to actual value over 1 second
<AnimatedCounter from={0} to={stats.totalUsers} duration={1000} />
```

#### 4. Table Row Animations
```typescript
// New row appears with slide + fade
const rowVariants = {
  initial: { opacity: 0, x: -20, backgroundColor: '#E0F2FE' },
  animate: { 
    opacity: 1, 
    x: 0, 
    backgroundColor: '#FFFFFF',
    transition: { duration: 0.5 }
  },
  exit: { opacity: 0, x: 20, height: 0 }
};
```

#### 5. Toast Notifications
- Slide in from top-right
- Stack multiple toasts
- Auto-dismiss after 5 seconds
- Different colors for success/error/info

#### 6. Button Interactions
```typescript
// Scale and shadow on hover
<motion.button
  whileHover={{ scale: 1.02, boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }}
  whileTap={{ scale: 0.98 }}
>
```

#### 7. Skeleton Loading
Show skeleton placeholders while data loads:
- Pulsing gradient animation
- Match actual content layout

---

## 📂 Suggested Project Structure

```
app/
├── (auth)/
│   └── login/
│       └── page.tsx
├── (dashboard)/
│   ├── layout.tsx           # Dashboard layout with sidebar
│   ├── page.tsx             # Main dashboard
│   └── users/
│       ├── page.tsx         # Users list
│       └── [id]/
│           └── page.tsx     # User detail
├── api/                     # API route handlers (if needed)
├── globals.css
└── layout.tsx

components/
├── dashboard/
│   ├── Sidebar.tsx
│   ├── Header.tsx
│   ├── StatsCard.tsx
│   ├── ActivityFeed.tsx
│   └── charts/
│       ├── RegistrationTrend.tsx
│       └── SpecialtyChart.tsx
├── users/
│   ├── UsersTable.tsx
│   ├── UserRow.tsx
│   ├── UserFilters.tsx
│   ├── UserDetailDrawer.tsx
│   ├── VerifyDoctorModal.tsx
│   └── DeleteUserModal.tsx
├── ui/
│   ├── Badge.tsx
│   ├── Button.tsx
│   ├── Card.tsx
│   ├── Input.tsx
│   ├── Modal.tsx
│   ├── Drawer.tsx
│   ├── Skeleton.tsx
│   ├── Avatar.tsx
│   └── AnimatedCounter.tsx
└── shared/
    ├── Toast.tsx
    └── ConfirmDialog.tsx

hooks/
├── useSocket.ts             # Socket.IO connection hook
├── useUsers.ts              # React Query hook for users
├── useStats.ts              # React Query hook for stats
└── useDebounce.ts

lib/
├── api.ts                   # Axios instance with interceptors
├── socket.ts                # Socket.IO client setup
└── utils.ts                 # Helper functions

stores/
├── authStore.ts             # Zustand store for auth
└── userStore.ts             # Zustand store for user state

types/
├── user.ts
├── stats.ts
└── api.ts
```

---

## 🔐 Authentication Flow

1. Admin logs in via `/login` page
2. JWT token stored in httpOnly cookie or secure storage
3. Token sent with all API requests
4. Token sent to Socket.IO on connection
5. If 401 response, redirect to login

---

## 📋 Acceptance Criteria

### Must Have
- [ ] Responsive sidebar with navigation
- [ ] Stats cards with animated counters
- [ ] Users table with search, filter, sort, pagination
- [ ] Real-time updates via Socket.IO
- [ ] User detail view (drawer or modal)
- [ ] Activate/Deactivate user functionality
- [ ] Doctor verification functionality
- [ ] Delete user with confirmation
- [ ] Toast notifications for all actions
- [ ] Loading skeletons
- [ ] Empty states

### Nice to Have
- [ ] Dark mode toggle
- [ ] Export users to CSV
- [ ] Bulk user actions
- [ ] Registration trend chart
- [ ] Specialty distribution chart
- [ ] Activity feed panel
- [ ] Keyboard shortcuts

---

## 🎭 Design Inspirations

Look for inspiration from:
- Vercel Dashboard
- Linear App
- Stripe Dashboard
- Tailwind UI Admin Templates

Key design principles:
- Clean whitespace
- Clear visual hierarchy
- Consistent spacing (8px grid)
- Subtle shadows and borders
- Smooth micro-interactions
- Professional healthcare aesthetic

---

## 📝 Notes

- All text should support RTL for Arabic language
- Use relative dates (date-fns: formatDistanceToNow)
- Handle error states gracefully
- Add proper TypeScript types for all data
- Use React Query for server state management
- Implement optimistic updates for better UX

---

---

# Part 2: Appointment Oversight Module

## 🎯 Module Overview

This module extends the admin dashboard with **Appointment Oversight** - allowing admins to view, manage, and monitor all appointments across the platform in real-time.

---

## 📡 API Configuration

### Base URL
```
API_BASE_URL=http://localhost:3000/api/v1
SOCKET_URL=http://localhost:3000
SOCKET_PATH=/rdv-socket
```

---

## 🔌 REST API Endpoints

### 1. Get All Appointments (Paginated)
```http
GET /appointments/admin/appointments
```

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | number | 1 | Page number |
| `limit` | number | 20 | Items per page |
| `status` | string | "all" | Filter: "all", "pending", "confirmed", "completed", "cancelled", "rejected", "no-show" |
| `doctorId` | ObjectId | - | Filter by doctor |
| `patientId` | ObjectId | - | Filter by patient |
| `dateFrom` | date | - | Filter appointments from this date |
| `dateTo` | date | - | Filter appointments until this date |
| `sortBy` | string | "appointmentDate" | Sort field |
| `sortOrder` | string | "desc" | "asc" or "desc" |

**Response:**
```json
{
  "appointments": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "patientId": "507f1f77bcf86cd799439012",
      "doctorId": "507f1f77bcf86cd799439013",
      "appointmentDate": "2026-01-10T00:00:00.000Z",
      "appointmentTime": "10:30",
      "duration": 30,
      "status": "confirmed",
      "reason": "Annual checkup",
      "notes": null,
      "isReferral": false,
      "confirmedAt": "2026-01-05T14:00:00.000Z",
      "createdAt": "2026-01-04T10:00:00.000Z",
      "doctor": {
        "_id": "507f1f77bcf86cd799439013",
        "firstName": "Dr. Ahmed",
        "lastName": "Ben Ali",
        "specialty": "Cardiologie",
        "profilePhoto": "https://..."
      },
      "patient": {
        "_id": "507f1f77bcf86cd799439012",
        "firstName": "Fatma",
        "lastName": "Trabelsi",
        "profilePhoto": null
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "pages": 8
  }
}
```

---

### 2. Get Appointment by ID
```http
GET /appointments/admin/appointments/:id
```

**Response:**
```json
{
  "appointment": {
    "_id": "507f1f77bcf86cd799439011",
    "patientId": "507f1f77bcf86cd799439012",
    "doctorId": "507f1f77bcf86cd799439013",
    "appointmentDate": "2026-01-10T00:00:00.000Z",
    "appointmentTime": "10:30",
    "duration": 30,
    "status": "confirmed",
    "reason": "Annual checkup",
    "notes": "Patient has history of hypertension",
    "isReferral": false,
    "isRescheduled": false,
    "rescheduleCount": 0,
    "reminderSent": true,
    "reminderSentAt": "2026-01-09T08:00:00.000Z",
    "confirmedAt": "2026-01-05T14:00:00.000Z",
    "createdAt": "2026-01-04T10:00:00.000Z",
    "attachedDocuments": [
      {
        "name": "previous_results.pdf",
        "url": "https://s3...",
        "type": "lab_result",
        "uploadedAt": "2026-01-04T10:05:00.000Z"
      }
    ],
    "doctor": {
      "_id": "507f1f77bcf86cd799439013",
      "firstName": "Dr. Ahmed",
      "lastName": "Ben Ali",
      "specialty": "Cardiologie",
      "phone": "+216 20 123 456",
      "profilePhoto": "https://...",
      "rating": 4.8
    },
    "patient": {
      "_id": "507f1f77bcf86cd799439012",
      "firstName": "Fatma",
      "lastName": "Trabelsi",
      "phone": "+216 20 789 012",
      "gender": "female",
      "profilePhoto": null
    }
  }
}
```

---

### 3. Update Appointment Status (Admin Override)
```http
PUT /appointments/admin/appointments/:id/status
```

**Request Body:**
```json
{
  "status": "cancelled",
  "reason": "Doctor unavailable due to emergency",
  "notes": "Patient has been notified and offered rebooking"
}
```

**Valid Statuses:** `pending`, `confirmed`, `rejected`, `cancelled`, `completed`, `no-show`

**Response:**
```json
{
  "message": "Appointment status updated to cancelled",
  "appointment": {
    "_id": "507f1f77bcf86cd799439011",
    "status": "cancelled",
    "cancellationReason": "Doctor unavailable due to emergency",
    "cancelledBy": "admin",
    "cancelledAt": "2026-01-05T16:00:00.000Z",
    "adminNotes": "Patient has been notified and offered rebooking",
    "adminUpdatedAt": "2026-01-05T16:00:00.000Z",
    "doctor": { ... },
    "patient": { ... }
  }
}
```

---

### 4. Reschedule Appointment (Admin Override)
```http
PUT /appointments/admin/appointments/:id/reschedule
```

**Request Body:**
```json
{
  "newDate": "2026-01-15",
  "newTime": "14:00",
  "reason": "Rescheduled due to scheduling conflict"
}
```

**Response:**
```json
{
  "message": "Appointment rescheduled successfully",
  "appointment": {
    "_id": "507f1f77bcf86cd799439011",
    "appointmentDate": "2026-01-15T00:00:00.000Z",
    "appointmentTime": "14:00",
    "previousDate": "2026-01-10T00:00:00.000Z",
    "previousTime": "10:30",
    "isRescheduled": true,
    "rescheduledBy": "admin",
    "rescheduledAt": "2026-01-05T16:00:00.000Z",
    "rescheduleReason": "Rescheduled due to scheduling conflict",
    "rescheduleCount": 1,
    "status": "confirmed",
    "doctor": { ... },
    "patient": { ... }
  }
}
```

---

### 5. Delete Appointment
```http
DELETE /appointments/admin/appointments/:id
```

**Request Body:**
```json
{
  "reason": "Duplicate appointment entry",
  "hardDelete": false
}
```

**Response:**
```json
{
  "message": "Appointment deleted successfully",
  "appointmentId": "507f1f77bcf86cd799439011"
}
```

---

### 6. Get Appointment Statistics
```http
GET /appointments/admin/stats
```

**Response:**
```json
{
  "overview": {
    "total": 5000,
    "pending": 150,
    "confirmed": 320,
    "completed": 4200,
    "cancelled": 250,
    "rejected": 50,
    "noShow": 30,
    "completionRate": "93.2"
  },
  "today": {
    "total": 85,
    "upcoming": 42
  },
  "period": {
    "thisWeek": 450,
    "thisMonth": 1800
  },
  "statusDistribution": [
    { "status": "completed", "count": 4200 },
    { "status": "confirmed", "count": 320 },
    { "status": "cancelled", "count": 250 },
    { "status": "pending", "count": 150 },
    { "status": "rejected", "count": 50 },
    { "status": "no-show", "count": 30 }
  ],
  "appointmentTrend": [
    {
      "_id": "2026-01-01",
      "statuses": [
        { "status": "completed", "count": 120 },
        { "status": "confirmed", "count": 25 },
        { "status": "cancelled", "count": 8 }
      ],
      "total": 153
    }
  ],
  "topDoctors": [
    {
      "_id": "507f1f77bcf86cd799439013",
      "appointmentCount": 245,
      "completedCount": 230,
      "doctor": {
        "_id": "507f1f77bcf86cd799439013",
        "firstName": "Dr. Ahmed",
        "lastName": "Ben Ali",
        "specialty": "Cardiologie",
        "profilePhoto": "https://..."
      }
    }
  ],
  "busiestHours": [
    { "time": "10:00", "count": 580 },
    { "time": "14:00", "count": 520 },
    { "time": "09:00", "count": 480 }
  ],
  "generatedAt": "2026-01-05T16:00:00.000Z"
}
```

---

### 7. Get Recent Activity
```http
GET /appointments/admin/recent-activity?limit=20
```

**Response:**
```json
{
  "recentActivity": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "status": "confirmed",
      "appointmentDate": "2026-01-10T00:00:00.000Z",
      "appointmentTime": "10:30",
      "createdAt": "2026-01-05T15:30:00.000Z",
      "updatedAt": "2026-01-05T15:35:00.000Z",
      "doctor": {
        "_id": "507f1f77bcf86cd799439013",
        "firstName": "Dr. Ahmed",
        "lastName": "Ben Ali",
        "specialty": "Cardiologie",
        "profilePhoto": "https://..."
      },
      "patient": {
        "_id": "507f1f77bcf86cd799439012",
        "firstName": "Fatma",
        "lastName": "Trabelsi",
        "profilePhoto": null
      }
    }
  ]
}
```

---

### 8. Get Today's Appointments
```http
GET /appointments/admin/today
```

**Response:**
```json
{
  "total": 85,
  "appointments": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "appointmentDate": "2026-01-05T00:00:00.000Z",
      "appointmentTime": "09:00",
      "status": "confirmed",
      "doctor": { ... },
      "patient": { ... }
    }
  ],
  "byStatus": {
    "pending": [...],
    "confirmed": [...],
    "completed": [...],
    "cancelled": [...],
    "noShow": [...]
  }
}
```

---

### 9. Get Pending Reschedule Requests
```http
GET /appointments/admin/reschedule-requests?page=1&limit=20
```

**Response:**
```json
{
  "requests": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "appointmentDate": "2026-01-10T00:00:00.000Z",
      "appointmentTime": "10:30",
      "status": "confirmed",
      "rescheduleRequest": {
        "requestedDate": "2026-01-12T00:00:00.000Z",
        "requestedTime": "15:00",
        "reason": "Work conflict",
        "requestedAt": "2026-01-05T10:00:00.000Z",
        "status": "pending"
      },
      "doctor": { ... },
      "patient": { ... }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "pages": 1
  }
}
```

---

## 🔴 Socket.IO Real-Time Events (Appointments)

### Connection Setup
```typescript
import { io, Socket } from 'socket.io-client';

const appointmentSocket = io('http://localhost:3000', {
  path: '/rdv-socket',
  auth: {
    token: 'your-jwt-token'
  }
});

// Join admin room after connection
appointmentSocket.on('connect', () => {
  appointmentSocket.emit('join_admin_room');
});

appointmentSocket.on('joined_admin_room', (data) => {
  console.log('Joined admin appointments room:', data);
});
```

### Events to Listen (Server → Client)

#### 1. New Appointment Created
```typescript
appointmentSocket.on('new_appointment', (data) => {
  // data structure:
  {
    appointmentId: string,
    patientId: string,
    doctorId: string,
    appointmentDate: string,
    appointmentTime: string,
    status: 'pending',
    patient: { firstName, lastName, profilePhoto },
    doctor: { firstName, lastName, specialty, profilePhoto },
    timestamp: string
  }
});
```
**UI Action**: Show toast, add new row to table with highlight animation, update stats counters.

#### 2. Appointment Status Changed
```typescript
appointmentSocket.on('appointment_status_changed', (data) => {
  // data structure:
  {
    appointmentId: string,
    status: string,
    reason?: string,
    updatedBy: 'admin' | 'doctor' | 'patient',
    updatedAt: string,
    appointment: { /* full appointment object */ }
  }
});
```
**UI Action**: Update row status badge with animation, show toast.

#### 3. Appointment Confirmed
```typescript
appointmentSocket.on('appointment_confirmed', (data) => {
  // data structure:
  {
    appointmentId: string,
    confirmedAt: string,
    appointment: { /* full appointment object */ },
    timestamp: string
  }
});
```
**UI Action**: Update status badge to green, animate checkmark.

#### 4. Appointment Cancelled
```typescript
appointmentSocket.on('appointment_cancelled', (data) => {
  // data structure:
  {
    appointmentId: string,
    cancelledBy: 'admin' | 'doctor' | 'patient',
    cancellationReason: string,
    appointment: { /* full appointment object */ },
    timestamp: string
  }
});
```
**UI Action**: Update status badge to red, show cancellation reason in tooltip.

#### 5. Appointment Rescheduled
```typescript
appointmentSocket.on('appointment_rescheduled', (data) => {
  // data structure:
  {
    appointmentId: string,
    previousDate: string,
    previousTime: string,
    newDate: string,
    newTime: string,
    rescheduledBy: 'admin' | 'doctor' | 'patient',
    appointment: { /* full appointment object */ },
    timestamp: string
  }
});
```
**UI Action**: Update date/time with animation, show "rescheduled" indicator.

#### 6. Appointment Deleted
```typescript
appointmentSocket.on('appointment_deleted', (data) => {
  // data structure:
  {
    appointmentId: string,
    hardDelete: boolean,
    deletedAt: string
  }
});
```
**UI Action**: Animate row removal from table.

#### 7. Stats Updated
```typescript
appointmentSocket.on('stats_updated', (data) => {
  // Full stats object (same as GET /admin/stats response)
});
```
**UI Action**: Animate counter updates on dashboard cards.

---

## 📱 UI/UX Requirements for Appointments Module

### Layout Addition to Sidebar
```
│  📊 Dashboard
│  👥 Users
│  📅 Appointments ◀──── NEW
│     ├── Overview
│     ├── All Appointments
│     ├── Today's Schedule
│     └── Reschedule Requests
│  📝 Records
│  🔔 Notifications
```

### Page Components

#### 1. Appointments Dashboard Overview
Cards:
- **Total Appointments** - All time count
- **Today's Appointments** - With breakdown by status
- **Pending Confirmation** - Urgent attention needed
- **Completion Rate** - Percentage with trend arrow
- **Cancelled Today** - With reason breakdown
- **No-Shows** - Monthly count

Charts:
- **Appointment Trend** - Area chart (last 30 days) with status stacking
- **Status Distribution** - Donut chart
- **Busiest Hours** - Horizontal bar chart
- **Top Doctors** - Leaderboard with appointment counts

#### 2. Appointments Data Table
Features:
- **Date range picker** with presets (Today, This Week, This Month)
- **Status filter** as pill buttons with colors
- **Doctor/Patient search** with autocomplete
- **Calendar view toggle** (Table ↔ Calendar)
- **Time slot visualization** for daily view

Table columns:
| Column | Description |
|--------|-------------|
| ID | Short appointment ID |
| Date & Time | Formatted with relative indicator |
| Patient | Avatar + Name |
| Doctor | Avatar + Name + Specialty |
| Status | Colored badge with icon |
| Duration | In minutes |
| Actions | View, Update Status, Reschedule, Delete |

#### 3. Appointment Detail Drawer
Sections:
- **Header**: Status badge, appointment ID, date/time
- **Participants**: Patient and Doctor cards with contact info
- **Details**: Reason, notes, duration
- **Documents**: Attached files with preview
- **Timeline**: Creation, confirmations, changes
- **Actions**: Status buttons, reschedule, delete

#### 4. Today's Schedule View
- Timeline visualization (8 AM - 8 PM)
- Appointments as blocks on timeline
- Color-coded by status
- Click to expand details
- Quick actions on hover

#### 5. Reschedule Requests Panel
- List of pending requests
- Original vs requested date/time
- Patient reason
- Quick approve/reject buttons
- Batch actions

---

## ✨ Animation Additions

### Status Badge Transitions
```typescript
const statusColors = {
  pending: '#F59E0B',
  confirmed: '#10B981',
  completed: '#3B82F6',
  cancelled: '#EF4444',
  rejected: '#6B7280',
  'no-show': '#8B5CF6'
};

// Animate status change
<motion.div
  initial={{ scale: 0.8, opacity: 0 }}
  animate={{ scale: 1, opacity: 1 }}
  style={{ backgroundColor: statusColors[status] }}
/>
```

### Calendar Day Animation
```typescript
// When navigating dates
const calendarVariants = {
  enter: (direction: number) => ({
    x: direction > 0 ? 300 : -300,
    opacity: 0
  }),
  center: { x: 0, opacity: 1 },
  exit: (direction: number) => ({
    x: direction < 0 ? 300 : -300,
    opacity: 0
  })
};
```

### Timeline Slot Animation
```typescript
// Appointments appearing on timeline
const slotVariants = {
  hidden: { scaleY: 0, opacity: 0 },
  visible: (i: number) => ({
    scaleY: 1,
    opacity: 1,
    transition: { delay: i * 0.05 }
  })
};
```

---

## 📂 Additional Project Structure

```
app/
├── (dashboard)/
│   └── appointments/
│       ├── page.tsx              # Appointments overview dashboard
│       ├── list/
│       │   └── page.tsx          # All appointments table
│       ├── today/
│       │   └── page.tsx          # Today's schedule
│       ├── reschedule-requests/
│       │   └── page.tsx          # Pending reschedules
│       └── [id]/
│           └── page.tsx          # Appointment detail

components/
├── appointments/
│   ├── AppointmentsTable.tsx
│   ├── AppointmentRow.tsx
│   ├── AppointmentFilters.tsx
│   ├── AppointmentDetailDrawer.tsx
│   ├── StatusBadge.tsx
│   ├── DateRangePicker.tsx
│   ├── TimelineView.tsx
│   ├── CalendarView.tsx
│   ├── UpdateStatusModal.tsx
│   ├── RescheduleModal.tsx
│   └── DeleteAppointmentModal.tsx
├── dashboard/
│   └── charts/
│       ├── AppointmentTrend.tsx
│       ├── StatusPieChart.tsx
│       ├── BusiestHoursChart.tsx
│       └── TopDoctorsChart.tsx

hooks/
├── useAppointmentSocket.ts       # Socket.IO hook for appointments
├── useAppointments.ts            # React Query hook
└── useAppointmentStats.ts        # Stats hook

types/
├── appointment.ts
└── appointmentStats.ts
```

---

## 📋 Acceptance Criteria for Appointments Module

### Must Have
- [ ] Appointment stats cards with animated counters
- [ ] Appointments table with search, filter, sort, pagination
- [ ] Date range picker with presets
- [ ] Status filter with colored pills
- [ ] Real-time updates via Socket.IO
- [ ] Appointment detail drawer
- [ ] Update status functionality (admin override)
- [ ] Reschedule appointment functionality
- [ ] Delete appointment with confirmation
- [ ] Today's schedule view
- [ ] Pending reschedule requests list

### Nice to Have
- [ ] Calendar view with month/week/day
- [ ] Timeline visualization for daily schedule
- [ ] Drag-and-drop rescheduling on calendar
- [ ] Appointment trend chart
- [ ] Status distribution chart
- [ ] Busiest hours chart
- [ ] Top doctors leaderboard
- [ ] Export to CSV/PDF
- [ ] Bulk status updates

---

---

# Part 3: System-Wide Dashboard Stats

## 🎯 Overview

This module provides **aggregated system-wide statistics** for the admin dashboard homepage. It consolidates data from all microservices (user-service, rdv-service, messaging-service, notification-service) into a unified dashboard view.

The Dashboard Stats module enables administrators to:
- View platform-wide statistics at a glance
- Monitor system health across all services
- Track recent activity from all modules
- Visualize growth trends and patterns

---

## 📡 API Endpoints

### Base URL
```
API_BASE_URL=http://localhost:3000/api/v1/admin/dashboard
```

---

### 1. Get Comprehensive Dashboard Stats
```http
GET /api/v1/admin/dashboard/stats
```

**Description:** Aggregates comprehensive statistics from all microservices.

**Response:**
```json
{
  "success": true,
  "data": {
    "users": {
      "totalDoctors": 45,
      "totalPatients": 1250,
      "verifiedDoctors": 42,
      "pendingVerification": 3,
      "newThisMonth": 89,
      "trends": {
        "daily": [
          { "date": "2024-01-01", "doctors": 2, "patients": 15 }
        ]
      },
      "topSpecialties": [
        { "specialty": "Cardiologie", "count": 12 },
        { "specialty": "Dermatologie", "count": 8 }
      ]
    },
    "appointments": {
      "total": 5420,
      "confirmed": 3200,
      "completed": 1800,
      "cancelled": 420,
      "pending": 580,
      "todayCount": 45,
      "pendingRescheduleRequests": 12,
      "busiestHours": [
        { "hour": 9, "count": 234 },
        { "hour": 10, "count": 289 }
      ]
    },
    "messaging": {
      "totalConversations": 3200,
      "totalMessages": 45000,
      "activeConversations": 890,
      "unreadMessages": 234,
      "averageMessagesPerConversation": 14.06,
      "readRate": 89.5,
      "messagesLast24h": 1250,
      "conversationsLast24h": 89,
      "busiestHours": [
        { "hour": 14, "count": 320 }
      ]
    },
    "notifications": {
      "totalSent": 125000,
      "read": 98000,
      "unread": 27000,
      "readRate": 78.4,
      "sentLast24h": 2340,
      "channels": {
        "push": 80000,
        "email": 35000,
        "sms": 10000
      },
      "byType": {
        "appointment_reminder": 45000,
        "new_message": 32000,
        "system_alert": 8000
      }
    },
    "fetchedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

---

### 2. Get Quick Stats
```http
GET /api/v1/admin/dashboard/quick-stats
```

**Description:** Returns quick summary stats for dashboard header cards. Faster than full stats endpoint.

**Response:**
```json
{
  "success": true,
  "data": {
    "users": {
      "totalDoctors": 45,
      "totalPatients": 1250,
      "pendingVerification": 3,
      "newThisMonth": 89
    },
    "appointments": {
      "total": 5420,
      "todayCount": 45,
      "pendingRescheduleRequests": 12
    },
    "messaging": {
      "totalConversations": 3200,
      "activeToday": 156
    },
    "notifications": {
      "sentToday": 2340,
      "unreadCount": 27000
    },
    "fetchedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

---

### 3. Get Platform Health
```http
GET /api/v1/admin/dashboard/health
```

**Description:** Returns health status for all microservices.

**Response:**
```json
{
  "success": true,
  "data": {
    "overallStatus": "healthy",
    "services": {
      "user-service": {
        "status": "healthy",
        "responseTime": 45,
        "lastChecked": "2024-01-15T10:30:00.000Z"
      },
      "rdv-service": {
        "status": "healthy",
        "responseTime": 52,
        "lastChecked": "2024-01-15T10:30:00.000Z"
      },
      "messaging-service": {
        "status": "healthy",
        "responseTime": 38,
        "lastChecked": "2024-01-15T10:30:00.000Z"
      },
      "notification-service": {
        "status": "healthy",
        "responseTime": 41,
        "lastChecked": "2024-01-15T10:30:00.000Z"
      },
      "medical-records-service": {
        "status": "degraded",
        "responseTime": 250,
        "lastChecked": "2024-01-15T10:30:00.000Z",
        "error": "Slow response time"
      }
    },
    "checkedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

**Status Values:**
| Status | Description | Color |
|--------|-------------|-------|
| `healthy` | Service responding normally | `#10B981` (green) |
| `degraded` | Service slow or partially working | `#F59E0B` (yellow) |
| `unhealthy` | Service not responding | `#EF4444` (red) |

---

### 4. Get Recent Activity
```http
GET /api/v1/admin/dashboard/recent-activity
```

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | number | 10 | Number of items per category |

**Response:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "type": "user_registered",
        "user": {
          "_id": "507f1f77bcf86cd799439011",
          "firstName": "Ahmed",
          "lastName": "Ben Ali",
          "userType": "doctor"
        },
        "timestamp": "2024-01-15T10:25:00.000Z"
      }
    ],
    "appointments": [
      {
        "type": "appointment_created",
        "appointment": {
          "_id": "appt123",
          "doctorName": "Dr. Ahmed Ben Ali",
          "patientName": "Fatma Trabelsi",
          "dateTime": "2024-01-16T09:00:00.000Z"
        },
        "timestamp": "2024-01-15T10:28:00.000Z"
      }
    ],
    "messaging": [
      {
        "type": "conversation_started",
        "conversation": {
          "_id": "conv123",
          "participants": ["Dr. Ahmed", "Fatma Trabelsi"]
        },
        "timestamp": "2024-01-15T10:27:00.000Z"
      }
    ],
    "notifications": [
      {
        "type": "bulk_notification_sent",
        "count": 150,
        "notificationType": "appointment_reminder",
        "timestamp": "2024-01-15T10:00:00.000Z"
      }
    ],
    "fetchedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

---

## 🎨 UI Components for Dashboard

### Stats Cards Grid
```tsx
// components/dashboard/StatsGrid.tsx

interface StatCard {
  title: string;
  value: number;
  change?: number;       // Percentage change
  changeLabel?: string;  // "vs last month"
  icon: LucideIcon;
  color: string;
  href?: string;
}

const statsCards: StatCard[] = [
  {
    title: "Total Doctors",
    value: stats.users.totalDoctors,
    change: +12.5,
    changeLabel: "vs last month",
    icon: UserCheck,
    color: "blue",
    href: "/users?role=doctor"
  },
  {
    title: "Total Patients",
    value: stats.users.totalPatients,
    change: +8.2,
    changeLabel: "vs last month",
    icon: Users,
    color: "teal",
    href: "/users?role=patient"
  },
  {
    title: "Appointments Today",
    value: stats.appointments.todayCount,
    icon: Calendar,
    color: "purple",
    href: "/appointments/today"
  },
  {
    title: "Pending Verifications",
    value: stats.users.pendingVerification,
    icon: Clock,
    color: "orange",
    href: "/users?isVerified=false"
  },
  {
    title: "Active Conversations",
    value: stats.messaging.activeConversations,
    icon: MessageSquare,
    color: "green",
    href: "/messaging"
  },
  {
    title: "Unread Notifications",
    value: stats.notifications.unread,
    icon: Bell,
    color: "red",
    href: "/notifications"
  }
];
```

### Animated Stat Card Component
```tsx
// components/dashboard/StatCard.tsx

import { motion } from 'framer-motion';
import CountUp from 'react-countup';

const colorStyles = {
  blue: { bg: 'bg-blue-50', iconBg: 'bg-blue-500', text: 'text-blue-600' },
  teal: { bg: 'bg-teal-50', iconBg: 'bg-teal-500', text: 'text-teal-600' },
  purple: { bg: 'bg-purple-50', iconBg: 'bg-purple-500', text: 'text-purple-600' },
  orange: { bg: 'bg-orange-50', iconBg: 'bg-orange-500', text: 'text-orange-600' },
  green: { bg: 'bg-green-50', iconBg: 'bg-green-500', text: 'text-green-600' },
  red: { bg: 'bg-red-50', iconBg: 'bg-red-500', text: 'text-red-600' }
};

export function StatCard({ title, value, change, changeLabel, icon: Icon, color, delay = 0 }) {
  const styles = colorStyles[color];
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: delay * 0.1, duration: 0.5 }}
      className={`${styles.bg} rounded-xl p-6 hover:shadow-lg transition-all duration-300 cursor-pointer group`}
    >
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <h3 className={`text-3xl font-bold mt-2 ${styles.text}`}>
            <CountUp end={value} duration={2} separator="," />
          </h3>
          {change !== undefined && (
            <div className="flex items-center mt-2">
              <span className={change >= 0 ? 'text-green-500' : 'text-red-500'}>
                {change >= 0 ? '↑' : '↓'} {Math.abs(change)}%
              </span>
              <span className="text-gray-500 text-xs ml-1">{changeLabel}</span>
            </div>
          )}
        </div>
        <div className={`${styles.iconBg} rounded-full p-4 group-hover:scale-110 transition-transform duration-300`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
      </div>
    </motion.div>
  );
}
```

### Service Health Grid
```tsx
// components/dashboard/ServiceHealth.tsx

const statusColors = { healthy: 'bg-green-500', degraded: 'bg-yellow-500', unhealthy: 'bg-red-500' };
const statusLabels = { healthy: 'Healthy', degraded: 'Degraded', unhealthy: 'Unhealthy' };

export function ServiceHealth({ services }) {
  return (
    <div className="bg-white rounded-xl p-6 shadow-sm">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">Platform Health</h3>
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
        {Object.entries(services).map(([name, service], index) => (
          <motion.div
            key={name}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.1 }}
            className="relative flex flex-col items-center p-4 rounded-lg bg-gray-50"
          >
            <div className={`w-3 h-3 rounded-full ${statusColors[service.status]} animate-pulse`} />
            <p className="mt-2 text-sm font-medium text-gray-700 text-center">
              {name.replace('-service', '')}
            </p>
            <p className="text-xs text-gray-500">{service.responseTime}ms</p>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
```

---

## 🔄 React Query Hooks

```tsx
// hooks/useDashboardStats.ts

import { useQuery } from '@tanstack/react-query';
import { dashboardApi } from '@/lib/api/dashboard';

export function useDashboardStats() {
  return useQuery({
    queryKey: ['dashboard', 'stats'],
    queryFn: dashboardApi.getStats,
    refetchInterval: 60000, // Refresh every minute
    staleTime: 30000,
  });
}

export function useQuickStats() {
  return useQuery({
    queryKey: ['dashboard', 'quick-stats'],
    queryFn: dashboardApi.getQuickStats,
    refetchInterval: 30000,
    staleTime: 15000,
  });
}

export function usePlatformHealth() {
  return useQuery({
    queryKey: ['dashboard', 'health'],
    queryFn: dashboardApi.getPlatformHealth,
    refetchInterval: 15000,
    staleTime: 10000,
  });
}

export function useRecentActivity(limit: number = 10) {
  return useQuery({
    queryKey: ['dashboard', 'recent-activity', limit],
    queryFn: () => dashboardApi.getRecentActivity(limit),
    refetchInterval: 30000,
    staleTime: 15000,
  });
}
```

### API Client
```tsx
// lib/api/dashboard.ts

import { apiClient } from './client';

export const dashboardApi = {
  getStats: async () => {
    const response = await apiClient.get('/admin/dashboard/stats');
    return response.data;
  },

  getQuickStats: async () => {
    const response = await apiClient.get('/admin/dashboard/quick-stats');
    return response.data;
  },

  getPlatformHealth: async () => {
    const response = await apiClient.get('/admin/dashboard/health');
    return response.data;
  },

  getRecentActivity: async (limit: number = 10) => {
    const response = await apiClient.get(`/admin/dashboard/recent-activity?limit=${limit}`);
    return response.data;
  }
};
```

---

## 📂 Project Structure for Dashboard Stats

```
app/
├── (dashboard)/
│   ├── page.tsx                    # Main dashboard with stats
│   └── layout.tsx

components/
├── dashboard/
│   ├── StatsGrid.tsx               # Grid of stat cards
│   ├── StatCard.tsx                # Individual stat card
│   ├── ServiceHealth.tsx           # Health status grid
│   ├── ActivityFeed.tsx            # Recent activity list
│   ├── DashboardCharts.tsx         # Charts section
│   └── DashboardSkeleton.tsx       # Loading skeleton

hooks/
├── useDashboardStats.ts            # Stats query hook
├── useQuickStats.ts                # Quick stats hook
├── usePlatformHealth.ts            # Health check hook
└── useRecentActivity.ts            # Activity feed hook

lib/
├── api/
│   └── dashboard.ts                # Dashboard API client

types/
├── dashboard.ts                    # Dashboard types
└── stats.ts                        # Stats types
```

---

## 📋 Acceptance Criteria for Dashboard Stats

### Must Have
- [ ] Stats cards grid with animated counters
- [ ] User growth chart (doctors vs patients over time)
- [ ] Appointment trend chart
- [ ] Service health status indicators
- [ ] Recent activity feed (all categories)
- [ ] Auto-refresh for real-time data
- [ ] Loading skeletons during data fetch
- [ ] Error handling with retry buttons

### Nice to Have
- [ ] Date range selector for charts
- [ ] Export stats to CSV/PDF
- [ ] Customizable dashboard widgets
- [ ] Fullscreen chart mode
- [ ] Dashboard layout persistence
- [ ] Dark mode support
- [ ] Notification bell with unread count
- [ ] Quick actions panel

---

**Good luck building this beautiful admin dashboard! 🚀**
