@echo off
echo Starting E-Sante Backend Services...

:: API Gateway
start "API Gateway" cmd /k "cd backend/api-gateway && npm run dev"

:: Auth Service
start "Auth Service" cmd /k "cd backend/services/auth-service && npm run dev"

:: User Service
start "User Service" cmd /k "cd backend/services/user-service && npm run dev"

:: RDV Service
start "RDV Service" cmd /k "cd backend/services/rdv-service && npm run dev"

:: Medical Records Service
start "Medical Records Service" cmd /k "cd backend/services/medical-records-service && npm run dev"

:: Messaging Service
start "Messaging Service" cmd /k "cd backend/services/messaging-service && npm run dev"

:: Notification Service
start "Notification Service" cmd /k "cd backend/services/notification-service && npm run dev"

:: Audit Service
start "Audit Service" cmd /k "cd backend/services/audit-service && npm run dev"

:: Referral Service
start "Referral Service" cmd /k "cd backend/services/referral-service && npm run dev"

echo All services started in separate windows!
pause
