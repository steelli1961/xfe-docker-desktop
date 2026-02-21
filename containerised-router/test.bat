@echo off
REM =========================================================================
REM Docker Network Simulation Testing Script for Windows
REM =========================================================================
REM This is the Windows batch file equivalent of test.sh
REM For Linux/macOS, use: bash test.sh
REM For Windows, use: test.bat
REM
REM Prerequisites:
REM - Docker Desktop for Windows installed and running
REM - Command Prompt (cmd.exe) or PowerShell with admin privileges
REM - Containers running: router, client1, client2
REM
REM Usage (Interactive mode):
REM   test.bat               - Shows interactive menu
REM
REM Usage (Direct commands):
REM   test.bat check         - Check container status
REM   test.bat ping          - Test ping connectivity
REM   test.bat ssh           - Test SSH connectivity
REM   test.bat internet      - Test internet access through NAT
REM   test.bat config        - Show network configuration
REM   test.bat iptables      - Show iptables rules
REM   test.bat test          - Run all tests
REM   test.bat router        - Open shell on router
REM   test.bat client1       - Open shell on client1
REM   test.bat client2       - Open shell on client2
REM =========================================================================

setlocal enabledelayedexpansion

REM =========================================================================
REM Helper Functions for Output
REM =========================================================================

:print_header
    setlocal
    set msg=%*
    echo.
    echo ==========================================
    echo !msg!
    echo ==========================================
    endlocal
    exit /b

:print_status
    setlocal
    set msg=%*
    echo [OK] !msg!
    endlocal
    exit /b

:print_error
    setlocal
    set msg=%*
    echo [XX] !msg!
    endlocal
    exit /b

:print_test
    setlocal
    set msg=%*
    echo [TEST] !msg!
    endlocal
    exit /b

REM =========================================================================
REM Get Container IPs
REM =========================================================================

:get_ips
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"network-one\").IPAddress}}" router 2^>nul') do set "ROUTER_IP_ONE=%%a"
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"network-two\").IPAddress}}" router 2^>nul') do set "ROUTER_IP_TWO=%%a"
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"network-one\").IPAddress}}" client1 2^>nul') do set "CLIENT1_IP=%%a"
    for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"network-two\").IPAddress}}" client2 2^>nul') do set "CLIENT2_IP=%%a"
    exit /b

REM =========================================================================
REM Check Container Status
REM =========================================================================

:check_containers
    call :print_header "Container Status Check"
    
    set all_running=1
    
    for %%C in (router client1 client2) do (
        docker ps -q -f name=%%C | find "." >nul
        if errorlevel 1 (
            call :print_error "%%C is not running"
            set all_running=0
        ) else (
            call :print_status "%%C is running"
        )
    )
    
    if %all_running%==0 exit /b 1
    exit /b 0

REM =========================================================================
REM Test Ping Connectivity
REM =========================================================================

:test_ping
    call :print_header "Ping Connectivity Tests"
    
    call :get_ips
    
    REM Test client1 to router
    call :print_test "client1 → router (!ROUTER_IP_ONE!)"
    docker exec client1 ping -c 1 !ROUTER_IP_ONE! >nul 2>&1
    if errorlevel 1 (
        call :print_error "Ping failed"
    ) else (
        call :print_status "Ping successful"
    )
    
    REM Test client2 to router
    call :print_test "client2 → router (!ROUTER_IP_TWO!)"
    docker exec client2 ping -c 1 !ROUTER_IP_TWO! >nul 2>&1
    if errorlevel 1 (
        call :print_error "Ping failed"
    ) else (
        call :print_status "Ping successful"
    )
    
    REM Test client1 to client2 (through router)
    call :print_test "client1 → client2 (!CLIENT2_IP!) [through router]"
    docker exec client1 ping -c 1 !CLIENT2_IP! >nul 2>&1
    if errorlevel 1 (
        call :print_error "Ping failed"
    ) else (
        call :print_status "Ping successful"
    )
    
    REM Test client2 to client1 (through router)
    call :print_test "client2 → client1 (!CLIENT1_IP!) [through router]"
    docker exec client2 ping -c 1 !CLIENT1_IP! >nul 2>&1
    if errorlevel 1 (
        call :print_error "Ping failed"
    ) else (
        call :print_status "Ping successful"
    )
    
    exit /b 0

REM =========================================================================
REM Test SSH Connectivity
REM =========================================================================

:test_ssh
    call :print_header "SSH Connectivity Tests"
    
    call :get_ips
    
    REM Test client1 to client2
    call :print_test "client1 → client2 SSH (!CLIENT2_IP!)"
    docker exec client1 sshpass -p "client" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 root@!CLIENT2_IP! "echo SSH connection successful" >nul 2>&1
    if errorlevel 1 (
        call :print_error "SSH connection failed"
    ) else (
        call :print_status "SSH connection successful"
    )
    
    REM Test client2 to client1
    call :print_test "client2 → client1 SSH (!CLIENT1_IP!)"
    docker exec client2 sshpass -p "client" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 root@!CLIENT1_IP! "echo SSH connection successful" >nul 2>&1
    if errorlevel 1 (
        call :print_error "SSH connection failed"
    ) else (
        call :print_status "SSH connection successful"
    )
    
    exit /b 0

REM =========================================================================
REM Show Network Configuration
REM =========================================================================

