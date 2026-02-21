@echo off
REM =========================================================================
REM Docker Network Simulation Setup Script for Windows
REM =========================================================================
REM This is the Windows batch file equivalent of setup.sh
REM For Linux/macOS, use: bash setup.sh
REM For Windows, use: setup.bat
REM
REM Prerequisites:
REM - Docker Desktop for Windows installed and running
REM - Command Prompt (cmd.exe) or PowerShell with admin privileges
REM
REM Usage:
REM   setup.bat          - Full setup with cleanup of existing resources
REM   setup.bat clean    - Only cleanup existing resources
REM   setup.bat reset    - Reset by cleaning up and then setting up fresh
REM =========================================================================

setlocal enabledelayedexpansion

REM Configuration
set ROUTER_IMAGE=network-router:latest
set CLIENT_IMAGE=network-client:latest
set NETWORK_ONE=network-one
set NETWORK_TWO=network-two
set BRIDGE_NETWORK=bridge-net

REM Get script directory
set SCRIPT_DIR=%~dp0

REM =========================================================================
REM Color output setup (limited colors in batch)
REM =========================================================================
REM Windows batch has limited color support. Using basic colors:
REM 0A = Bright Green, 0C = Bright Red, 0E = Bright Yellow, 0B = Bright Cyan

cls
color 0F

REM =========================================================================
REM Helper Functions
REM =========================================================================

REM Print status message
setlocal enabledelayedexpansion
goto :skip_functions
:print_status
    setlocal
    set msg=%*
    echo [*] !msg!
    endlocal
    exit /b

:print_error
    setlocal
    set msg=%*
    echo [!] !msg!
    endlocal
    exit /b

:print_warning
    setlocal
    set msg=%*
    echo [!] !msg!
    endlocal
    exit /b

:skip_functions
endlocal

REM =========================================================================
REM Main Functions
REM =========================================================================

REM Cleanup function
:cleanup
    call :print_warning "Cleaning up existing resources..."
    
    REM Stop and remove containers
    for %%C in (router client1 client2) do (
        docker stop %%C >nul 2>&1
        docker rm %%C >nul 2>&1
    )
    
    REM Remove networks
    for %%N in (%NETWORK_ONE% %NETWORK_TWO% %BRIDGE_NETWORK%) do (
        docker network rm %%N >nul 2>&1
    )
    
    call :print_status "Cleanup complete"
    exit /b

REM Build images function
:build_images
    call :print_status "Building Docker images..."
    
    docker build -f "%SCRIPT_DIR%Dockerfile.router" -t %ROUTER_IMAGE% "%SCRIPT_DIR%"
    if errorlevel 1 (
        call :print_error "Failed to build router image"
        exit /b 1
    )
    
    docker build -f "%SCRIPT_DIR%Dockerfile.client" -t %CLIENT_IMAGE% "%SCRIPT_DIR%"
    if errorlevel 1 (
        call :print_error "Failed to build client image"
        exit /b 1
    )
    
    call :print_status "Images built successfully"
    exit /b

REM Create networks function
:create_networks
    call :print_status "Creating Docker networks..."
    
    docker network create --driver bridge %NETWORK_ONE%
    if errorlevel 1 (
        call :print_error "Failed to create %NETWORK_ONE%"
        exit /b 1
    )
    
    docker network create --driver bridge %NETWORK_TWO%
    if errorlevel 1 (
        call :print_error "Failed to create %NETWORK_TWO%"
        exit /b 1
    )
    
    docker network create --driver bridge %BRIDGE_NETWORK%
    if errorlevel 1 (
        call :print_error "Failed to create %BRIDGE_NETWORK%"
        exit /b 1
    )
    
    call :print_status "Networks created successfully"
    exit /b

REM Start router function
:start_router
    call :print_status "Starting router container..."
    
    docker run -d ^
        --name router ^
        --network %BRIDGE_NETWORK% ^
        --cap-add=NET_ADMIN ^
        --cap-add=SYS_ADMIN ^
        --hostname router ^
        --dns 8.8.8.8 ^
        --dns 1.1.1.1 ^
        %ROUTER_IMAGE%
    if errorlevel 1 (
        call :print_error "Failed to start router container"
        exit /b 1
    )
    
    REM Connect router to network-one and network-two
    docker network connect %NETWORK_ONE% router
    if errorlevel 1 (
        call :print_error "Failed to connect router to %NETWORK_ONE%"
        exit /b 1
    )
    
    docker network connect %NETWORK_TWO% router
    if errorlevel 1 (
        call :print_error "Failed to connect router to %NETWORK_TWO%"
        exit /b 1
    )
    
    call :print_status "Router container started and connected to all networks"
    
    REM Give the router time to fully initialize
    timeout /t 2 /nobreak
    exit /b

