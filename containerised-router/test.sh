#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

# Get container IPs
get_ips() {
    ROUTER_IP_ONE=$(docker inspect -f '{{(index .NetworkSettings.Networks "network-one").IPAddress}}' router 2>/dev/null)
    ROUTER_IP_TWO=$(docker inspect -f '{{(index .NetworkSettings.Networks "network-two").IPAddress}}' router 2>/dev/null)
    CLIENT1_IP=$(docker inspect -f '{{(index .NetworkSettings.Networks "network-one").IPAddress}}' client1 2>/dev/null)
    CLIENT2_IP=$(docker inspect -f '{{(index .NetworkSettings.Networks "network-two").IPAddress}}' client2 2>/dev/null)
}

# Check if containers are running
check_containers() {
    print_header "Container Status Check"
    
    for container in router client1 client2; do
        if docker ps -q -f name=$container | grep -q .; then
            print_status "$container is running"
        else
            print_error "$container is not running"
            return 1
        fi
    done
    return 0
}

# Test ping connectivity
test_ping() {
    print_header "Ping Connectivity Tests"
    
    get_ips
    
    # Test client1 to router
    print_test "client1 → router ($ROUTER_IP_ONE)"
    if docker exec client1 ping -c 1 $ROUTER_IP_ONE &>/dev/null; then
        print_status "Ping successful"
    else
        print_error "Ping failed"
    fi
    
    # Test client2 to router
    print_test "client2 → router ($ROUTER_IP_TWO)"
    if docker exec client2 ping -c 1 $ROUTER_IP_TWO &>/dev/null; then
        print_status "Ping successful"
    else
        print_error "Ping failed"
    fi
    
    # Test client1 to client2 (through router)
    print_test "client1 → client2 ($CLIENT2_IP) [through router]"
    if docker exec client1 ping -c 1 $CLIENT2_IP &>/dev/null; then
        print_status "Ping successful"
    else
        print_error "Ping failed"
    fi
    
    # Test client2 to client1 (through router)
    print_test "client2 → client1 ($CLIENT1_IP) [through router]"
    if docker exec client2 ping -c 1 $CLIENT1_IP &>/dev/null; then
        print_status "Ping successful"
    else
        print_error "Ping failed"
    fi
}

# Test SSH connectivity
test_ssh() {
    print_header "SSH Connectivity Tests"
    
    get_ips
    
    # Test client1 to client2
    print_test "client1 → client2 SSH ($CLIENT2_IP)"
    if docker exec client1 sshpass -p "client" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 root@$CLIENT2_IP "echo 'SSH connection successful'" &>/dev/null; then
        print_status "SSH connection successful"
    else
        print_error "SSH connection failed"
    fi
    
    # Test client2 to client1
    print_test "client2 → client1 SSH ($CLIENT1_IP)"
    if docker exec client2 sshpass -p "client" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 root@$CLIENT1_IP "echo 'SSH connection successful'" &>/dev/null; then
        print_status "SSH connection successful"
    else
        print_error "SSH connection failed"
    fi
}

# Display network configuration
show_network_config() {
    print_header "Network Configuration"
    
    get_ips
    
    echo -e "${YELLOW}Router Interfaces:${NC}"
    docker exec router ifconfig 2>/dev/null | grep -A 3 "inet" || print_error "Could not retrieve interfaces"
    
    echo ""
    echo -e "${YELLOW}Router Routing Table:${NC}"
    docker exec router route -n 2>/dev/null || print_error "Could not retrieve routing table"
    
    echo ""
    echo -e "${YELLOW}Client1 Configuration:${NC}"
    docker exec client1 ifconfig 2>/dev/null | grep -A 3 "inet" || print_error "Could not retrieve client1 config"
    
    echo ""
    echo -e "${YELLOW}Client2 Configuration:${NC}"
    docker exec client2 ifconfig 2>/dev/null | grep -A 3 "inet" || print_error "Could not retrieve client2 config"
}