:show_network_config
    call :print_header "Network Configuration"
    
    call :get_ips
    
    echo Router Interfaces:
    docker exec router ifconfig 2>nul | find "inet" || call :print_error "Could not retrieve interfaces"
    
    echo.
    echo Router Routing Table:
    docker exec router route -n 2>nul || call :print_error "Could not retrieve routing table"
    
    echo.
    echo Client1 Configuration:
    docker exec client1 ifconfig 2>nul | find "inet" || call :print_error "Could not retrieve client1 config"
    
    echo.
    echo Client2 Configuration:
    docker exec client2 ifconfig 2>nul | find "inet" || call :print_error "Could not retrieve client2 config"
    
    exit /b 0

REM =========================================================================
REM Test Internet Connectivity
REM =========================================================================

:test_internet
    call :print_header "Internet Connectivity Tests (Through Router NAT)"
    
    call :get_ips
    
    REM Test client1 internet access
    call :print_test "client1 → Internet (DNS/HTTP through router NAT)"
    docker exec client1 curl -s -m 5 -o nul -w "%%%%{http_code}" http://example.com 2>nul | find "200" >nul
    if errorlevel 1 (
        docker exec client1 nslookup example.com 2>nul | find "Name:" >nul
        if errorlevel 1 (
            call :print_error "Internet access failed"
        ) else (
            call :print_status "Internet access successful (DNS resolution works)"
        )
    ) else (
        call :print_status "Internet access successful (HTTP)"
    )
    
    REM Test client2 internet access
    call :print_test "client2 → Internet (DNS/HTTP through router NAT)"
    docker exec client2 curl -s -m 5 -o nul -w "%%%%{http_code}" http://example.com 2>nul | find "200" >nul
    if errorlevel 1 (
        docker exec client2 nslookup example.com 2>nul | find "Name:" >nul
        if errorlevel 1 (
            call :print_error "Internet access failed"
        ) else (
            call :print_status "Internet access successful (DNS resolution works)"
        )
    ) else (
        call :print_status "Internet access successful (HTTP)"
    )
    
    REM Test router DNS
    call :print_test "router → DNS (can resolve external addresses)"
    docker exec router nslookup example.com 2>nul | find "Name:" >nul
    if errorlevel 1 (
        call :print_error "DNS resolution failed"
    ) else (
        call :print_status "DNS resolution successful"
    )
    
    exit /b 0

REM =========================================================================
REM Show iptables Rules
REM =========================================================================

:show_iptables
    call :print_header "Router iptables Rules"
    
    echo Filter Table (INPUT/OUTPUT/FORWARD):
    docker exec router iptables -L -v 2>nul || call :print_error "Could not retrieve iptables rules"
    
    echo.
    echo NAT Table (PREROUTING/POSTROUTING):
    docker exec router iptables -t nat -L -v 2>nul || call :print_error "Could not retrieve NAT rules"
    
    exit /b 0

REM =========================================================================
REM Run All Tests
REM =========================================================================

:run_all_tests
    call :check_containers
    if errorlevel 1 exit /b 1
    echo.
    call :test_ping
    echo.
    call :test_ssh
    echo.
    call :test_internet
    echo.
    call :show_network_config
    exit /b 0

REM =========================================================================
REM Show Interactive Menu
REM =========================================================================

:show_menu
    echo.
    echo Docker Network Simulation - Testing Utility
    echo ===========================================
    echo 1. Check container status
    echo 2. Test ping connectivity
    echo 3. Test SSH connectivity
    echo 4. Test internet access (NAT)
    echo 5. Show network configuration
    echo 6. Show iptables rules
    echo 7. Run all tests
    echo 8. Shell access to router
    echo 9. Shell access to client1
    echo 10. Shell access to client2
    echo 0. Exit
    echo ===========================================
    exit /b 0

REM =========================================================================
REM Main Execution
REM =========================================================================

if "%1"=="" (
    REM Interactive mode
    :interactive_loop
    call :show_menu
    set /p choice="Select an option [0-10]: "
    
    if "!choice!"=="0" (
        call :print_status "Exiting"
        exit /b 0
    ) else if "!choice!"=="1" (
        call :check_containers
    ) else if "!choice!"=="2" (
        call :test_ping
    ) else if "!choice!"=="3" (
        call :test_ssh
    ) else if "!choice!"=="4" (
        call :test_internet
    ) else if "!choice!"=="5" (
        call :show_network_config
    ) else if "!choice!"=="6" (
        call :show_iptables
    ) else if "!choice!"=="7" (
        call :run_all_tests
    ) else if "!choice!"=="8" (
        docker exec -it router cmd
    ) else if "!choice!"=="9" (
        docker exec -it client1 cmd
    ) else if "!choice!"=="10" (
        docker exec -it client2 cmd
    ) else (
        call :print_error "Invalid option"
    )
    
    pause
    goto interactive_loop
) else (
    REM Command mode
    if "%1"=="check" (
        call :check_containers
    ) else if "%1"=="ping" (
        call :test_ping
    ) else if "%1"=="ssh" (
        call :test_ssh
    ) else if "%1"=="internet" (
        call :test_internet
    ) else if "%1"=="config" (
        call :show_network_config
    ) else if "%1"=="iptables" (
        call :show_iptables
    ) else if "%1"=="test" (
        call :run_all_tests
    ) else if "%1"=="router" (
        docker exec -it router cmd
    ) else if "%1"=="client1" (
        docker exec -it client1 cmd
    ) else if "%1"=="client2" (
        docker exec -it client2 cmd
    ) else (
        echo Usage: %0 {check^|ping^|ssh^|internet^|config^|iptables^|test^|router^|client1^|client2}
        exit /b 1
    )
    exit /b 0
)
