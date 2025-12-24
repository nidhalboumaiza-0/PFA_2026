# Audit Service

Comprehensive audit logging system for E-Santé platform that tracks all critical actions for security, compliance, and admin oversight.

## Features

- ✅ **Comprehensive Logging**: Track all critical actions across the platform
- ✅ **Event-Driven**: Kafka consumers automatically log events from all services
- ✅ **Security Monitoring**: Real-time detection of failed logins, suspicious activity
- ✅ **Compliance Reports**: HIPAA and activity reports for regulatory compliance
- ✅ **Patient Access Logs**: Track who accessed patient medical records
- ✅ **Admin Dashboard**: Real-time monitoring via Socket.IO
- ✅ **Export Functionality**: CSV/JSON export for compliance audits
- ✅ **Advanced Filtering**: Filter by category, user, patient, severity, dates
- ✅ **Change Tracking**: Record before/after data for modifications

## Technology Stack

- **Runtime**: Node.js with ES6 modules
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Event Streaming**: KafkaJS ^2.2.4
- **Real-time**: Socket.IO ^4.6.1 (admin monitoring)
- **Export**: json2csv ^6.0.0
- **Validation**: Joi
- **Authentication**: JWT (admin-only access)

## Port

- **3008**

## Environment Variables

```env
# Server
PORT=3008
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/esante-audit

# JWT
JWT_SECRET=your_jwt_secret_key_here_must_match_other_services

# Kafka
KAFKA_BROKER=localhost:9092
KAFKA_CLIENT_ID=audit-service
KAFKA_GROUP_ID=audit-service-group

# Service URLs
USER_SERVICE_URL=http://localhost:3002
NOTIFICATION_SERVICE_URL=http://localhost:3007

# Frontend
FRONTEND_URL=http://localhost:3000

# Audit Settings
DEFAULT_AUDIT_LIMIT=50
MAX_AUDIT_LIMIT=500
AUDIT_LOG_RETENTION_DAYS=365

# Admin Alert Settings
ENABLE_CRITICAL_ALERTS=true
ALERT_WEBHOOK_URL=

# Export Settings
EXPORT_MAX_RECORDS=10000
```

## Database Schema

### AuditLog Model

```javascript
{
  // Action Details
  action: String, // 'user.login', 'consultation.viewed'
  actionCategory: enum [
    'authentication', 'user_management', 'appointment',
    'consultation', 'prescription', 'document',
    'referral', 'message', 'system'
  ],
  
  // Actor (Who)
  performedBy: ObjectId,
  performedByType: enum ['patient', 'doctor', 'admin', 'system'],
  performedByName: String,
  performedByEmail: String,
  
  // Target (What)
  resourceType: String,
  resourceId: ObjectId,
  resourceName: String,
  
  // Patient Context
  patientId: ObjectId,
  patientName: String,
  
  // Details
  description: String,
  severity: enum ['info', 'warning', 'critical'],
  
  // Request Metadata
  ipAddress: String,
  userAgent: String,
  requestMethod: String,
  requestUrl: String,
  
  // Change Tracking
  changes: Object,
  previousData: Object,
  newData: Object,
  
  // Status
  status: enum ['success', 'failed', 'blocked'],
  errorMessage: String,
  
  // Compliance Flags
  isSecurityRelevant: Boolean,
  isComplianceRelevant: Boolean,
  requiresReview: Boolean,
  
  // Review
  reviewedBy: ObjectId,
  reviewedAt: Date,
  reviewNotes: String,
  
  // Metadata
  metadata: Object,
  timestamp: Date,
  createdAt: Date
}
```

### Indexes (7 compound indexes)
1. `{ performedBy: 1, timestamp: -1 }` - User activity
2. `{ patientId: 1, timestamp: -1 }` - Patient access
3. `{ resourceType: 1, resourceId: 1, timestamp: -1 }` - Resource tracking
4. `{ actionCategory: 1, timestamp: -1 }` - Category queries
5. `{ severity: 1, timestamp: -1 }` - Severity filtering
6. `{ isSecurityRelevant: 1, timestamp: -1 }` - Security events
7. `{ isComplianceRelevant: 1, timestamp: -1 }` - Compliance queries

## API Endpoints

### 1. Get Audit Logs
```http
GET /api/v1/audit/logs
Authorization: Bearer <admin_token>

Query Parameters:
  - actionCategory: authentication | user_management | appointment | ...
  - performedBy: userId (ObjectId)
  - patientId: patientId (ObjectId)
  - resourceType: consultation | appointment | document | ...
  - severity: info | warning | critical
  - status: success | failed | blocked
  - isSecurityRelevant: true | false
  - isComplianceRelevant: true | false
  - requiresReview: true | false
  - startDate: ISO date
  - endDate: ISO date
  - page: number (default: 1)
  - limit: number (default: 50, max: 500)

Response:
{
  "success": true,
  "data": {
    "logs": [...],
    "pagination": {
      "currentPage": 1,
      "totalPages": 10,
      "totalItems": 500,
      "itemsPerPage": 50
    },
    "summary": {
      "total": 500,
      "bySeverity": { "info": 450, "warning": 40, "critical": 10 },
      "byCategory": { "authentication": 100, "consultation": 200 }
    }
  }
}
```

