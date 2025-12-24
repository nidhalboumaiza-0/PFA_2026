# E-Sante Backend - Start All Services

# Use the script folder as the workspace root so paths are relative and portable
$root = $PSScriptRoot

Write-Host "Starting E-Sante Backend Microservices..." -ForegroundColor Cyan
Write-Host ""

$services = @(
    @{Name="API Gateway"; Path="api-gateway"; Port=3000},
    @{Name="Auth Service"; Path="services\auth-service"; Port=3001},
    @{Name="User Service"; Path="services\user-service"; Port=3002},
    @{Name="RDV Service"; Path="services\rdv-service"; Port=3003},
    @{Name="Medical Records Service"; Path="services\medical-records-service"; Port=3004},
    @{Name="Referral Service"; Path="services\referral-service"; Port=3005},
    @{Name="Messaging Service"; Path="services\messaging-service"; Port=3006},
    @{Name="Notification Service"; Path="services\notification-service"; Port=3007},
    @{Name="Audit Service"; Path="services\audit-service"; Port=3008}
)

foreach ($service in $services) {
    Write-Host "Starting $($service.Name) on port $($service.Port)..." -ForegroundColor Green
    $servicePath = Join-Path $root $service.Path
    if (-Not (Test-Path $servicePath)) {
        Write-Host "Path not found: $servicePath - skipping" -ForegroundColor Yellow
        continue
    }
    $command = "cd '$servicePath'; npm run dev"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $command -WorkingDirectory $servicePath
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "All services launching in separate PowerShell windows..." -ForegroundColor Green
Write-Host "Wait 10-20 seconds then check health endpoints or run the test script (e.g., python test_api.py)." -ForegroundColor Yellow
    # Use the script folder as the workspace root so paths are relative and portable
    $root = $PSScriptRoot

    # Optionally bring up Docker infra (MongoDB, Redis, Kafka)
    Try {
        Write-Host "Bringing up Docker infrastructure via docker-compose..." -ForegroundColor Cyan
        $composeFile = Join-Path $root 'docker-compose.yml'
        if (Test-Path $composeFile) {
            Write-Host "Running: docker-compose -f $composeFile -f $root\docker-compose.kafka.yml up -d" -ForegroundColor DarkCyan
            docker-compose -f "$composeFile" -f "$root\docker-compose.kafka.yml" up -d | Out-Null
            Write-Host "Docker infrastructure started (or already running)." -ForegroundColor Green
        } else {
            Write-Host "docker-compose.yml not found in $root - skipping infra startup." -ForegroundColor Yellow
        }
    } Catch {
        Write-Host "Failed to start Docker infra (docker-compose may not be available): $_" -ForegroundColor Yellow
    }
