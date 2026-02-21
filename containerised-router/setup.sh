#!/bin/bash

################################################################################
# Docker Network Simulation Setup Script for Linux/macOS
################################################################################
#
# This script sets up a Docker network simulation environment with:
# - A router container with iptables and routing capabilities
# - Two client containers connected through the router
# - Network isolation and connectivity testing
#
# USAGE (Linux/macOS):
#   bash setup.sh          - Full setup with cleanup of existing resources
#   bash setup.sh clean    - Only cleanup existing resources
#   bash setup.sh reset    - Reset by cleaning up and then setting up fresh
#
# WINDOWS USERS:
#   Use setup.bat instead (Windows batch file equivalent)
#   Command Prompt: setup.bat
#   PowerShell:     .\setup.bat
#
# REQUIREMENTS:
#   - Docker and Docker Compose installed
#   - For Linux: Elevated privileges may be needed for iptables rules
#   - For macOS: Docker Desktop app running
#   - For Windows: Docker Desktop for Windows + Command Prompt or PowerShell
#
# CROSS-PLATFORM NOTES:
#   - Shell script version (setup.sh): Linux/macOS - uses bash, ANSI colors
#   - Batch version (setup.bat): Windows - uses Command Prompt/PowerShell
#   - Both versions perform identical setup operations
#   - Docker commands work the same across all platforms
#
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROUTER_IMAGE="network-router:latest"
CLIENT_IMAGE="network-client:latest"
NETWORK_ONE="network-one"
NETWORK_TWO="network-two"
BRIDGE_NETWORK="bridge-net"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Cleanup function
cleanup() {
    print_warning "Cleaning up existing resources..."
    
    # Stop and remove containers
    docker stop router client1 client2 2>/dev/null || true
    docker rm router client1 client2 2>/dev/null || true
    
    # Remove networks
    docker network rm $NETWORK_ONE $NETWORK_TWO $BRIDGE_NETWORK 2>/dev/null || true
    
    print_status "Cleanup complete"
}

# Build images
build_images() {
    print_status "Building Docker images..."
    
    docker build -f "$SCRIPT_DIR/Dockerfile.router" -t $ROUTER_IMAGE "$SCRIPT_DIR/" || {
        print_error "Failed to build router image"
        exit 1
    }
    
    docker build -f "$SCRIPT_DIR/Dockerfile.client" -t $CLIENT_IMAGE "$SCRIPT_DIR/" || {
        print_error "Failed to build client image"
        exit 1
    }
    
    print_status "Images built successfully"
}

# Create networks
create_networks() {
    print_status "Creating Docker networks..."
    
    docker network create --driver bridge $NETWORK_ONE || {
        print_error "Failed to create $NETWORK_ONE"
        exit 1
    }
    
    docker network create --driver bridge $NETWORK_TWO || {
        print_error "Failed to create $NETWORK_TWO"
        exit 1
    }
    
    docker network create --driver bridge $BRIDGE_NETWORK || {
        print_error "Failed to create $BRIDGE_NETWORK"
        exit 1
    }
    
    print_status "Networks created successfully"
}

# Start router container
start_router() {
    print_status "Starting router container..."
    
    docker run -d \
        --name router \
        --network $BRIDGE_NETWORK \
        --cap-add=NET_ADMIN \
        --cap-add=SYS_ADMIN \
        --hostname router \
        --dns 8.8.8.8 \
        --dns 1.1.1.1 \
        $ROUTER_IMAGE || {
        print_error "Failed to start router container"
        exit 1
    }
    
    # Connect router to network-one and network-two
    docker network connect $NETWORK_ONE router || {
        print_error "Failed to connect router to $NETWORK_ONE"
        exit 1
    }
    
    docker network connect $NETWORK_TWO router || {
        print_error "Failed to connect router to $NETWORK_TWO"
        exit 1
    }
    
    print_status "Router container started and connected to all networks"
    
    # Give the router a moment to fully initialize
    sleep 2
}

