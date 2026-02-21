@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =========================================================================
REM Resolve Script Directory Safely (Windows-safe)
REM =========================================================================

REM %~dp0 returns path with trailing backslash — normalize it
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Change working directory to script directory (critical for Windows)
cd /d "%SCRIPT_DIR%" || (
    echo Failed to change directory to script location.
    exit /b 1
)

REM =========================================================================
REM Configuration
REM =========================================================================

set "ROUTER_IMAGE=network-router:latest"
set "CLIENT_IMAGE=network-client:latest"
set "NETWORK_ONE=network-one"
set "NETWORK_TWO=network-two"
set "BRIDGE_NETWORK=bridge-net"

color 0F
cls

goto :main


REM =========================================================================
REM Helper Functions
REM =========================================================================

:print_status
echo [*] %*
exit /b 0

:print_warning
echo [!] %*
exit /b 0

:print_error
echo [ERROR] %*
exit /b 1


REM =========================================================================
REM Core Functions
REM =========================================================================

:cleanup
call :print_warning Cleaning up existing resources...

for %%C in (router client1 client2) do (
    docker stop %%C >nul 2>&1
    docker rm %%C >nul 2>&1
)

for %%N in ("%NETWORK_ONE%" "%NETWORK_TWO%" "%BRIDGE_NETWORK%") do (
    docker network rm %%~N >nul 2>&1
)

call :print_status Cleanup complete
exit /b 0


:build_images
call :print_status Building Docker images...

docker build ^
    -f "%SCRIPT_DIR%\Dockerfile.router" ^
    -t "%ROUTER_IMAGE%" ^
    "%SCRIPT_DIR%" || exit /b 1

docker build ^
    -f "%SCRIPT_DIR%\Dockerfile.client" ^
    -t "%CLIENT_IMAGE%" ^
    "%SCRIPT_DIR%" || exit /b 1

call :print_status Images built successfully
exit /b 0


:create_networks
call :print_status Creating Docker networks...

docker network create --driver bridge "%NETWORK_ONE%" || exit /b 1
docker network create --driver bridge "%NETWORK_TWO%" || exit /b 1
docker network create --driver bridge "%BRIDGE_NETWORK%" || exit /b 1

call :print_status Networks created successfully
exit /b 0


:start_router
call :print_status Starting router container...

docker run -d ^
    --name router ^
    --network "%BRIDGE_NETWORK%" ^
    --cap-add=NET_ADMIN ^
    --cap-add=SYS_ADMIN ^
    --hostname router ^
    --dns 8.8.8.8 ^
    --dns 1.1.1.1 ^
    "%ROUTER_IMAGE%" || exit /b 1

docker network connect "%NETWORK_ONE%" router || exit /b 1
docker network connect "%NETWORK_TWO%" router || exit /b 1

timeout /t 2 /nobreak >nul

call :print_status Router started successfully
exit /b 0


:start_clients
call :print_status Starting client containers...

docker run -d ^
    --name client1 ^
    --network "%NETWORK_ONE%" ^
    --hostname client1 ^
    --cap-add=NET_ADMIN ^
    --dns 8.8.8.8 ^
    --dns 1.1.1.1 ^
    "%CLIENT_IMAGE%" || exit /b 1

docker run -d ^
    --name client2 ^
    --network "%NETWORK_TWO%" ^
    --hostname client2 ^
    --cap-add=NET_ADMIN ^
    --dns 8.8.8.8 ^
    --dns 1.1.1.1 ^
    "%CLIENT_IMAGE%" || exit /b 1

call :print_status Clients started successfully
exit /b 0


:configure_routes
call :print_status Configuring routes...

docker exec client1 route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.18.0.2 || exit /b 1
docker exec client2 route add -net 172.18.0.0 netmask 255.255.0.0 gw 172.19.0.2 || exit /b 1

call :print_status Routes configured successfully
exit /b 0


:show_info
call :print_status Network setup complete
echo.
docker ps --filter "name=router" --filter "name=client1" --filter "name=client2" ^
--format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
exit /b 0


REM =========================================================================
REM Main
REM =========================================================================

:main

echo.
echo =========================================
echo Docker Network Simulation Setup
echo =========================================
echo.

if /I "%1"=="clean" (
    call :cleanup
    exit /b 0
)

if /I "%1"=="reset" (
    call :cleanup
)

call :build_images     || goto :fatal
call :create_networks  || goto :fatal
call :start_router     || goto :fatal
call :start_clients    || goto :fatal
call :configure_routes || goto :fatal
call :show_info        || goto :fatal

echo.
call :print_status Setup complete!
exit /b 0

:fatal
call :print_error Setup failed.
exit /b 1