# Test internet connectivity through NAT
test_internet() {
    print_header "Internet Connectivity Tests (Through Router NAT)"
    
    get_ips
    
    # Test client1 internet access
    print_test "client1 → Internet (DNS/HTTP through router NAT)"
    if docker exec client1 curl -s -m 5 -o /dev/null -w "%{http_code}" http://example.com 2>/dev/null | grep -q "200\|301\|302"; then
        print_status "Internet access successful (HTTP)"
    else
        # Fallback: test DNS resolution
        if docker exec client1 nslookup example.com 2>/dev/null | grep -q "Name:"; then
            print_status "Internet access successful (DNS resolution works)"
        else
            print_error "Internet access failed"
        fi
    fi
    
    # Test client2 internet access
    print_test "client2 → Internet (DNS/HTTP through router NAT)"
    if docker exec client2 curl -s -m 5 -o /dev/null -w "%{http_code}" http://example.com 2>/dev/null | grep -q "200\|301\|302"; then
        print_status "Internet access successful (HTTP)"
    else
        # Fallback: test DNS resolution
        if docker exec client2 nslookup example.com 2>/dev/null | grep -q "Name:"; then
            print_status "Internet access successful (DNS resolution works)"
        else
            print_error "Internet access failed"
        fi
    fi
    
    # Test router DNS
    print_test "router → DNS (can resolve external addresses)"
    if docker exec router nslookup example.com 2>/dev/null | grep -q "Name:"; then
        print_status "DNS resolution successful"
    else
        print_error "DNS resolution failed"
    fi
}

# Display iptables rules on router
show_iptables() {
    print_header "Router iptables Rules"
    
    echo -e "${YELLOW}Filter Table (INPUT/OUTPUT/FORWARD):${NC}"
    docker exec router iptables -L -v 2>/dev/null || print_error "Could not retrieve iptables rules"
    
    echo ""
    echo -e "${YELLOW}NAT Table (PREROUTING/POSTROUTING):${NC}"
    docker exec router iptables -t nat -L -v 2>/dev/null || print_error "Could not retrieve NAT rules"
}

# Run all tests
run_all_tests() {
    check_containers || exit 1
    echo ""
    test_ping
    echo ""
    test_ssh
    echo ""
    test_internet
    echo ""
    show_network_config
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}Docker Network Simulation - Testing Utility${NC}"
    echo "=========================================="
    echo "1. Check container status"
    echo "2. Test ping connectivity"
    echo "3. Test SSH connectivity"
    echo "4. Test internet access (NAT)"
    echo "5. Show network configuration"
    echo "6. Show iptables rules"
    echo "7. Run all tests"
    echo "8. Shell access to router"
    echo "9. Shell access to client1"
    echo "10. Shell access to client2"
    echo "0. Exit"
    echo "=========================================="
}

# Main execution
main() {
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select an option [0-10]: " choice
            
            case $choice in
                1) check_containers ;;
                2) test_ping ;;
                3) test_ssh ;;
                4) test_internet ;;
                5) show_network_config ;;
                6) show_iptables ;;
                7) run_all_tests ;;
                8) docker exec -it router /bin/bash ;;
                9) docker exec -it client1 /bin/bash ;;
                10) docker exec -it client2 /bin/bash ;;
                0) print_status "Exiting"; exit 0 ;;
                *) print_error "Invalid option" ;;
            esac
            
            read -p "Press Enter to continue..."
        done
    else
        # Command mode
        case "$1" in
            check) check_containers ;;
            ping) test_ping ;;
            ssh) test_ssh ;;
            internet) test_internet ;;
            config) show_network_config ;;
            iptables) show_iptables ;;
            test) run_all_tests ;;
            router) docker exec -it router /bin/bash ;;
            client1) docker exec -it client1 /bin/bash ;;
            client2) docker exec -it client2 /bin/bash ;;
            *)
                echo "Usage: $0 {check|ping|ssh|internet|config|iptables|test|router|client1|client2}"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