### 2. Get User Activity History
```http
GET /api/v1/audit/users/:userId/activity
Authorization: Bearer <admin_token>

Query Parameters:
  - startDate: ISO date
  - endDate: ISO date
  - actionCategory: filter by category
  - page: number
  - limit: number

Response:
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "name": "Dr. Sarah Smith",
      "email": "sarah@example.com",
      "type": "doctor"
    },
    "activityTimeline": [
      {
        "timestamp": "2025-10-29T10:30:00Z",
        "action": "consultation.viewed",
        "description": "Accessed patient medical timeline",
        "patient": "John Doe",
        "severity": "info"
      }
    ],
    "statistics": {
      "totalActions": 150,
      "loginCount": 45,
      "consultationsViewed": 80,
      "documentsAccessed": 25
    }
  }
}
```

### 3. Get Patient Access Log
```http
GET /api/v1/audit/patients/:patientId/access-log
Authorization: Bearer <admin_token>

Purpose: See who accessed a patient's medical records

Response:
{
  "success": true,
  "data": {
    "patient": {
      "id": "...",
      "name": "John Doe"
    },
    "accessLog": [
      {
        "timestamp": "2025-10-29T10:30:00Z",
        "accessedBy": {
          "id": "...",
          "name": "Dr. Sarah Smith",
          "type": "doctor"
        },
        "action": "consultation.viewed",
        "resourceType": "patient_timeline",
        "ipAddress": "192.168.1.100"
      }
    ],
    "statistics": {
      "totalAccesses": 50,
      "uniqueDoctors": 5,
      "lastAccessed": "2025-10-29T10:30:00Z"
    }
  }
}
```

### 4. Get Security Events
```http
GET /api/v1/audit/security-events
Authorization: Bearer <admin_token>

Query Parameters:
  - severity: warning | critical
  - requiresReview: true | false
  - startDate: ISO date
  - endDate: ISO date
  - page: number
  - limit: number (default: 20)

Response:
{
  "success": true,
  "data": {
    "events": [
      {
        "id": "...",
        "timestamp": "2025-10-29T03:00:00Z",
        "action": "security.multiple_failed_logins",
        "severity": "critical",
        "description": "Multiple failed login attempts",
        "performedBy": "System",
        "ipAddress": "203.0.113.45",
        "requiresReview": true
      }
    ],
    "summary": {
      "critical": 5,
      "warning": 20,
      "requiresReview": 10
    }
  }
}
```

### 5. Get Audit Statistics
```http
GET /api/v1/audit/statistics
Authorization: Bearer <admin_token>

Query Parameters:
  - startDate: ISO date
  - endDate: ISO date

Response:
{
  "success": true,
  "data": {
    "totalLogs": 10000,
    "dateRange": {
      "start": "2025-10-01",
      "end": "2025-10-29"
    },
    "bySeverity": {
      "info": 9000,
      "warning": 900,
      "critical": 100
    },
    "byCategory": {
      "authentication": 2000,
      "consultation": 3000,
      "document": 2500
    },
    "topActions": [
      { "action": "user.login", "count": 1500 },
      { "action": "consultation.viewed", "count": 1200 }
    ],
    "topUsers": [
      {
        "userId": "...",
        "name": "Dr. Sarah Smith",
        "actionCount": 500
      }
    ]
  }
}
```

### 6. Mark Audit Log as Reviewed
```http
PUT /api/v1/audit/logs/:logId/review
Authorization: Bearer <admin_token>

Request Body:
{
  "reviewNotes": "Reviewed - no action needed"
}

Response:
{
  "success": true,
  "message": "Audit log marked as reviewed",
  "data": { ... }
}
```

### 7. Export Audit Logs
```http
GET /api/v1/audit/export
Authorization: Bearer <admin_token>

Query Parameters:
  - format: csv | json (default: csv)
  - actionCategory: filter by category
  - startDate: ISO date
  - endDate: ISO date
  - limit: number (default: 1000, max: 10000)

Response: File download (CSV or JSON)
```

