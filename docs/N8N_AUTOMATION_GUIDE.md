# n8n Workflow Automation - Implementation Guide

## Overview

This guide explains the n8n workflow automation system integrated into the E-Santé platform for intelligent appointment booking through multiple channels.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Workflow Components](#workflow-components)
3. [API Integration](#api-integration)
4. [Channel Integrations](#channel-integrations)
5. [Workflow Examples](#workflow-examples)
6. [Setup Instructions](#setup-instructions)
7. [Testing Guide](#testing-guide)

---

## Architecture Overview

```
Patient Request (WhatsApp/Telegram/Voice)
    ↓
n8n Webhook Trigger
    ↓
Parse Natural Language Input
    ↓
Search Doctors (E-Santé API)
    ↓
Check Availability (E-Santé API)
    ↓
Filter & Match Preferences
    ↓
Present Options to Patient
    ↓
Book Appointment (E-Santé API)
    ↓
Send Multi-Channel Confirmations
    ↓
Schedule Automated Reminders
```

---

## Workflow Components

### 1. Webhook Trigger Node
- **Purpose**: Receives incoming requests from external systems
- **Endpoint**: `https://n8n.esante.ma/webhook/book-appointment`
- **Method**: POST
- **Payload**:
```json
{
  "patientId": "user123",
  "channel": "whatsapp|telegram|voice|web",
  "message": "I need a cardiologist in Casablanca",
  "preferences": {
    "specialty": "cardiology",
    "location": {
      "city": "Casablanca",
      "lat": 33.5731,
      "lng": -7.5898
    },
    "preferredDate": "2025-11-10",
    "timeSlot": "morning|afternoon|evening"
  }
}
```

### 2. NLP Parser Node (Optional)
- **Purpose**: Extract intent and entities from natural language
- **Example Input**: "I need a cardiologist appointment in Casablanca this week"
- **Extracted**:
  - Specialty: "cardiology"
  - Location: "Casablanca"
  - Timeframe: "this week"

### 3. HTTP Request Node - Search Doctors
- **Endpoint**: `GET /api/v1/users/doctors/search`
- **Parameters**:
```json
{
  "specialization": "cardiology",
  "lat": 33.5731,
  "lng": -7.5898,
  "radius": 5000,
  "availability": true
}
```
- **Response**: List of matching doctors

### 4. HTTP Request Node - Get Availability
- **Endpoint**: `GET /api/v1/rdv/availability/:doctorId`
- **Parameters**:
```json
{
  "startDate": "2025-11-05",
  "endDate": "2025-11-12",
  "status": "available"
}
```
- **Response**: Available time slots

### 5. Filter & Logic Node
- **Purpose**: Match available slots with patient preferences
- **Logic**:
  - Filter by preferred date range
  - Filter by time of day (morning/afternoon/evening)
  - Sort by earliest available
  - Limit to top 3 options

### 6. Interactive Response Node
- **Purpose**: Present options to patient via their channel
- **Message Format**:
```
Found 3 available appointments:

1️⃣ Dr. Ahmed Benali - Cardiologist
   📅 Tuesday, Nov 7 at 10:00 AM
   📍 Clinique du Centre, Casablanca
   
2️⃣ Dr. Fatima El Mansouri - Cardiologist
   📅 Wednesday, Nov 8 at 2:00 PM
   📍 Polyclinique Anfa, Casablanca
   
3️⃣ Dr. Youssef Alami - Cardiologist
   📅 Thursday, Nov 9 at 9:00 AM
   📍 Cabinet Médical Maarif, Casablanca

Reply with the number to book, or say "more" for other options.
```

### 7. HTTP Request Node - Book Appointment
- **Endpoint**: `POST /api/v1/rdv/appointments`
- **Headers**:
```json
{
  "Authorization": "Bearer <patient_jwt_token>",
  "Content-Type": "application/json"
}
```
- **Body**:
```json
{
  "doctorId": "doc123",
  "availabilityId": "avail456",
  "date": "2025-11-07",
  "startTime": "10:00",
  "endTime": "10:30",
  "reason": "Cardiology consultation",
  "notes": "Booked via WhatsApp automation"
}
```

### 8. Notification Nodes (Parallel)
- **Email Node**: Send confirmation email using Nodemailer
- **SMS Node**: Send SMS confirmation (Twilio/Africa's Talking)
- **Push Notification**: Send via OneSignal
- **WhatsApp/Telegram**: Send confirmation on same channel

### 9. Schedule Reminder Workflows
- **24-Hour Reminder**: Schedule workflow to run 24h before appointment
- **1-Hour Reminder**: Schedule workflow to run 1h before appointment
- **Implementation**: Use n8n's "Schedule" or "Wait" nodes

---

## API Integration

### Authentication
All API requests require JWT authentication. The workflow stores patient tokens securely:

```javascript
// In n8n HTTP Request node
Headers: {
  "Authorization": "Bearer {{ $json.patientToken }}"
}
```

### Available E-Santé API Endpoints

#### 1. Search Doctors
```
GET /api/v1/users/doctors/search
Query Parameters:
  - specialization: string
  - lat: number
  - lng: number
  - radius: number (meters)
  - availability: boolean
```

#### 2. Get Doctor Availability
```
GET /api/v1/rdv/availability/:doctorId
Query Parameters:
  - startDate: YYYY-MM-DD
  - endDate: YYYY-MM-DD
  - status: 'available' | 'booked' | 'all'
```

#### 3. Create Appointment
```
POST /api/v1/rdv/appointments
Body: {
  doctorId: string,
  availabilityId: string,
  date: string,
  startTime: string,
  endTime: string,
  reason: string,
  notes: string
}
```

#### 4. Cancel/Reschedule Appointment
```
PATCH /api/v1/rdv/appointments/:id
Body: {
  status: 'cancelled',
  cancellationReason: string
}
```

---

## Channel Integrations

### 1. WhatsApp Business API

**Setup:**
```javascript
// n8n WhatsApp node configuration
{
  "credentials": "WhatsApp Business Account",
  "phoneNumberId": "YOUR_PHONE_NUMBER_ID",
  "accessToken": "YOUR_ACCESS_TOKEN"
}
```

**Webhook Configuration:**
- URL: `https://n8n.esante.ma/webhook/whatsapp`
- Verify Token: Set in WhatsApp Business settings
- Events: `messages`, `message_status`

**Message Flow:**
1. Patient sends: "Book doctor appointment"
2. Bot responds: "What type of doctor do you need?"
3. Patient: "Cardiologist"
4. Bot: "Which city?"
5. Patient: "Casablanca"
6. Bot: Shows available appointments
7. Patient: "1" (selects first option)
8. Bot: "✅ Appointment booked! Confirmation sent."

### 2. Telegram Bot

**Setup:**
```javascript
// n8n Telegram node configuration
{
  "credentials": "Telegram API",
  "botToken": "YOUR_BOT_TOKEN"
}
```

**Commands:**
- `/start` - Start conversation
- `/book` - Start booking process
- `/myappointments` - View appointments
- `/cancel <id>` - Cancel appointment
- `/help` - Show help

**Inline Keyboard Example:**
```javascript
{
  "reply_markup": {
    "inline_keyboard": [
      [
        {"text": "🩺 Book Appointment", "callback_data": "book_appointment"},
        {"text": "📋 My Appointments", "callback_data": "view_appointments"}
      ],
      [
        {"text": "🔍 Find Doctor", "callback_data": "search_doctor"},
        {"text": "❌ Cancel", "callback_data": "cancel"}
      ]
    ]
  }
}
```

### 3. Voice Assistant (Alexa)

**Skill Setup:**
- Skill Name: "E-Santé Appointments"
- Invocation: "Alexa, ask E-Santé to book an appointment"
- Endpoint: `https://n8n.esante.ma/webhook/alexa`

**Intent Examples:**
```json
{
  "BookAppointmentIntent": {
    "slots": [
      {"name": "specialty", "type": "SPECIALTY_TYPE"},
      {"name": "location", "type": "AMAZON.City"},
      {"name": "date", "type": "AMAZON.DATE"},
      {"name": "time", "type": "AMAZON.TIME"}
    ]
  }
}
```

**Voice Interaction:**
```
User: "Alexa, ask E-Santé to book a cardiologist"
Alexa: "I found 3 cardiologists in your area. Would you like an appointment 
        with Dr. Ahmed on Tuesday at 10 AM, Dr. Fatima on Wednesday at 2 PM, 
        or Dr. Youssef on Thursday at 9 AM?"
User: "The first one"
Alexa: "Great! I've booked your appointment with Dr. Ahmed for Tuesday at 10 AM. 
        You'll receive a confirmation via email and SMS."
```

### 4. Google Assistant

**Action Configuration:**
- Display Name: "E-Santé Health Assistant"
- Invocation: "Talk to E-Santé"
- Fulfillment: `https://n8n.esante.ma/webhook/google-assistant`

---

## Workflow Examples

### Example 1: Basic Appointment Booking

```json
{
  "name": "Book Appointment - WhatsApp",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "whatsapp-booking",
        "responseMode": "onReceived"
      }
    },
    {
      "name": "Search Doctors",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://localhost:3000/api/v1/users/doctors/search",
        "method": "GET",
        "qs": {
          "specialization": "={{ $json.body.specialty }}",
          "lat": "={{ $json.body.location.lat }}",
          "lng": "={{ $json.body.location.lng }}",
          "radius": 5000
        }
      }
    },
    {
      "name": "Get Availability",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://localhost:3000/api/v1/rdv/availability/={{ $json.userId }}",
        "method": "GET"
      }
    },
    {
      "name": "Book Appointment",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://localhost:3000/api/v1/rdv/appointments",
        "method": "POST",
        "body": {
          "doctorId": "={{ $json.doctorId }}",
          "date": "={{ $json.selectedDate }}",
          "startTime": "={{ $json.selectedTime }}"
        }
      }
    },
    {
      "name": "Send Confirmation",
      "type": "n8n-nodes-base.whatsapp",
      "parameters": {
        "message": "✅ Appointment confirmed!\n📅 {{ $json.date }}\n⏰ {{ $json.time }}\n👨‍⚕️ Dr. {{ $json.doctorName }}"
      }
    }
  ]
}
```

### Example 2: Waitlist Automation

**Scenario**: Patient wants an appointment but no slots available

```javascript
// Workflow: Add to Waitlist
If (no availability) {
  1. Store patient request in MongoDB
  2. Send message: "No slots available. Added you to waitlist."
  3. When slot becomes available:
     - Trigger: Appointment cancelled/New availability added
     - Find matching waitlist entries
     - Send notification to first patient in queue
     - Give 24h to book, then move to next
}
```

### Example 3: Appointment Reminder Workflow

```json
{
  "name": "24h Reminder",
  "trigger": {
    "type": "schedule",
    "cron": "0 10 * * *"
  },
  "nodes": [
    {
      "name": "Get Tomorrow's Appointments",
      "type": "httpRequest",
      "url": "http://localhost:3000/api/v1/rdv/appointments/tomorrow"
    },
    {
      "name": "For Each Appointment",
      "type": "splitInBatches"
    },
    {
      "name": "Send WhatsApp Reminder",
      "message": "🔔 Reminder: You have an appointment tomorrow at {{ $json.time }} with Dr. {{ $json.doctorName }}"
    },
    {
      "name": "Send Email Reminder",
      "type": "emailSend",
      "subject": "Appointment Reminder - Tomorrow"
    }
  ]
}
```

---

## Setup Instructions

### 1. Install n8n

**Docker:**
```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=your_password \
  -e WEBHOOK_URL=https://n8n.esante.ma \
  -v n8n_data:/home/node/.n8n \
  n8nio/n8n
```

**npm:**
```bash
npm install n8n -g
n8n start
```

### 2. Configure E-Santé API Credentials

In n8n Credentials menu:
```
Name: E-Santé API
Type: HTTP Request - Custom Auth
Headers:
  Authorization: Bearer YOUR_JWT_TOKEN
Base URL: http://localhost:3000/api/v1
```

### 3. Set Up Webhook Endpoints

1. Create Webhook node in n8n
2. Get webhook URL: `https://n8n.esante.ma/webhook/<path>`
3. Configure in external services (WhatsApp, Telegram, etc.)

### 4. Import Workflow Templates

1. Download workflow JSON from `/docs/n8n-workflows/`
2. In n8n: Workflows → Import from File
3. Configure credentials for each node
4. Activate workflow

---

## Testing Guide

### Test Workflow 1: WhatsApp Booking

**Prerequisites:**
- WhatsApp Business API configured
- Test phone number registered
- n8n webhook active

**Steps:**
1. Send message to WhatsApp Business number: "Book appointment"
2. Bot should respond: "What type of doctor do you need?"
3. Reply: "Cardiologist"
4. Bot asks: "Which city?"
5. Reply: "Casablanca"
6. Bot shows available appointments
7. Reply: "1" (select first option)
8. Verify: Appointment created in database
9. Verify: Confirmation received via WhatsApp, Email, SMS

**Expected Result:**
- Appointment status: "pending"
- Patient notified via all channels
- Doctor notified
- Audit log created

### Test Workflow 2: No Availability Scenario

**Steps:**
1. Request appointment for fully booked doctor
2. Verify: "Added to waitlist" message
3. Check: Waitlist entry in database
4. Cancel an appointment (create availability)
5. Verify: Waitlist patient notified automatically

### Test Workflow 3: Reminder System

**Steps:**
1. Create appointment for tomorrow
2. Wait for scheduled reminder (or trigger manually)
3. Verify: 24h reminder sent via all channels
4. On appointment day: Verify 1h reminder sent

---

## Monitoring & Analytics

### Key Metrics to Track

1. **Booking Success Rate**
   - Total booking attempts
   - Successfully booked
   - Failed (no availability, errors)

2. **Channel Performance**
   - Bookings per channel (WhatsApp vs Telegram vs Voice)
   - Average time to book
   - User preference trends

3. **Workflow Execution**
   - Success rate per workflow
   - Average execution time
   - Error frequency

### n8n Built-in Monitoring

Access at: `http://localhost:5678/executions`
- View all workflow runs
- Filter by status (success/error)
- Inspect node outputs
- Debug failed executions

---

## Troubleshooting

### Common Issues

**1. Webhook Not Receiving Requests**
- Check firewall settings
- Verify webhook URL is publicly accessible
- Test with curl:
```bash
curl -X POST https://n8n.esante.ma/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

**2. API Authentication Failing**
- Verify JWT token not expired
- Check token has correct permissions
- Refresh token if needed

**3. No Doctors Found**
- Verify search parameters
- Check doctors have availability marked
- Confirm geolocation data is correct

**4. Booking Fails**
- Check availability still exists (race condition)
- Verify all required fields provided
- Check doctor calendar not conflicting

---

## Security Considerations

1. **Token Management**
   - Store JWT tokens securely in n8n credentials
   - Implement token refresh logic
   - Never log tokens in workflow output

2. **Webhook Security**
   - Validate webhook signatures
   - Use HTTPS only
   - Implement rate limiting
   - Verify request origin

3. **Data Privacy**
   - Minimize PII in workflow logs
   - Encrypt sensitive data
   - Follow GDPR/HIPAA guidelines
   - Regular security audits

---

## Future Enhancements

1. **AI-Powered Scheduling**
   - Use ML to predict best appointment times
   - Smart waitlist prioritization
   - Predictive availability forecasting

2. **Multi-Language Support**
   - NLP in Arabic, French, English
   - Automatic language detection
   - Localized responses

3. **Payment Integration**
   - Online payment for appointments
   - Insurance verification
   - Invoice generation

4. **Video Consultation**
   - Trigger video calls from booking
   - Automated meeting link generation
   - Post-consultation follow-up

---

## Support & Resources

- **n8n Documentation**: https://docs.n8n.io
- **E-Santé API Docs**: `/docs/API_DOCUMENTATION.md`
- **Workflow Templates**: `/docs/n8n-workflows/`
- **Support Email**: dev@esante.ma

---

## Conclusion

The n8n automation system provides a powerful, flexible solution for intelligent appointment booking across multiple channels. By leveraging workflow automation, the E-Santé platform can:

✅ Reduce manual booking effort  
✅ Provide 24/7 automated service  
✅ Improve patient accessibility  
✅ Scale efficiently with demand  
✅ Integrate with new channels easily  

This guide should help your team implement and maintain the n8n automation system successfully.

---

**Document Version**: 1.0  
**Last Updated**: November 4, 2025  
**Author**: E-Santé Development Team
