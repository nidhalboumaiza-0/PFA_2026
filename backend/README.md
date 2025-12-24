# E-Santé Backend - Microservices Architecture

Professional healthcare platform backend with microservices architecture.

## 🏗️ Architecture

The backend is split into 8 independent microservices:

1. **Auth Service** (Port 3001) - Authentication & Authorization
2. **User Service** (Port 3002) - Patient & Doctor Management
3. **RDV Service** (Port 3003) - Appointment Scheduling
4. **Medical Records Service** (Port 3004) - Consultations, Prescriptions, Documents
5. **Referral Service** (Port 3005) - Doctor-to-Doctor Referrals
6. **Messaging Service** (Port 3006) - Real-time Communication
7. **Notification Service** (Port 3007) - Multi-channel Notifications
8. **Audit Service** (Port 3008) - Activity Logging

All services communicate through:
- **API Gateway** (Port 3000) - Central entry point
- **Apache Kafka** - Event-driven messaging
- **MongoDB** - Database per service pattern
- **Consul** - Service discovery & centralized configuration

## ⚙️ Centralized Configuration

All services use **Consul KV Store** for centralized configuration management. This eliminates the need for per-service `.env` files in production.

### How it works:
- Configurations are stored in Consul under `esante/config/`
- Global configs: `esante/config/global/JWT_SECRET`, etc.
- Service-specific: `esante/config/services/auth-service/PORT`, etc.
- Services call `initConfig('service-name')` on startup
- Fallback to environment variables if Consul is unavailable

For detailed documentation, see [docs/CENTRALIZED_CONFIG.md](docs/CENTRALIZED_CONFIG.md)

## 🚀 Getting Started

### Prerequisites

- Node.js v18+
- Docker & Docker Compose
- MongoDB v6+
- Apache Kafka (via Docker)
- Redis (for rate limiting)
- Consul (for service discovery)

### Installation

1. Clone the repository
2. Copy `.env.example` to `.env` and configure
3. Install dependencies:

```bash
npm run install-all
```

### Running Services

Each service can be run independently:

```bash
# Run Auth Service
npm run dev:auth

# Run User Service
npm run dev:user

# Run API Gateway
npm run dev:gateway
```

### Database Setup

MongoDB will auto-create databases on first connection. No manual setup needed.

## 📁 Project Structure

```
backend/
├── api-gateway/          # API Gateway (Port 3000)
├── services/             # Microservices
│   ├── auth-service/     # Authentication
│   ├── user-service/     # User Management
│   ├── rdv-service/      # Appointments
│   ├── medical-records-service/  # Medical Data
│   ├── referral-service/ # Referrals
│   ├── messaging-service/# Messaging
│   ├── notification-service/  # Notifications
│   └── audit-service/    # Audit Logs
├── shared/               # Shared utilities
└── docker-compose.yml    # Container orchestration
```

## 🔧 Technology Stack

- **Runtime**: Node.js + Express.js
- **Database**: MongoDB + Mongoose
- **Message Broker**: Apache Kafka
- **Cache**: Redis
- **Storage**: AWS S3
- **Real-time**: Socket.IO
- **Notifications**: OneSignal + Nodemailer

## 📝 Next Steps

After completing this setup:
1. Proceed to PROMPT 1B (Shared Middleware)
2. Then PROMPT 1C (Kafka Infrastructure)
3. Then PROMPT 1D (API Gateway)
4. Finally start with PROMPT 2 (Auth Service)