### 8. Generate HIPAA Compliance Report
```http
GET /api/v1/audit/compliance/hipaa-report
Authorization: Bearer <admin_token>

Query Parameters:
  - startDate: ISO date
  - endDate: ISO date

Purpose: Generate report showing all medical record accesses

Response:
{
  "success": true,
  "data": {
    "reportType": "HIPAA Compliance",
    "dateRange": { ... },
    "summary": {
      "totalComplianceEvents": 5000,
      "byCategory": [...],
      "uniquePatientsAccessed": 200,
      "uniqueAccessors": 50
    },
    "detailedAccesses": [...],
    "logs": [...]
  }
}
```

### 9. Generate Activity Report
```http
GET /api/v1/audit/compliance/activity-report
Authorization: Bearer <admin_token>

Query Parameters:
  - startDate: ISO date
  - endDate: ISO date

Purpose: Show all system activity for compliance audits

Response:
{
  "success": true,
  "data": {
    "reportType": "Activity Report",
    "summary": { ... },
    "topUsers": [...],
    "timeline": [
      { "date": "2025-10-29", "count": 500 }
    ]
  }
}
```

## Kafka Event Tracking

### Events Consumed (20+ topics)

**Authentication:**
- `auth.user.registered` → user.registered
- `auth.user.verified` → user.email_verified
- `auth.user.logged_in` → user.login
- `auth.login.failed` → auth.login_failed
- `auth.password.changed` → user.password_changed

**User Management:**
- `user.profile.updated` → user.profile_updated
- `user.account.deleted` → user.account_deleted

**Appointments:**
- `rdv.appointment.created` → appointment.created
- `rdv.appointment.confirmed` → appointment.confirmed
- `rdv.appointment.rejected` → appointment.rejected
- `rdv.appointment.cancelled` → appointment.cancelled

**Medical Records:**
- `medical-records.consultation.created` → consultation.created
- `medical-records.consultation.accessed` → consultation.accessed
- `medical-records.consultation.updated` → consultation.updated
- `medical-records.prescription.created` → prescription.created
- `medical-records.prescription.updated` → prescription.updated
- `medical-records.document.uploaded` → document.uploaded
- `medical-records.document.downloaded` → document.downloaded
- `medical-records.document.deleted` → document.deleted

**Referrals:**
- `referral.referral.created` → referral.created
- `referral.referral.scheduled` → referral.scheduled

**Messages:**
- `messaging.message.sent` → message.sent

## Real-Time Monitoring (Socket.IO)

### Admin Dashboard Connection
```javascript
import io from 'socket.io-client';

const socket = io('http://localhost:3008', {
  auth: {
    token: 'admin_jwt_token'
  }
});

// Subscribe to audit stream
socket.emit('subscribe_audit');

// Listen for critical events
socket.on('critical_event', (auditLog) => {
  console.log('Critical event:', auditLog);
  showAlertInDashboard(auditLog);
});

// Listen for security alerts
socket.on('security_alert', (auditLog) => {
  console.log('Security alert:', auditLog);
  showSecurityWarning(auditLog);
});
```

### Events Emitted
- **critical_event**: Sent when severity = 'critical'
- **security_alert**: Sent when isSecurityRelevant = true and severity = 'warning'/'critical'

## Installation

```bash
# Navigate to audit service
cd backend/services/audit-service

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Start service (development)
npm run dev

# Start service (production)
npm start
```

## Dependencies

```json
{
  "express": "^4.18.2",
  "mongoose": "^7.5.0",
  "kafkajs": "^2.2.4",
  "socket.io": "^4.6.1",
  "joi": "^17.9.2",
  "axios": "^1.4.0",
  "jsonwebtoken": "^9.0.1",
  "dotenv": "^16.3.1",
  "helmet": "^7.0.0",
  "cors": "^2.8.5",
  "json2csv": "^6.0.0-alpha.2"
}
```

## Usage Examples

### Manual Audit Log Creation
```javascript
import { createAuditLog } from './utils/auditHelpers.js';

// Track medical record access
await createAuditLog({
  action: 'medical_records.accessed',
  actionCategory: 'consultation',
  performedBy: doctorId,
  performedByType: 'doctor',
  resourceType: 'patient_timeline',
  patientId: patientId,
  description: 'Doctor accessed patient medical timeline',
  severity: 'info',
  isComplianceRelevant: true,
  metadata: {
    viewType: 'full_timeline',
    recordCount: records.length
  }
});

// Track failed login
await createAuditLog({
  action: 'auth.login_failed',
  actionCategory: 'authentication',
  performedBy: null,
  performedByType: 'system',
  description: `Failed login attempt for email: ${email}`,
  severity: 'warning',
  isSecurityRelevant: true,
  requiresReview: true,
  status: 'failed',
  errorMessage: 'Invalid credentials',
  ipAddress: req.ip,
  metadata: { email, attemptCount: 5 }
});
```

