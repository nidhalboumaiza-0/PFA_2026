# Environment Variables Verification Script
# Run this to check if all .env files are properly configured

Write-Host "================================" -ForegroundColor Cyan
Write-Host "🔍 E-Santé Environment Verification" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

$services = @(
    "api-gateway",
    "services/auth-service",
    "services/user-service",
    "services/rdv-service",
    "services/medical-records-service",
    "services/referral-service",
    "services/messaging-service",
    "services/notification-service",
    "services/audit-service"
)

$allExist = $true
$needsGmail = @()

foreach ($service in $services) {
    $envPath = "backend/$service/.env"
    
    if (Test-Path $envPath) {
        Write-Host "✅ $service" -ForegroundColor Green
        
        # Check for placeholder values
        $content = Get-Content $envPath -Raw
        
        if ($content -match "your_email@gmail.com" -or $content -match "your_gmail_app_password" -or $content -match "your-email@gmail.com" -or $content -match "your_app_password") {
            $needsGmail += $service
        }
    } else {
        Write-Host "❌ $service - .env file missing!" -ForegroundColor Red
        $allExist = $false
    }
}

Write-Host "`n================================" -ForegroundColor Cyan

if ($allExist) {
    Write-Host "✅ All .env files exist!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some .env files are missing!" -ForegroundColor Yellow
}

if ($needsGmail.Count -gt 0) {
    Write-Host "`n⚠️  Gmail credentials needed in:" -ForegroundColor Yellow
    foreach ($service in $needsGmail) {
        Write-Host "   - backend/$service/.env" -ForegroundColor Yellow
    }
    Write-Host "`nReplace:" -ForegroundColor Cyan
    Write-Host "   your_email@gmail.com → your actual Gmail" -ForegroundColor White
    Write-Host "   your_gmail_app_password → your Gmail App Password" -ForegroundColor White
    Write-Host "   your-email@gmail.com → your actual Gmail" -ForegroundColor White
    Write-Host "   your_app_password → your Gmail App Password" -ForegroundColor White
} else {
    Write-Host "✅ No placeholder values found!" -ForegroundColor Green
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "🐳 Checking Docker Containers..." -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

$dockerRunning = $false
try {
    docker ps | Out-Null
    $dockerRunning = $true
    
    $containers = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-Object -Skip 1
    
    if ($containers) {
        Write-Host "Running containers:" -ForegroundColor Green
        $containers | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    } else {
        Write-Host "⚠️  No Docker containers running!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Start them with:" -ForegroundColor Cyan
        Write-Host "  cd backend"
        Write-Host "  docker-compose up -d"
        Write-Host "  docker-compose -f docker-compose.kafka.yml up -d"
    }
} catch {
    Write-Host "⚠️  Docker is not running or not installed" -ForegroundColor Yellow
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "📊 Summary" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

if ($allExist -and $needsGmail.Count -eq 0 -and $dockerRunning) {
    Write-Host "🎉 Environment is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Start services with:" -ForegroundColor Cyan
    Write-Host "  cd backend"
    Write-Host "  .\start-all-services.ps1"
} else {
    Write-Host "⚠️  Setup incomplete. Check the issues above." -ForegroundColor Yellow
    Write-Host "`nRefer to: ENV_SETUP_CHECKLIST.md" -ForegroundColor Cyan
}

Write-Host "`n================================`n" -ForegroundColor Cyan
