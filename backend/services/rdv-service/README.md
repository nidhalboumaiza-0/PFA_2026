# RDV Service - Appointment Management Microservice

## Overview
The RDV (Rendez-vous) Service manages the entire appointment workflow between patients and doctors in the E-Santé platform. It handles doctor availability, appointment requests, confirmations, cancellations, and referral bookings.

## Features

### Doctor Features
- **Availability Management**
  - Set available time slots for specific dates
  - Update or remove availability
  - View personal schedule
  
- **Appointment Management**
  - View pending appointment requests
  - Confirm or reject appointments
  - Mark appointments as completed
  - Cancel appointments if needed
  
- **Referral System**
  - Book appointments for referred patients (auto-confirmed)
  
- **Statistics Dashboard**
  - View appointment counts by status
  - Track today's appointments
  - Monitor no-shows and cancellations

### Patient Features
- **Doctor Search**
  - View available time slots for specific doctors
  - Filter by date range
  
- **Appointment Booking**
  - Request appointments with preferred doctors
  - View appointment history (upcoming/past)
  - Cancel appointments (with 2-hour minimum notice)
  
- **Appointment Tracking**
  - View appointment status (pending, confirmed, rejected, etc.)
  - Filter by status and time period

## API Endpoints

### Doctor Endpoints
```
POST   /api/v1/appointments/doctor/availability      # Set availability
GET    /api/v1/appointments/doctor/availability      # Get my availability
GET    /api/v1/appointments/doctor/requests          # Get appointment requests
PUT    /api/v1/appointments/:id/confirm              # Confirm appointment
PUT    /api/v1/appointments/:id/reject               # Reject appointment
PUT    /api/v1/appointments/:id/complete             # Complete appointment
GET    /api/v1/appointments/doctor/my-appointments   # Get my appointments
GET    /api/v1/appointments/doctor/statistics        # Get statistics
POST   /api/v1/appointments/referral-booking         # Book referral appointment
```

### Patient Endpoints
```
GET    /api/v1/appointments/doctors/:id/availability # View doctor availability
POST   /api/v1/appointments/request                  # Request appointment
PUT    /api/v1/appointments/:id/cancel               # Cancel appointment
GET    /api/v1/appointments/patient/my-appointments  # Get my appointments
```

### Shared Endpoints
```
GET    /api/v1/appointments/:id                      # Get appointment details
GET    /health                                        # Health check
```

## Appointment Status Flow

```
pending → confirmed → completed
        ↓           ↓
    rejected    cancelled
                   ↓
                no-show
```

### Status Definitions
- **pending**: Waiting for doctor confirmation
- **confirmed**: Doctor has accepted the appointment
- **rejected**: Doctor has declined the appointment
- **cancelled**: Patient or doctor has cancelled
- **completed**: Appointment has been completed
- **no-show**: Patient did not show up (future feature)

## Database Models

### Appointment Model
- Patient and doctor references
- Appointment date and time
- Status tracking
- Referral support
- Cancellation/rejection tracking
- Completion tracking
- Reminder tracking

### TimeSlot Model
- Doctor ID + date (compound unique index)
- Array of time slots with booking status
- Availability flag
- Special notes

## Business Logic

### Slot Management
1. Doctor sets availability for a specific date with time slots
2. Each slot can be booked by only one appointment
3. Slots are automatically locked when appointment is requested
4. Slots are freed when appointments are rejected or cancelled

### Conflict Prevention
- Patient cannot book two appointments with same doctor at same time
- TimeSlot unique index prevents duplicate availability entries
- Concurrent booking requests are handled with atomic updates

### Cancellation Policy
- Patients can cancel pending or confirmed appointments
- 2-hour minimum notice before appointment time (future enforcement)
- Cancelled appointments free up the time slot

### Referral Booking
- Referring doctor books on behalf of patient
- Appointments are auto-confirmed (no doctor approval needed)
- Linked to referral ID for tracking

## Kafka Events Published

```javascript
rdv.availability.set         // Doctor sets availability
rdv.appointment.requested    // Patient requests appointment
rdv.appointment.confirmed    // Doctor confirms appointment
rdv.appointment.rejected     // Doctor rejects appointment
rdv.appointment.cancelled    // Appointment cancelled
rdv.appointment.completed    // Appointment completed
rdv.referral.booked          // Referral appointment booked
```

## Environment Variables