REM Start clients function
:start_clients
    call :print_status "Starting client containers..."
    
    docker run -d ^
        --name client1 ^
        --network %NETWORK_ONE% ^
        --hostname client1 ^
        --cap-add=NET_ADMIN ^
        --dns 8.8.8.8 ^
        --dns 1.1.1.1 ^
        %CLIENT_IMAGE%
    if errorlevel 1 (
        call :print_error "Failed to start client1"
        exit /b 1
    )
    
    docker run -d ^
        --name client2 ^
        --network %NETWORK_TWO% ^
        --hostname client2 ^
        --cap-add=NET_ADMIN ^
        --dns 8.8.8.8 ^
        --dns 1.1.1.1 ^
        %CLIENT_IMAGE%
    if errorlevel 1 (
        call :print_error "Failed to start client2"
        exit /b 1
    )
    
    call :print_status "Client containers started"
    exit /b

REM Configure routes function
:configure_routes
    call :print_status "Configuring routes for cross-network communication..."
    
    REM Add route on client1 to reach network-two through router
    docker exec client1 route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.18.0.2
    if errorlevel 1 (
        call :print_error "Failed to add route on client1"
        exit /b 1
    )
    
    REM Add route on client2 to reach network-one through router
    docker exec client2 route add -net 172.18.0.0 netmask 255.255.0.0 gw 172.19.0.2
    if errorlevel 1 (
        call :print_error "Failed to add route on client2"
        exit /b 1
    )
    
    call :print_status "Routes configured successfully"
    exit /b

REM Show info function
:show_info
    call :print_status "Network setup complete! Here's the configuration:"
    echo.
    
    REM Get IPs
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"%NETWORK_ONE%\").IPAddress}}" router 2^>nul') do set "ROUTER_IP_ONE=%%a"
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"%NETWORK_TWO%\").IPAddress}}" router 2^>nul') do set "ROUTER_IP_TWO=%%a"
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"%BRIDGE_NETWORK%\").IPAddress}}" router 2^>nul') do set "ROUTER_IP_BRIDGE=%%a"
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"%NETWORK_ONE%\").IPAddress}}" client1 2^>nul') do set "CLIENT1_IP=%%a"
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"%NETWORK_TWO%\").IPAddress}}" client2 2^>nul') do set "CLIENT2_IP=%%a"
    
    echo Router IPs:
    echo   - Bridge (Internet):   %ROUTER_IP_BRIDGE%
    echo   - Network One:         %ROUTER_IP_ONE%
    echo   - Network Two:         %ROUTER_IP_TWO%
    echo.
    echo Client IPs:
    echo   - Client1 (Network One): %CLIENT1_IP%
    echo   - Client2 (Network Two): %CLIENT2_IP%
    echo.
    echo Useful Commands:
    echo   # Shell access to containers:
    echo   docker exec -it router cmd
    echo   docker exec -it client1 cmd
    echo   docker exec -it client2 cmd
    echo.
    echo   # Test connectivity from client1:
    echo   docker exec client1 ping %CLIENT2_IP%
    echo   docker exec client1 ping %ROUTER_IP_ONE%
    echo.
    echo   # View iptables rules on router:
    echo   docker exec router iptables -L -v
    echo   docker exec router iptables -t nat -L -v
    echo.
    echo Container Status:
    docker ps --filter "name=router" --filter "name=client1" --filter "name=client2" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit /b

REM =========================================================================
REM Main Script Execution
REM =========================================================================

cls
echo.
echo =========================================
echo Docker Network Simulation Setup
echo =========================================
echo.

REM Check for command line arguments
if "%1"=="clean" (
    call :cleanup
    call :print_status "Cleaned up. Run without 'clean' argument to setup"
    exit /b 0
)

if "%1"=="reset" (
    call :cleanup
)

call :build_images
if errorlevel 1 exit /b 1

call :create_networks
if errorlevel 1 exit /b 1

call :start_router
if errorlevel 1 exit /b 1

call :start_clients
if errorlevel 1 exit /b 1

call :configure_routes
if errorlevel 1 exit /b 1

call :show_info

echo.
call :print_status "Setup complete!"
exit /b 0
