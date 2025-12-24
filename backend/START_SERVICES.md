# 🚀 E-Santé Backend - Service Startup Guide

## Prerequisites Checklist

Before starting the services, make sure:

- ✅ Node.js installed (v14 or higher)
- ✅ MongoDB installed or Docker available
- ✅ Kafka installed or Docker available
- ✅ All dependencies installed (`npm install` in each service)
- ✅ All .env files configured

---

## Option 1: Quick Start with Docker (RECOMMENDED)

### Step 1: Start MongoDB and Kafka with Docker

```powershell
# Navigate to backend folder
cd c:\Users\nidha\Desktop\pfa\backend

# Start MongoDB, Kafka, and Zookeeper
docker-compose up -d

# Verify containers are running
docker ps
```

You should see 3 containers:
- `mongodb` (port 27017)
- `kafka` (port 9092)
- `zookeeper` (port 2181)

---

## Step 2: Start All Microservices

Open **8 separate PowerShell terminals** and run one service in each:

### Terminal 1 - Auth Service (Port 3001)
```powershell
cd c:\Users\nidha\Desktop\pfa\backend\services\auth-service
npm run dev
```

### Terminal 2 - User Service (Port 3002)
```powershell
cd c:\Users\nidha\Desktop\pfa\backend\services\user-service
npm run dev
```

### Terminal 3 - RDV Service (Port 3003)
```powershell
cd c:\Users\nidha\Desktop\pfa\backend\services\rdv-service
npm run dev
```

### Terminal 4 - Medical Records Service (Port 3004)
```powershell
cd c:\Users\nidha\Desktop\pfa\backend\services\medical-records-service
npm run dev
```

### Terminal 5 - Messaging Service (Port 3006)
```powershell
cd c:\Users\nidha\Desktop\pfa\backend\services\messaging-service
npm run dev
```

### Terminal 6 - Notification Service (Port 3007)
```powershell
cd c:\Users\nidha\Desktop\pfa\backend\services\notification-service
npm run dev
```

### Terminal 7 - Referral Service (Port 3005)
```powershell
cd c:\Users\nidha\Desktop\pfa\backend\services\referral-service
npm run dev
```

### Terminal 8 - Audit Service (Port 3008)
```powershell
cd c:\Users\nidha\Desktop\pfa\backend\services\audit-service
npm run dev
```

---

## Step 3: Verify All Services Are Running

Open a new terminal and check each service health endpoint:

```powershell
# Test all services
curl http://localhost:3001/health  # Auth
curl http://localhost:3002/health  # User
curl http://localhost:3003/health  # RDV
curl http://localhost:3004/health  # Medical Records
curl http://localhost:3006/health  # Messaging
curl http://localhost:3007/health  # Notification
curl http://localhost:3005/health  # Referral
curl http://localhost:3008/health  # Audit
```

---

## Step 4: Run Tests

Once all services show "healthy", run the test script:

```powershell
cd c:\Users\nidha\Desktop\pfa\backend
python test_api.py
```

---

## Option 2: Start All Services with One Command

Create a `start-all.ps1` script:

```powershell
# Start all services in background
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\Users\nidha\Desktop\pfa\backend\services\auth-service; npm run dev"
Start-Sleep 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\Users\nidha\Desktop\pfa\backend\services\user-service; npm run dev"
Start-Sleep 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\Users\nidha\Desktop\pfa\backend\services\rdv-service; npm run dev"
Start-Sleep 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\Users\nidha\Desktop\pfa\backend\services\medical-records-service; npm run dev"
Start-Sleep 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\Users\nidha\Desktop\pfa\backend\services\messaging-service; npm run dev"
Start-Sleep 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\Users\nidha\Desktop\pfa\backend\services\notification-service; npm run dev"
Start-Sleep 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\Users\nidha\Desktop\pfa\backend\services\referral-service; npm run dev"
Start-Sleep 2
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd c:\Users\nidha\Desktop\pfa\backend\services\audit-service; npm run dev"

Write-Host "All services starting... Wait 30 seconds before testing" -ForegroundColor Green
```

---

## Troubleshooting

### Issue: "Port already in use"
```powershell
# Find process using port (e.g., 3001)
netstat -ano | findstr :3001

# Kill process by PID
taskkill /PID <PID> /F
```

### Issue: "MongoDB connection failed"
```powershell
# Check if MongoDB is running
docker ps | findstr mongodb

# Check MongoDB logs
docker logs mongodb

# Restart MongoDB
docker-compose restart mongodb
```

### Issue: "Kafka connection failed"
```powershell
# Check Kafka and Zookeeper
docker ps | findstr kafka

# Restart Kafka
docker-compose restart kafka zookeeper
```

### Issue: "Cannot find module"
```powershell
# Reinstall dependencies in specific service
cd services/<service-name>
rm -rf node_modules
rm package-lock.json
npm install
```

---

## Service Ports Reference

| Service | Port | Description |
|---------|------|-------------|
| Auth Service | 3001 | Authentication & Authorization |
| User Service | 3002 | User profiles & Doctor search |
| RDV Service | 3003 | Appointments & Time slots |
| Medical Records | 3004 | Consultations, Prescriptions, Documents |
| Referral Service | 3005 | Doctor referrals |
| Messaging Service | 3006 | Real-time chat |
| Notification Service | 3007 | Push, Email, In-app notifications |
| Audit Service | 3008 | Activity logging |
| MongoDB | 27017 | Database |
| Kafka | 9092 | Event streaming |
| Zookeeper | 2181 | Kafka coordination |

---

## Expected Startup Messages

When each service starts correctly, you should see:

```
✓ Connected to MongoDB
✓ Kafka Consumer connected
✓ Server running on port XXXX
✓ Health check endpoint: http://localhost:XXXX/health
```

---

## Next Steps After All Services Are Running

1. ✅ Run `python test_api.py` - Should show all tests passing
2. ✅ Check MongoDB - Data should be created
3. ✅ Check Kafka topics - Events should be flowing
4. ✅ Test real-time features - Socket.IO, notifications
5. ✅ Test file uploads - S3 integration
6. ✅ Test push notifications - OneSignal
7. ✅ Test email notifications - Nodemailer (if configured)

---

## Quick Health Check

```powershell
# One-liner to check all services
@(3001,3002,3003,3004,3005,3006,3007,3008) | ForEach-Object { 
    try { 
        $response = Invoke-WebRequest -Uri "http://localhost:$_/health" -UseBasicParsing -TimeoutSec 2
        Write-Host "Port $_: OK" -ForegroundColor Green
    } catch { 
        Write-Host "Port $_: DOWN" -ForegroundColor Red
    }
}
```

Good luck! 🚀