# Start client containers
start_clients() {
    print_status "Starting client containers..."
    
    docker run -d \
        --name client1 \
        --network $NETWORK_ONE \
        --hostname client1 \
        --cap-add=NET_ADMIN \
        --dns 8.8.8.8 \
        --dns 1.1.1.1 \
        $CLIENT_IMAGE || {
        print_error "Failed to start client1"
        exit 1
    }
    
    docker run -d \
        --name client2 \
        --network $NETWORK_TWO \
        --hostname client2 \
        --cap-add=NET_ADMIN \
        --dns 8.8.8.8 \
        --dns 1.1.1.1 \
        $CLIENT_IMAGE || {
        print_error "Failed to start client2"
        exit 1
    }
    
    print_status "Client containers started"
}

# Configure routes on clients for cross-network communication
configure_routes() {
    print_status "Configuring routes for cross-network communication..."
    
    # Add route on client1 to reach network-two through router
    docker exec client1 route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.18.0.2 || {
        print_error "Failed to add route on client1"
        exit 1
    }
    
    # Add route on client2 to reach network-one through router
    docker exec client2 route add -net 172.18.0.0 netmask 255.255.0.0 gw 172.19.0.2 || {
        print_error "Failed to add route on client2"
        exit 1
    }
    
    print_status "Routes configured successfully"
}

# Display network information
show_info() {
    print_status "Network setup complete! Here's the configuration:"
    echo ""
    
    # Get IPs
    ROUTER_IP_ONE=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{if eq .NetworkID (index (docker network inspect '$NETWORK_ONE' -f "{{.ID}}") 0)}}{{.IPAddress}}{{end}}{{end}}' router)
    ROUTER_IP_TWO=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{if eq .NetworkID (index (docker network inspect '$NETWORK_TWO' -f "{{.ID}}") 0)}}{{.IPAddress}}{{end}}{{end}}' router)
    ROUTER_IP_BRIDGE=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{if eq .Name "'$BRIDGE_NETWORK'"}}{{.IPAddress}}{{end}}{{end}}' router)
    CLIENT1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{if eq .Name "'$NETWORK_ONE'"}}{{.IPAddress}}{{end}}{{end}}' client1)
    CLIENT2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{if eq .Name "'$NETWORK_TWO'"}}{{.IPAddress}}{{end}}{{end}}' client2)
    
    echo -e "${YELLOW}Router IPs:${NC}"
    echo "  - Bridge (Internet):   $ROUTER_IP_BRIDGE"
    echo "  - Network One:         $ROUTER_IP_ONE"
    echo "  - Network Two:         $ROUTER_IP_TWO"
    echo ""
    echo -e "${YELLOW}Client IPs:${NC}"
    echo "  - Client1 (Network One): $CLIENT1_IP"
    echo "  - Client2 (Network Two): $CLIENT2_IP"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  # SSH into containers:"
    echo "  docker exec -it router /bin/bash"
    echo "  docker exec -it client1 /bin/bash"
    echo "  docker exec -it client2 /bin/bash"
    echo ""
    echo "  # Test connectivity from client1:"
    echo "  docker exec client1 ping $CLIENT2_IP"
    echo "  docker exec client1 ping $ROUTER_IP_ONE"
    echo "  docker exec client1 ssh -o StrictHostKeyChecking=no root@$CLIENT2_IP"
    echo ""
    echo "  # View iptables rules on router:"
    echo "  docker exec router iptables -L -v"
    echo "  docker exec router iptables -t nat -L -v"
    echo ""
    echo -e "${YELLOW}Container Status:${NC}"
    docker ps --filter "name=router\|client1\|client2" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main execution
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Docker Network Simulation Setup${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Check if cleanup flag is passed
    if [[ "$1" == "clean" ]]; then
        cleanup
        print_status "Cleaned up. Run without 'clean' argument to setup"
        exit 0
    fi
    
    # Check if we're doing a full reset
    if [[ "$1" == "reset" ]]; then
        cleanup
    fi
    
    build_images
    create_networks
    start_router
    start_clients
    configure_routes
    show_info
    
    echo ""
    print_status "Setup complete!"
}

# Run main function
main "$@"
