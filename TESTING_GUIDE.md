# 🧪 E-Santé App - Complete Testing Guide

**For Testing the Full Application (Backend + Mobile App)**

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Mobile App Setup](#mobile-app-setup)
4. [Connecting Backend & Mobile App](#connecting-backend--mobile-app)
5. [Testing Scenarios](#testing-scenarios)
6. [Troubleshooting](#troubleshooting)

---

## 🔧 Prerequisites

### Required Software:
- **Docker Desktop** - [Download](https://www.docker.com/products/docker-desktop/) ⭐ **MOST IMPORTANT**
- **Flutter** (v3.0 or higher) - [Download](https://flutter.dev/docs/get-started/install)
- **Android Studio** 
- **Git** - [Download](https://git-scm.com/)

### Check Your Installation:
```powershell
# Open PowerShell and run:
docker --version          # Should show Docker version
docker-compose --version  # Should show docker-compose version
flutter --version         # Should show Flutter version
```

### ⚠️ Docker Desktop Must Be Running
Make sure Docker Desktop is running before starting the backend!

---

## 🚀 Backend Setup (Fully Containerized)

### Step 1: Navigate to Backend Folder
```powershell
# Navigate to backend folder
cd <path-to-project>\PFA_2025_ESante\backend
```

### Step 2: Start All Services with Docker Compose

**🎯 One Command to Rule Them All:**
```powershell
# Build and start ALL services (infrastructure + microservices)
docker-compose up -d --build
```

This single command will:
- ✅ Pull/build all Docker images
- ✅ Install all Node.js dependencies automatically
- ✅ Start MongoDB, Redis, Kafka, Zookeeper, Consul
- ✅ Seed Consul configuration automatically
- ✅ Start all 8 microservices + API Gateway
- ✅ Set up networking between all containers

### Step 3: Wait for Services to Start (2-3 minutes)

```powershell
# Monitor the startup process
docker-compose logs -f

# Or check specific service logs
docker-compose logs -f api-gateway
docker-compose logs -f auth-service
```

Press `Ctrl+C` to stop watching logs.

### Step 4: Verify All Containers are Running
```powershell
# Check container status
docker-compose ps
```

You should see **14 containers** running:

**Infrastructure (5):**
- `esante-mongodb` - Database
- `esante-redis` - Caching
- `esante-kafka` - Message broker
- `esante-zookeeper` - Kafka coordinator
- `esante-consul` - Service discovery

**Application Services (9):**
- `esante-api-gateway` (Port 3000)
- `esante-auth-service` (Port 3001)
- `esante-user-service` (Port 3002)
- `esante-rdv-service` (Port 3003)
- `esante-medical-records-service` (Port 3004)
- `esante-referral-service` (Port 3005)
- `esante-messaging-service` (Port 3006)
- `esante-notification-service` (Port 3007)
- `esante-audit-service` (Port 3008)

### Step 5: Test Backend Health
```powershell
# Test API Gateway
curl http://localhost:3000/health

# Test Auth Service
curl http://localhost:3001/health

# Test User Service
curl http://localhost:3002/health
```

✅ **Backend is ready when you get successful responses!**

---

### 🛠️ Useful Docker Commands

```powershell
# View all container logs
docker-compose logs

# View specific service logs
docker-compose logs messaging-service

# Follow logs in real-time
docker-compose logs -f api-gateway

# Restart a specific service
docker-compose restart auth-service

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v

# Rebuild a specific service
docker-compose up -d --build auth-service
```

---

### 🌐 Management UIs

Once running, you can access:
- **Consul UI**: http://localhost:8500 (View configuration)
- **Kafka UI**: http://localhost:8085 (Monitor messages)
- **MongoDB**: Use MongoDB Compass at `mongodb://admin:password@localhost:27017`

---

## 📱 Mobile App Setup

### Step 1: Navigate to Mobile App
```powershell
cd <path-to-project>\PFA_2025_ESante\mobile-app\medical_app
```

### Step 2: Install Flutter Dependencies
```powershell
flutter pub get
```

### Step 3: Configure Backend URL

⚠️ **IMPORTANT: Update the backend URL before running**

Open: [lib/core/utils/constants.dart](mobile-app/medical_app/lib/core/utils/constants.dart)

Find this line:
```dart
const String kBaseUrl = 'http://192.168.1.204:3000';
```

Change it to **YOUR COMPUTER'S IP ADDRESS**:

**On Windows:**
```powershell
# Find your IP address
ipconfig

# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.105
```

**Update the constant:**
```dart
const String kBaseUrl = 'http://YOUR_IP_ADDRESS:3000';
// Example: const String kBaseUrl = 'http://192.168.1.105:3000';
```

**Also update the socket URL:**
```dart
const String kSocketUrl = 'http://YOUR_IP_ADDRESS:3006';
```

### Step 4: Check Connected Devices
```powershell
# For Android
flutter devices

# You should see connected Android device or emulator
```

### Step 5: Run the App
```powershell
# Run on Android
flutter run

# Or run on specific device
flutter run -d <device-id>
```

✅ **The app should launch on your device/emulator**

---

## 🔗 Connecting Backend & Mobile App

### Important Network Setup

#### If Testing on Physical Device:
1. ✅ **Both phone and computer MUST be on the same WiFi network**
2. ✅ Use your computer's IP address (NOT localhost or 127.0.0.1)
3. ✅ Disable any firewall blocking port 3000-3008

#### If Testing on Emulator:
- **Android Emulator**: Use `10.0.2.2` instead of `localhost`
- **iOS Simulator**: Use `localhost` or your computer's IP

### Testing the Connection

#### From Mobile App:
1. Open the app
2. Try to register a new account
3. Check if you get a response (not a network error)

#### From Backend:
Monitor the terminal where API Gateway is running:
- You should see incoming requests
- Example: `GET /api/v1/users` or `POST /api/v1/auth/register`
-----------*********************************************------------------------------------------------**********************************-***********************************
--- 7ATA L HNA SAYE L APP T7ALET W JAWHA BAHI W TABDI TESTI 3LA RO7IK 
-----------*********************************************------------------------------------------------**********************************-***********************************
## ✅ Testing Scenarios

### 1. Authentication Flow
- [ ] **Register**: Create new patient account
- [ ] **Login**: Login with credentials
- [ ] **Verify Email**: Check email verification flow
- [ ] **Password Reset**: Test forgot password
- [ ] **Logout**: Logout and verify token is cleared

### 2. User Profile
- [ ] **View Profile**: Check patient/doctor profile display
- [ ] **Edit Profile**: Update profile information
- [ ] **Upload Photo**: Test profile picture upload

### 3. Medical Records (Dossier Medical)
- [ ] **View Medical Files**: Access "Gérer mon dossier médical"
- [ ] **Upload File**: Upload PDF or image
- [ ] **Add Description**: Add notes to medical file
- [ ] **Delete File**: Remove a medical file
- [ ] **Block Appointment**: Verify can't book appointment without medical files

### 4. Appointments (RDV)
- [ ] **Search Doctors**: Find doctors by specialty
- [ ] **View Availability**: Check doctor's time slots
- [ ] **Book Appointment**: Schedule an appointment
- [ ] **View Appointments**: See list of appointments
- [ ] **Cancel Appointment**: Cancel a scheduled appointment
- [ ] **Appointment Status**: Check pending/confirmed/cancelled status

### 5. Consultations
- [ ] **Start Consultation**: Doctor starts consultation
- [ ] **Add Notes**: Doctor adds consultation notes
- [ ] **Create Prescription**: Create prescription during consultation
- [ ] **End Consultation**: Complete consultation

### 6. Prescriptions (Ordonnances)
- [ ] **Create Prescription**: Doctor creates new prescription
- [ ] **Add Medications**: Add medicines to prescription
- [ ] **View Prescription**: Patient views prescription
- [ ] **Download Prescription**: Download as PDF

### 7. Referrals
- [ ] **Create Referral**: Doctor creates referral to specialist
- [ ] **View Referrals**: Patient sees referrals
- [ ] **Accept Referral**: Specialist accepts referral

### 8. Messaging
- [ ] **Send Message**: Send message to doctor/patient
- [ ] **Receive Message**: Check real-time message reception
- [ ] **Online Status**: Verify online/offline indicators
- [ ] **Read Receipts**: Check message read status
- [ ] **Conversation List**: View all conversations

### 9. Notifications
- [ ] **Push Notifications**: Receive FCM notifications
- [ ] **Notification List**: View notification history
- [ ] **Mark as Read**: Mark notifications as read

### 10. Search & Filters
- [ ] **Search Doctors**: Search by name or specialty
- [ ] **Filter Results**: Filter doctors by location/rating
- [ ] **Sort Results**: Sort search results

---

## 🐛 Troubleshooting

### Backend Issues

#### Docker Desktop Not Running
```
Error: Cannot connect to the Docker daemon
```
**Solution:**
- Open Docker Desktop application
- Wait for it to fully start (whale icon should be stable)
- Try the command again

#### Build Errors During docker-compose up
```
Error: failed to solve with frontend dockerfile.v0
```
**Solution:**
```powershell
# Clean Docker build cache
docker-compose down
docker system prune -a --volumes
docker-compose up -d --build
```

#### Service Won't Start / Crashing
```
Error: Container exits immediately
```
**Solution:**
```powershell
# Check service logs
docker-compose logs <service-name>

# Example:
docker-compose logs auth-service

# Look for error messages and fix configuration
```

#### Port Already in Use
```
Error: Bind for 0.0.0.0:3000 failed: port is already allocated
```
**Solution:**
```powershell
# Stop all containers
docker-compose down

# Find process using the port
netstat -ano | findstr :3000

# Kill the process
taskkill /PID <process-id> /F

# Restart
docker-compose up -d
```

#### MongoDB Connection Error
```
Error: MongoServerError: Authentication failed
```
**Solution:**
```powershell
# Restart MongoDB with clean volumes
docker-compose down -v
docker-compose up -d mongodb
# Wait 30 seconds
docker-compose up -d
```

#### Kafka Connection Error
```
Error: Kafka broker not available
```
**Solution:**
```powershell
# Restart Kafka and wait for it to fully initialize
docker-compose restart kafka
docker-compose restart zookeeper

# Wait 60 seconds for Kafka to be ready
# Then restart services
docker-compose restart auth-service user-service
```

#### Services Stuck in "Starting" State
**Solution:**
```powershell
# Check if config-seeder completed successfully
docker-compose logs config-seeder

# If failed, restart everything
docker-compose down
docker-compose up -d
```

---

### Mobile App Issues

#### Cannot Connect to Backend
```
SocketException: Failed to connect to /192.168.1.x:3000
```
**Solutions:**
1. **Check IP Address**: Verify IP in [constants.dart](mobile-app/medical_app/lib/core/utils/constants.dart)
2. **Check Network**: Phone and computer on same WiFi?
3. **Check Firewall**: Disable firewall temporarily
4. **Check Backend**: Is API Gateway running on port 3000?

Test from phone's browser: `http://YOUR_IP:3000/health`

#### Build Errors
```
Error: Gradle build failed
```
**Solution:**
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### Hot Reload Not Working
**Solution:**
```powershell
# Stop app (Ctrl+C) and restart
flutter run
```

#### Firebase Errors
```
Error: Firebase not initialized
```
**Solution:**
1. Check Firebase configuration in `android/app/google-services.json`
2. Verify Firebase project is set up correctly
3. See [FIREBASE_SETUP.md](mobile-app/medical_app/FIREBASE_SETUP.md)

---

### Network Testing

#### Test Backend from Phone
Use a browser app on your phone and visit:
```
http://YOUR_IP:3000/health
```

If this doesn't work, the problem is network connectivity.

#### Test with Postman
Install Postman and test endpoints:
```
GET http://localhost:3000/health
POST http://localhost:3000/api/v1/auth/register
```

---

## 📊 System Status Check

### Quick Health Check Script
```powershell
# Save this as check-health.ps1
$services = @(
    @{name="API Gateway"; port=3000},
    @{name="Auth Service"; port=3001},
    @{name="User Service"; port=3002},
    @{name="RDV Service"; port=3003},
    @{name="Medical Records"; port=3004},
    @{name="Referral Service"; port=3005},
    @{name="Messaging Service"; port=3006},
    @{name="Notification Service"; port=3007},
    @{name="Audit Service"; port=3008}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$($service.port)/health" -UseBasicParsing -TimeoutSec 2
        Write-Host "✅ $($service.name) (Port $($service.port)) - OK" -ForegroundColor Green
    } catch {
        Write-Host "❌ $($service.name) (Port $($service.port)) - DOWN" -ForegroundColor Red
    }
}
```

Run it:
```powershell
.\check-health.ps1
```

---

## 📝 Testing Checklist

Print this checklist and check items as you test:

### Pre-Testing Setup
- [ ] Docker Desktop installed and running
- [ ] Backend started with `docker-compose up -d --build`
- [ ] All 14 containers running (verify with `docker-compose ps`)
- [ ] Mobile app installed on device/emulator
- [ ] Device and computer on same network
- [ ] Backend URL configured correctly in constants.dart

### Basic Functionality
- [ ] User can register
- [ ] User can login
- [ ] User can view profile
- [ ] User can search doctors
- [ ] User can book appointment
- [ ] User can send message
- [ ] User receives notifications

### Advanced Features
- [ ] Medical file upload works
- [ ] Prescriptions are created correctly
- [ ] Real-time messaging works
- [ ] Online status updates properly
- [ ] File downloads work
- [ ] Email notifications sent

### Performance
- [ ] App loads quickly
- [ ] No lag when scrolling
- [ ] Images load properly
- [ ] Real-time updates are instant
- [ ] No crashes or freezes

---

## 🎯 Success Criteria

Your testing is successful when:

✅ **Backend**: All 14 Docker containers running (5 infrastructure + 9 services)  
✅ **Mobile App**: App launches and connects to backend  
✅ **Authentication**: Can register, login, and logout  
✅ **Core Features**: Appointments, messaging, and medical records work  
✅ **Real-time**: Messages and notifications arrive instantly  
✅ **Stability**: No crashes during 10-minute usage session  

---

## 📞 Getting Help

If you encounter issues:

1. **Check Container Status**: `docker-compose ps`
2. **Check Logs**: `docker-compose logs <service-name>`
3. **Check Documentation**: See [README.md](backend/README.md) for backend
4. **Check Firebase**: See [FIREBASE_SETUP.md](mobile-app/medical_app/FIREBASE_SETUP.md)
5. **Network Issues**: Verify IP address and WiFi connection
6. **Docker Issues**: Make sure Docker Desktop is running

---

## 🎉 Ready to Test!

**Quick Start Commands:**

```powershell
# Terminal 1: Start EVERYTHING (Backend Infrastructure + All Services)
cd backend
docker-compose up -d --build

# Wait 2-3 minutes for all services to start

# Terminal 2: Run Mobile App
cd mobile-app\medical_app
flutter run
```

**That's it! Everything runs in Docker automatically! 🚀**