```env
PORT=3003
MONGODB_URI=mongodb://localhost:27017/esante_rdv
JWT_SECRET=your_jwt_secret
KAFKA_BROKERS=localhost:9092
USER_SERVICE_URL=http://localhost:3002
```

## Inter-Service Communication

### Dependencies
- **User Service**: Fetch doctor profile information
- **Auth Service**: JWT token validation (via shared middleware)

### Events Consumed
- None (currently standalone)

### Events Published
- All appointment lifecycle events (for Notification Service)

## Data Validation

### Request Appointment
- Doctor ID must be valid ObjectId
- Date must be future date
- Time must be in HH:MM format
- Reason must be provided (max 500 chars)

### Set Availability
- Date must be future date
- Slots must be array of valid time strings
- Time format: HH:MM (24-hour)

### Cancellation/Rejection
- Reason must be provided
- Only specific statuses can be changed

## Query Optimizations

### Indexes
- `doctorId + appointmentDate + status` (compound)
- `patientId + appointmentDate + status` (compound)
- `appointmentDate + appointmentTime` (compound)
- `doctorId + date` (compound unique on TimeSlot)

### Pagination
- All list endpoints support `page` and `limit` parameters
- Default limit: 20 items per page

## Error Handling

### Common Error Responses
```json
{ "message": "Appointment not found" }                  // 404
{ "message": "This time slot is not available" }        // 400
{ "message": "You can only confirm your own appointments" } // 403
{ "message": "Only pending appointments can be confirmed" } // 400
```

## Security

- All endpoints require JWT authentication
- Role-based authorization (patient/doctor)
- User can only access their own appointments
- Doctor can only manage their own schedule

## Future Enhancements

1. **Reminder System**
   - Send notifications 24h, 1h before appointment
   - Mark reminders as sent to avoid duplicates

2. **No-Show Tracking**
   - Automatic status change if patient doesn't show
   - Patient reliability score

3. **Recurring Appointments**
   - Book multiple appointments at once
   - Weekly/monthly patterns

4. **Waitlist System**
   - Join waitlist for fully booked slots
   - Automatic notification when slot opens

5. **Video Consultation Support**
   - Integration with video call service
   - Generate meeting links for confirmed appointments

6. **Calendar Integration**
   - Export to iCal/Google Calendar
   - Sync with external calendars

## Testing

### Manual Testing Steps
1. Start MongoDB and Kafka
2. Start shared services (Auth, User)
3. Run RDV service: `npm start`
4. Register doctor and patient accounts
5. Doctor sets availability
6. Patient requests appointment
7. Doctor confirms/rejects request
8. Test cancellation flow

### Test Scenarios
- ✅ Doctor sets availability for future date
- ✅ Patient views only available (unbooked) slots
- ✅ Patient requests appointment (status: pending)
- ✅ Doctor confirms appointment (status: confirmed)
- ✅ Doctor rejects appointment (slot freed)
- ✅ Patient cancels appointment (slot freed)
- ✅ Prevent double-booking same slot
- ✅ Referral booking auto-confirms
- ✅ Appointment history pagination
- ✅ Statistics calculation

## Development

### Run Development Server
```bash
cd backend/services/rdv-service
npm install
npm start
```

### File Structure
```
rdv-service/
├── src/
│   ├── controllers/
│   │   └── appointmentController.js
│   ├── models/
│   │   ├── Appointment.js
│   │   └── TimeSlot.js
│   ├── routes/
│   │   └── appointmentRoutes.js
│   ├── validators/
│   │   └── appointmentValidator.js
│   ├── utils/
│   │   └── appointmentHelpers.js
│   └── server.js
├── .env
├── package.json
└── README.md
```

## Dependencies

```json
{
  "express": "^4.18.2",
  "mongoose": "^7.6.3",
  "joi": "^17.10.2",
  "axios": "^1.5.1",
  "dotenv": "^16.3.1",
  "cors": "^2.8.5",
  "helmet": "^7.0.0"
}
```

## Contributing

Follow the E-Santé coding style guide:
- ES6 modules (import/export)
- Simple error responses `{message: "..."}`
- Publish Kafka events for all major actions
- Use shared middleware (auth, errorHandler, requestLogger)
- Validate all inputs with Joi
- Use async/await for async operations

---

**Service:** RDV Service  
**Port:** 3003  
**Version:** 1.0.0  
**Status:** ✅ Complete
