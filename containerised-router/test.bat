@echo off
setlocal EnableExtensions EnableDelayedExpansion

goto :main

REM =========================================================================
REM Helper Functions
REM =========================================================================

:print_header
echo.
echo ==========================================
echo %*
echo ==========================================
exit /b 0

:print_status
echo [OK] %*
exit /b 0

:print_error
echo [XX] %*
exit /b 1

:print_test
echo [TEST] %*
exit /b 0


REM =========================================================================
REM Get Container IPs
REM =========================================================================

:get_ips
for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"network-one\").IPAddress}}" router 2^>nul') do set "ROUTER_IP_ONE=%%a"
for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"network-two\").IPAddress}}" router 2^>nul') do set "ROUTER_IP_TWO=%%a"
for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"network-one\").IPAddress}}" client1 2^>nul') do set "CLIENT1_IP=%%a"
for /f "delims=" %%a in ('docker inspect -f "{{(index .NetworkSettings.Networks \"network-two\").IPAddress}}" client2 2^>nul') do set "CLIENT2_IP=%%a"
exit /b 0


REM =========================================================================
REM Container Checks
REM =========================================================================

:check_containers
call :print_header Container Status Check
set "all_running=1"

for %%C in (router client1 client2) do (
    docker ps -q -f name=%%C | find "." >nul
    if errorlevel 1 (
        call :print_error %%C is not running
        set "all_running=0"
    ) else (
        call :print_status %%C is running
    )
)

if "!all_running!"=="0" exit /b 1
exit /b 0


REM =========================================================================
REM Ping Tests
REM =========================================================================

:test_ping
call :print_header Ping Connectivity Tests
call :get_ips

call :print_test client1 → router (!ROUTER_IP_ONE!)
docker exec client1 ping -c 1 !ROUTER_IP_ONE! >nul 2>&1
if errorlevel 1 (call :print_error Ping failed) else (call :print_status Ping successful)

call :print_test client2 → router (!ROUTER_IP_TWO!)
docker exec client2 ping -c 1 !ROUTER_IP_TWO! >nul 2>&1
if errorlevel 1 (call :print_error Ping failed) else (call :print_status Ping successful)

call :print_test client1 → client2 (!CLIENT2_IP!)
docker exec client1 ping -c 1 !CLIENT2_IP! >nul 2>&1
if errorlevel 1 (call :print_error Ping failed) else (call :print_status Ping successful)

call :print_test client2 → client1 (!CLIENT1_IP!)
docker exec client2 ping -c 1 !CLIENT1_IP! >nul 2>&1
if errorlevel 1 (call :print_error Ping failed) else (call :print_status Ping successful)

exit /b 0


REM =========================================================================
REM Internet Test (Windows-safe curl formatting)
REM =========================================================================

:test_internet
call :print_header Internet Connectivity Test

call :print_test client1 → Internet
docker exec client1 curl -s -m 5 -o nul -w "%%%%{http_code}" http://example.com 2>nul | find "200" >nul
if errorlevel 1 (
    call :print_error Internet failed
) else (
    call :print_status Internet OK
)

call :print_test client2 → Internet
docker exec client2 curl -s -m 5 -o nul -w "%%%%{http_code}" http://example.com 2>nul | find "200" >nul
if errorlevel 1 (
    call :print_error Internet failed
) else (
    call :print_status Internet OK
)

exit /b 0


REM =========================================================================
REM Run All Tests
REM =========================================================================

:run_all_tests
call :check_containers || exit /b 1
echo.
call :test_ping
echo.
call :test_internet
exit /b 0


REM =========================================================================
REM Menu
REM =========================================================================

:show_menu
echo.
echo Docker Network Simulation - Testing Utility
echo ===========================================
echo 1. Check container status
echo 2. Test ping connectivity
echo 3. Test internet access
echo 4. Run all tests
echo 5. Router shell
echo 6. Client1 shell
echo 7. Client2 shell
echo 0. Exit
echo ===========================================
exit /b 0


REM =========================================================================
REM Main
REM =========================================================================

:main

if "%1"=="" (
    :loop
    call :show_menu
    set /p choice=Select an option: 

    if "!choice!"=="0" exit /b 0
    if "!choice!"=="1" call :check_containers
    if "!choice!"=="2" call :test_ping
    if "!choice!"=="3" call :test_internet
    if "!choice!"=="4" call :run_all_tests
    if "!choice!"=="5" docker exec -it router cmd
    if "!choice!"=="6" docker exec -it client1 cmd
    if "!choice!"=="7" docker exec -it client2 cmd

    pause
    goto loop
)

if /I "%1"=="check"    call :check_containers
if /I "%1"=="ping"     call :test_ping
if /I "%1"=="internet" call :test_internet
if /I "%1"=="test"     call :run_all_tests
if /I "%1"=="router"   docker exec -it router cmd
if /I "%1"=="client1"  docker exec -it client1 cmd
if /I "%1"=="client2"  docker exec -it client2 cmd

exit /b 0