### Express Middleware Usage
```javascript
import { auditMiddleware, setAuditAction } from './utils/auditHelpers.js';

app.use(auditMiddleware);

// In your route handler
router.get('/consultations/:id', authMiddleware, async (req, res) => {
  // Set audit action
  setAuditAction(req, {
    action: 'consultation.viewed',
    category: 'consultation',
    resourceType: 'consultation',
    resourceId: req.params.id,
    patientId: consultation.patientId,
    description: 'Consultation accessed',
    severity: 'info'
  });
  
  // Your logic...
  res.json({ success: true, data: consultation });
});
```

## Testing

### Manual Testing
```bash
# 1. Start MongoDB
docker-compose up mongodb

# 2. Start Kafka
docker-compose up kafka

# 3. Start Audit Service
npm run dev

# 4. Test health check
curl http://localhost:3008/health

# 5. Trigger event from another service
# (e.g., login from Auth Service) - audit log should be created

# 6. Query audit logs (admin token required)
curl -H "Authorization: Bearer ADMIN_TOKEN" \
  "http://localhost:3008/api/v1/audit/logs?limit=10"

# 7. Export logs
curl -H "Authorization: Bearer ADMIN_TOKEN" \
  "http://localhost:3008/api/v1/audit/export?format=csv" \
  -o audit-logs.csv
```

## Architecture

```
audit-service/
├── src/
│   ├── models/
│   │   └── AuditLog.js                # Audit log schema with 7 indexes
│   ├── controllers/
│   │   └── auditController.js         # 9 REST endpoint handlers
│   ├── services/
│   │   └── exportService.js           # CSV/JSON export, HIPAA/activity reports
│   ├── kafka/
│   │   └── auditConsumer.js           # Consume 20+ event topics
│   ├── socket/
│   │   └── socket.js                  # Real-time monitoring for admins
│   ├── validators/
│   │   └── auditValidator.js          # Joi validation schemas
│   ├── routes/
│   │   └── auditRoutes.js             # API routes (admin-only)
│   ├── utils/
│   │   └── auditHelpers.js            # createAuditLog, middleware
│   └── server.js                      # Main server + MongoDB change stream
├── .env
├── package.json
└── README.md
```

## Security

- ✅ **Admin-Only Access**: All API endpoints require admin privileges
- ✅ **JWT Authentication**: Token verification on all requests
- ✅ **Socket.IO Auth**: JWT authentication for real-time monitoring
- ✅ **Helmet.js**: Security headers
- ✅ **CORS**: Configured for frontend domain
- ✅ **Input Validation**: Joi validation on all endpoints
- ✅ **Audit Trail**: All actions are logged (including audit service access)

## Performance

### Indexes (7 compound indexes)
- Fast queries by user, patient, resource, category, severity
- Optimized for date range queries

### MongoDB Change Stream
- Real-time monitoring without polling
- Efficient event emission to Socket.IO

### Pagination
- Default: 50 items per page
- Maximum: 500 items per page (10,000 for exports)

### TTL Index (Optional)
- Auto-delete old logs after specified retention period
- Configurable via AUDIT_LOG_RETENTION_DAYS

## Compliance Features

### HIPAA Compliance
- Track all medical record accesses
- Patient-centric access logs
- Detailed audit trails with IP addresses
- Export capabilities for compliance audits

### Data Retention
- Configurable retention period (default: 365 days)
- Option to archive old logs before deletion
- Compliance-relevant logs can be exempted from TTL

### Reporting
- HIPAA compliance reports
- Activity reports for audits
- Export to CSV/JSON for external tools

## Monitoring & Alerts

### Real-Time Monitoring
- Socket.IO dashboard for admins
- Live stream of critical/security events
- MongoDB change stream for instant notifications

### Critical Event Alerts
- Automatic alerts for severity = 'critical'
- Security alerts for failed logins, suspicious activity
- Optional webhook integration (ALERT_WEBHOOK_URL)

### Health Metrics
- Total log count
- Critical events count
- Security events count
- Logs requiring review

## Troubleshooting

### Issue: Logs not being created
- Check Kafka connection: `docker-compose ps kafka`
- Verify Kafka topics exist: `kafka-topics --list`
- Check service logs for errors

### Issue: Real-time monitoring not working
- Verify admin JWT token is valid
- Check Socket.IO connection in browser dev tools
- Ensure FRONTEND_URL in .env is correct

### Issue: Export fails
- Check EXPORT_MAX_RECORDS setting
- Verify sufficient disk space
- Check json2csv package is installed

## Future Enhancements

- Elasticsearch integration for advanced search
- Machine learning anomaly detection
- Automated compliance report scheduling
- Integration with SIEM systems
- Blockchain-based immutable audit trail
- Advanced data visualization dashboards

## License

MIT
