# Containerized Router - Complete Documentation

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Building](#building)
6. [Setup and Configuration](#setup-and-configuration)
7. [Testing](#testing)
8. [Manual Testing](#manual-testing)
9. [Troubleshooting](#troubleshooting)
10. [Project Files Reference](#project-files-reference)

---

## 🎯 Project Overview

This project demonstrates a containerized network simulation featuring a router connecting two isolated networks. It's designed to simulate real-world network scenarios using Docker containers.

### Key Features

- **Dual-Network Router**: A router container bridges two separate Docker networks (network-one and network-two)
- **Client Network Simulation**: Two client containers, one in each network, simulate endpoint communication
- **Cross-Network Communication**: Clients can communicate across networks through the router
- **NAT Support**: Network Address Translation enables containers to reach external networks/internet
- **SSH Connectivity**: Secure shell access between containers for remote management
- **Comprehensive Testing**: Automated test suite validates connectivity and network configuration

### Use Cases

- Learning Docker networking concepts
- Testing network routing and firewall rules
- Developing network simulation scenarios
- Understanding iptables and NAT configuration
- Practicing container orchestration

---

## 🏗️ Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Host Machine                       │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   client1    │         │   client2    │                 │
│  │  172.18.0.3  │         │  172.19.0.3  │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                       │                           │
│    network-one              network-two                     │
│    172.18.0.0/16            172.19.0.0/16                  │
│         │                       │                           │
│         └───────────┬───────────┘                           │
│                     │                                       │
│              ┌──────────────┐                               │
│              │    router    │                               │
│              │ 172.18.0.2   │ (network-one)                │
│              │ 172.19.0.2   │ (network-two)                │
│              │ 172.20.0.2   │ (bridge-net)                 │
│              └──────────────┘                               │
│                     │                                       │
│                 bridge-net                                  │
│              172.20.0.0/16                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Container Details

| Component | Image | Networks | Purpose |
|-----------|-------|----------|---------|
| **router** | `network-router:latest` | bridge-net, network-one, network-two | Routes traffic between networks, NAT, iptables rules |
| **client1** | `network-client:latest` | network-one | Client in first network (172.18.0.3) |
| **client2** | `network-client:latest` | network-two | Client in second network (172.19.0.3) |

### Network Types

| Network | Purpose | Subnet | Gateway |
|---------|---------|--------|---------|
| **bridge-net** | Simulates internet/external access | 172.20.0.0/16 | 172.20.0.1 |
| **network-one** | First isolated network | 172.18.0.0/16 | 172.18.0.1 |
| **network-two** | Second isolated network | 172.19.0.0/16 | 172.19.0.1 |

---

## 📋 Prerequisites

### System Requirements

- **Docker**: Version 20.10+ (with Docker Compose optional)
- **OS**: Linux, macOS, or Windows with WSL2
- **Memory**: Minimum 2GB RAM available
- **Disk**: Minimum 500MB free space for images

### Required Tools

- `docker` - Container runtime
- `bash` - Script interpreter
- Standard Unix tools: `grep`, `sed`, `awk`

### Verify Prerequisites

```bash
# Check Docker installation
docker --version
docker ps

# Check bash availability
bash --version
```

---

## 🚀 Quick Start

### One-Command Setup

```bash
cd /path/to/containerised-router
bash setup.sh
```

### One-Command Test

```bash
bash test.sh test
```

### Cleanup

```bash
bash setup.sh clean
```

---

## 🔨 Building

### Step 1: Review the Project Structure

```
containerised-router/
├── Dockerfile.router          # Router container configuration
├── Dockerfile.client          # Client container configuration
├── entrypoint-router.sh       # Router startup script
├── setup.sh                   # Setup and deployment script
├── test.sh                    # Testing utility script
└── README.md                  # This file
```

### Step 2: Build Docker Images

The build process is handled automatically by `setup.sh`, but you can also build manually:

```bash
# Build router image
docker build -f Dockerfile.router -t network-router:latest .

# Build client image
docker build -f Dockerfile.client -t network-client:latest .
```

### Image Details

#### Router Image (Dockerfile.router)

**Base**: Ubuntu 22.04

**Installed Packages**:
- `iproute2` - Advanced IP routing
- `iptables` - Firewall and NAT rules
- `openssh-server` & `openssh-client` - SSH connectivity
- `iputils-ping` - Network diagnostics
- `net-tools` - Network utilities (ifconfig, route)
- `curl` - HTTP client
- `vim` - Text editor

**Configuration**:
- Enables IP forwarding (`net.ipv4.ip_forward=1`)
- Configures SSH (root login, password auth)
- Sets root password to `router`
- Copies and executes `/entrypoint-router.sh`

#### Client Image (Dockerfile.client)

**Base**: Ubuntu 22.04

**Installed Packages**:
- `openssh-server` & `openssh-client` - SSH connectivity
- `iputils-ping` - Network diagnostics
- `net-tools` - Network utilities
- `curl` - HTTP client
- `vim` - Text editor
- `sshpass` - Non-interactive SSH password authentication

**Configuration**:
- Configures SSH (root login, password auth)
- Sets root password to `client`
- Runs SSH daemon as main process

---

## ⚙️ Setup and Configuration

### Automated Setup (Recommended)

```bash
bash setup.sh
```

This script performs all setup steps automatically:

1. Cleans up any existing resources
2. Builds Docker images
3. Creates Docker networks
4. Starts router container
5. Connects router to all networks
6. Starts client containers
7. Configures static routes on clients
8. Displays configuration summary

### Manual Setup (Advanced)

If you need more control, here are the individual steps:

#### 1. Create Networks

```bash
docker network create --driver bridge network-one
docker network create --driver bridge network-two
docker network create --driver bridge bridge-net
```

#### 2. Start Router Container

```bash
docker run -d \
  --name router \
  --network bridge-net \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_ADMIN \
  --hostname router \
  network-router:latest
```

The router needs `NET_ADMIN` capability to:
- Load iptables rules
- Configure routing
- Enable IP forwarding

#### 3. Connect Router to All Networks

```bash
docker network connect network-one router
docker network connect network-two router
```

#### 4. Start Client Containers

```bash
docker run -d \
  --name client1 \
  --network network-one \
  --hostname client1 \
  --cap-add=NET_ADMIN \
  network-client:latest

docker run -d \
  --name client2 \
  --network network-two \
  --hostname client2 \
  --cap-add=NET_ADMIN \
  network-client:latest
```

#### 5. Configure Routes for Cross-Network Communication

```bash
# On client1: route to network-two through router
docker exec client1 route add -net 172.19.0.0 netmask 255.255.0.0 gw 172.18.0.2

# On client2: route to network-one through router
docker exec client2 route add -net 172.18.0.0 netmask 255.255.0.0 gw 172.19.0.2
```

### Router Configuration Details

#### IP Forwarding

The router enables IP forwarding to allow packets to pass between networks:

```bash
sysctl -w net.ipv4.ip_forward=1
```

This allows the router to act as a gateway between network-one and network-two.

#### iptables Rules

The router applies comprehensive iptables rules (see `entrypoint-router.sh`):

### Router iptables Rules in Detail

#### Configuration Commands Applied

```bash
# Clear all existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Set default policies (all ACCEPT initially)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# NAT Rule: Enable source NAT for outgoing traffic
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# FORWARD Rules: Connection tracking
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# FORWARD Rules: Cross-network routing
iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT

# FORWARD Rules: Internet access
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -j ACCEPT
```

#### Rule Explanation

| Rule | Type | Interface | Action | Purpose |
|------|------|-----------|--------|---------|
| `POSTROUTING -o eth0 -j MASQUERADE` | NAT | eth0 (bridge-net) | MASQUERADE | Source NAT for outgoing traffic; changes source IP to router's IP |
| `ESTABLISHED,RELATED` | FORWARD | all | ACCEPT | Allow return traffic for established connections |
| `-i eth1 -o eth2` | FORWARD | eth1→eth2 | ACCEPT | Allow network-one → network-two routing |
| `-i eth2 -o eth1` | FORWARD | eth2→eth1 | ACCEPT | Allow network-two → network-one routing |
| `-i eth1 -o eth0` | FORWARD | eth1→eth0 | ACCEPT | Allow network-one → bridge-net (external) |
| `-i eth2 -o eth0` | FORWARD | eth2→eth0 | ACCEPT | Allow network-two → bridge-net (external) |
| `-i eth0 -o eth1` | FORWARD | eth0→eth1 | ACCEPT | Allow bridge-net (external) → network-one |
| `-i eth0 -o eth2` | FORWARD | eth0→eth2 | ACCEPT | Allow bridge-net (external) → network-two |

#### Expected Router iptables Output

To view all rules on the router:

```bash
docker exec router iptables -L -v
```

**Expected Filter Table Output**:
```
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     all  --  any    any     anywhere             anywhere             ctstate RELATED,ESTABLISHED
   10   840 ACCEPT     all  --  eth1   eth2    anywhere             anywhere
    8   672 ACCEPT     all  --  eth2   eth1    anywhere             anywhere
    5   420 ACCEPT     all  --  eth1   eth0    anywhere             anywhere
    6   504 ACCEPT     all  --  eth2   eth0    anywhere             anywhere
    7   588 ACCEPT     all  --  eth0   eth1    anywhere             anywhere
    8   672 ACCEPT     all  --  eth0   eth2    anywhere             anywhere

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

**Column Meanings**:
- `pkts` - Number of packets matched by this rule
- `bytes` - Total bytes matched
- `target` - Action taken (ACCEPT, DROP, MASQUERADE, etc.)
- `prot` - Protocol (all, tcp, udp, icmp)
- `opt` - Options
- `in` - Input interface
- `out` - Output interface
- `source` - Source IP/network
- `destination` - Destination IP/network

To view NAT rules on the router:

```bash
docker exec router iptables -t nat -L -v
```

**Expected NAT Table Output**:
```
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  any    eth0    anywhere             anywhere
```

#### Detailed Rule Breakdown by Network Traffic Flow

**Traffic: client1 (network-one) → client2 (network-two)**
```
1. Packet from 172.18.0.3 to 172.19.0.3 arrives at eth1
2. Router matches: FORWARD -i eth1 -o eth2 → ACCEPT
3. Packet forwards to eth2 toward 172.19.0.3
4. Return traffic: 172.19.0.3 → 172.18.0.3 arrives at eth2
5. Router matches: FORWARD -i eth2 -o eth1 (or ESTABLISHED) → ACCEPT
6. Reply forwards back to client1
```

**Traffic: client1 (network-one) → External (via NAT)**
```
1. Packet from 172.18.0.3:12345 → external:80 arrives at eth1
2. Router matches: FORWARD -i eth1 -o eth0 → ACCEPT
3. NAT rule matches: POST-ROUTING -o eth0 → MASQUERADE
4. Source IP changed to 172.20.0.2
5. Packet sent out eth0: 172.20.0.2:54321 → external:80
6. Return traffic arrives: external:80 → 172.20.0.2:54321
7. Connection tracking restores original destination
8. Packet returned to 172.18.0.3:12345
```

### Client iptables Rules in Detail

Clients have minimal firewall configuration - mostly default ACCEPT policies:

#### Client Configuration

```bash
# Default chain policies (set during startup)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# No additional filtering rules
```

#### Expected Client iptables Output

To view rules on client1:

```bash
docker exec client1 iptables -L -v
```

**Expected Output**:
```
Chain INPUT (policy ACCEPT 25 packets, 2000 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 20 packets, 1500 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

**Explanation**:
- All chains have ACCEPT policy (default allow)
- No additional rules (chains are empty)
- Packets are counted in INPUT/OUTPUT showing traffic activity
- FORWARD is 0 because clients don't forward traffic

#### Client NAT Rules

To view NAT table on client1:

```bash
docker exec client1 iptables -t nat -L -v
```

**Expected Output**:
```
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

**Explanation**:
- No NAT rules needed on clients
- All chains empty with ACCEPT policy
- Clients don't perform NAT - they just send and receive packets
- The router handles NAT for them

### Viewing Complete Rule Sets

#### Router Complete Rules

```bash
# View all rules with line numbers
docker exec router iptables -L -n -v --line-numbers

# View with more details
docker exec router iptables -L -n -v -e
```

#### Detailed Diagnostics

```bash
# View only FORWARD chain
docker exec router iptables -L FORWARD -v -n

# View specific interface rules
docker exec router iptables -L -i eth1 -v -n

# View rules matching a pattern
docker exec router iptables -L -v -n | grep "eth1"

# View rules in tcpdump format (for debugging)
docker exec router iptables -L -n -v -x

# Monitor iptables counters in realtime
docker exec router watch 'iptables -L -v -n'
```

#### Comparison Table: Router vs Client Rules

| Aspect | Router | Client1 | Client2 |
|--------|--------|---------|---------|
| INPUT policy | ACCEPT | ACCEPT | ACCEPT |
| FORWARD policy | ACCEPT | ACCEPT | ACCEPT |
| OUTPUT policy | ACCEPT | ACCEPT | ACCEPT |
| Filter rules | 8 custom | 0 (default) | 0 (default) |
| NAT rules | 1 (MASQUERADE) | 0 | 0 |
| Can route packets | Yes (eth1↔eth2) | No | No |
| Can NAT traffic | Yes (eth0) | No | No |
| SSH capable | Yes (port 22) | Yes (port 22) | Yes (port 22) |
| Forwarding enabled | Yes | No | No |

### Monitoring Traffic with iptables Counters

The packet and byte counters in iptables output show real-time activity:

```bash
# Run ping from client1 to client2
docker exec client1 ping -c 5 172.19.0.3 &

# Monitor iptables counters
docker exec router iptables -L FORWARD -v -n --continuous

# Results after ping completes:
# - eth1→eth2 rule shows 5 packets (ICMP requests)
# - eth2→eth1 rule shows 5 packets (ICMP replies)
```

### Modifying iptables Rules (Advanced)

If you need to adjust rules:

```bash
# Drop all rules and set DENY policies
docker exec router iptables -P FORWARD DROP

# Add rule to allow only SSH traffic
docker exec router iptables -A FORWARD -p tcp --dport 22 -j ACCEPT

# Insert rule at specific position (position 1)
docker exec router iptables -I FORWARD 1 -i eth1 -o eth2 -j ACCEPT

# Delete rule by number
docker exec router iptables -D FORWARD 5

# Save rules (inside container)
docker exec router iptables-save > router_rules.txt
```

---

## 🧪 Testing

### Automated Test Suite

The `test.sh` script provides a comprehensive test utility with multiple testing options.

#### Running Full Test Suite

```bash
bash test.sh test
```

This runs all checks:
1. Container status verification
2. Ping connectivity tests
3. SSH connectivity tests
4. Network configuration display

#### Expected Output

```
╔════════════════════════════════════════╗
║  Container Status Check
╚════════════════════════════════════════╝
[✓] router is running
[✓] client1 is running
[✓] client2 is running

╔════════════════════════════════════════╗
║  Ping Connectivity Tests
╚════════════════════════════════════════╝
[TEST] client1 → router (172.18.0.2)
[✓] Ping successful
[TEST] client2 → router (172.19.0.2)
[✓] Ping successful
[TEST] client1 → client2 (172.19.0.3) [through router]
[✓] Ping successful
[TEST] client2 → client1 (172.18.0.3) [through router]
[✓] Ping successful

╔════════════════════════════════════════╗
║  SSH Connectivity Tests
╚════════════════════════════════════════╝
[TEST] client1 → client2 SSH (172.19.0.3)
[✓] SSH connection successful
[TEST] client2 → client1 SSH (172.18.0.3)
[✓] SSH connection successful

╔════════════════════════════════════════╗
║  Network Configuration
╚════════════════════════════════════════╝
[Router and Client Configuration Details...]
```

#### Individual Test Commands

```bash
# Check container status
bash test.sh check

# Test ping connectivity
bash test.sh ping

# Test SSH connectivity
bash test.sh ssh

# Show network configuration
bash test.sh config

# Show iptables rules
bash test.sh iptables

# Interactive mode
bash test.sh
```

### Ping Connectivity Tests

These tests verify basic network connectivity:

| Test | Command | Expected Result |
|------|---------|-----------------|
| Client1 → Router | `docker exec client1 ping -c 1 172.18.0.2` | Should succeed |
| Client2 → Router | `docker exec client2 ping -c 1 172.19.0.2` | Should succeed |
| Client1 → Client2 (cross-network) | `docker exec client1 ping -c 1 172.19.0.3` | Should succeed |
| Client2 → Client1 (cross-network) | `docker exec client2 ping -c 1 172.18.0.3` | Should succeed |

**What's being tested**: Network layer (Layer 3) connectivity

### SSH Connectivity Tests

These tests verify application-layer connectivity:

| Test | Command | Expected Result |
|------|---------|-----------------|
| Client1 → Client2 SSH | `docker exec client1 sshpass -p "client" ssh root@172.19.0.3` | Should connect successfully |
| Client2 → Client1 SSH | `docker exec client2 sshpass -p "client" ssh root@172.18.0.3` | Should connect successfully |

**What's being tested**: SSH service availability, routing, NAT

### Network Configuration Tests

These tests display network state:

- Router network interfaces (eth0, eth1, eth2)
- Router routing table
- Client network configuration
- IP address assignments

---

## 🔍 Manual Testing

### Interactive Test Mode

```bash
bash test.sh
```

This presents an interactive menu:

```
Docker Network Simulation - Testing Utility
==========================================
1. Check container status
2. Test ping connectivity
3. Test SSH connectivity
4. Show network configuration
5. Show iptables rules
6. Run all tests
7. Shell access to router
8. Shell access to client1
9. Shell access to client2
0. Exit
```

### Direct Container Access

#### Access Router Shell

```bash
docker exec -it router /bin/bash
```

Once in the router:

```bash
# View network interfaces
ifconfig

# View routing table
route -n

# View iptables rules
iptables -L -v

# View NAT rules
iptables -t nat -L -v

# Test routing
ping 172.18.0.3  # ping client1
ping 172.19.0.3  # ping client2

# Monitor traffic
tcpdump -i eth1  # Monitor network-one traffic
```

#### Access Client1 Shell

```bash
docker exec -it client1 /bin/bash
```

Once in client1:

```bash
# View network config
ifconfig
route -n

# Test connectivity
ping 172.18.0.2          # ping router on network-one
ping 172.19.0.3          # ping client2 on network-two
ping 172.19.0.2          # ping router on network-two

# SSH to client2
sshpass -p "client" ssh root@172.19.0.3

# SSH with interactive password
ssh root@172.19.0.3
# Enter password: client
```

#### Access Client2 Shell

```bash
docker exec -it client2 /bin/bash
```

Same commands as client1, but reversed networks.

### Network Diagnostics

#### View Container Network Configuration

```bash
# Detailed network info
docker inspect router --format='{{json .NetworkSettings.Networks}}' | python3 -m json.tool

# Quick IP lookup
docker inspect -f '{{(index .NetworkSettings.Networks "network-one").IPAddress}}' router
```

#### View Docker Network Status

```bash
# List all networks
docker network ls

# Detailed network info
docker network inspect network-one

# Connected containers
docker network inspect network-one --format='{{json .Containers}}' | python3 -m json.tool
```

#### Monitor Network Traffic

```bash
# Capture packets on router's network-one interface
docker exec router tcpdump -i eth1

# Capture with specific protocol
docker exec router tcpdump -i eth1 icmp  # ICMP/ping traffic
docker exec router tcpdump -i eth1 tcp port 22  # SSH traffic
```

### Advanced Testing

#### Test NAT Functionality

```bash
# From client1, check source IP seen by router
docker exec client1 bash -c 'while true; do nc -zv 172.20.0.1 80; sleep 1; done'

# On router, capture outgoing traffic
docker exec router tcpdump -i eth0 -nn
```

#### Test Route Persistence

```bash
# Check routes on client1
docker exec client1 route -n

# Verify route to network-two
docker exec client1 route -n | grep 172.19.0.0
```

#### Test SSH Across Networks

```bash
# From client1, SSH to client2 with verbose output
docker exec client1 sshpass -p "client" ssh -vvv root@172.19.0.3 "hostname"

# With command execution
docker exec client1 sshpass -p "client" ssh root@172.19.0.3 "ifconfig eth0"
```

---

## 🔧 Troubleshooting

### Container Won't Start

```bash
# Check container logs
docker logs router
docker logs client1

# Check if port is already in use
docker ps -a

# Remove stuck containers
docker rm -f router client1 client2

# Restart with setup.sh reset
bash setup.sh reset
```

### Ping Fails Between Networks

**Symptoms**: `ping 172.19.0.3` from client1 fails

**Possible Causes**:

1. **Routes not configured**
   ```bash
   # Check routes on client1
   docker exec client1 route -n
   
   # Reconfigure routes (from host)
   bash setup.sh reset
   ```

2. **Router not forwarding**
   ```bash
   # Check IP forwarding on router
   docker exec router cat /proc/sys/net/ipv4/ip_forward
   # Should output: 1
   
   # Check iptables rules
   docker exec router iptables -L -v
   # Should show FORWARD chains accepting traffic
   ```

3. **Network not connected to router**
   ```bash
   # Check connected networks
   docker inspect router --format='{{json .NetworkSettings.Networks}}'
   
   # Reconnect if needed
   docker network connect network-one router
   docker network connect network-two router
   ```

### SSH Connection Fails

**Symptoms**: `sshpass -p "client" ssh root@172.19.0.3` fails

**Possible Causes**:

1. **sshpass not installed in client image**
   ```bash
   # Verify sshpass is in image
   docker exec client1 which sshpass
   
   # Add to Dockerfile.client and rebuild
   # Already included in current version
   ```

2. **SSH daemon not running**
   ```bash
   # Check SSH daemon
   docker exec client1 ps aux | grep sshd
   
   # Restart SSH
   docker exec client1 service ssh restart
   ```

3. **Wrong password**
   - Router password: `router`
   - Client password: `client`
   ```bash
   # Verify credentials
   sshpass -p "client" ssh root@172.18.0.3 "echo success"
   ```

4. **Hostname resolution issues**
   ```bash
   # Use IP address directly
   sshpass -p "client" ssh -o StrictHostKeyChecking=no root@172.19.0.3
   ```

### Network Configuration Not Showing

**Symptoms**: Clients show no IP, or `ifconfig` doesn't work

**Possible Causes**:

1. **ifconfig not installed**
   ```bash
   # Check available tools
   docker exec client1 which ifconfig
   
   # Alternative: use ip command if available
   docker exec client1 hostname -I
   ```

2. **Container crashed during setup**
   ```bash
   # Check container status
   docker ps -a
   
   # Restart container
   docker start client1
   ```

### Performance Issues

**Symptoms**: Slow connectivity, high CPU usage

**Solutions**:

1. **Check host resources**
   ```bash
   # Monitor Docker resource usage
   docker stats
   ```

2. **Reduce network traffic**
   ```bash
   # Stop background processes
   docker exec router killall tcpdump
   ```

3. **Restart containers**
   ```bash
   bash setup.sh reset
   ```

### Port Already in Use

**Error**: `Error response from daemon: Bind for 0.0.0.0:22 failed`

**Solution**:

```bash
# Stop conflicting container
docker stop container_name

# Or use a different port
docker run -d -p 2222:22 network-client:latest
```

---

## 📚 Project Files Reference

### setup.sh

**Purpose**: Automated deployment and network configuration

**Key Functions**:

- `cleanup()` - Removes existing containers and networks
- `build_images()` - Builds Docker images from Dockerfiles
- `create_networks()` - Creates three Docker networks
- `start_router()` - Starts router container with capabilities
- `start_clients()` - Starts two client containers
- `configure_routes()` - Sets up static routes for cross-network communication
- `show_info()` - Displays configuration summary

**Usage**:

```bash
bash setup.sh              # Full setup
bash setup.sh clean        # Remove all resources
bash setup.sh reset        # Clean and rebuild
```

### test.sh

**Purpose**: Comprehensive testing and diagnostics

**Key Functions**:

- `get_ips()` - Retrieves container IP addresses from Docker networks
- `check_containers()` - Verifies all containers are running
- `test_ping()` - Tests ICMP connectivity between containers
- `test_ssh()` - Tests SSH connectivity and authentication
- `show_network_config()` - Displays network configuration
- `show_iptables()` - Shows firewall rules
- `run_all_tests()` - Executes complete test suite

**Usage**:

```bash
bash test.sh test          # Run all tests
bash test.sh check         # Container status
bash test.sh ping          # Ping tests
bash test.sh ssh           # SSH tests
bash test.sh config        # Network config
bash test.sh iptables      # Firewall rules
bash test.sh [container]   # Shell access
```

### Dockerfile.router

**Purpose**: Router container image

**Key Components**:

- Base image: Ubuntu 22.04
- Installed packages: iproute2, iptables, openssh, net-tools, etc.
- Root password: `router`
- Entrypoint: `/entrypoint-router.sh`

### Dockerfile.client

**Purpose**: Client container image

**Key Components**:

- Base image: Ubuntu 22.04
- Installed packages: openssh, iputils, net-tools, sshpass, etc.
- Root password: `client`
- Main process: SSH daemon

### entrypoint-router.sh

**Purpose**: Router initialization script

**Key Tasks**:

1. Enables IP forwarding
2. Clears existing iptables rules
3. Sets default policies (ACCEPT)
4. Configures NAT masquerade
5. Sets up forwarding rules
6. Starts SSH daemon

---

## 📝 Common Workflows

### Workflow 1: Complete Fresh Setup and Test

```bash
# 1. Navigate to project
cd /path/to/containerised-router

# 2. Full setup (includes cleanup)
bash setup.sh reset

# 3. Run comprehensive tests
bash test.sh test

# 4. Check results
# All tests should show [✓] for successful items
```

### Workflow 2: Quick Connectivity Check

```bash
# Direct ping test
docker exec client1 ping -c 3 172.19.0.3

# Direct SSH test
docker exec client1 sshpass -p "client" ssh root@172.19.0.3 "echo Connected!"
```

### Workflow 3: Debug Network Issues

```bash
# 1. Check container status
bash test.sh check

# 2. View routing on client
docker exec client1 route -n

# 3. View routing on router
docker exec router route -n

# 4. Check iptables on router
docker exec router iptables -L -v

# 5. Ping test with verbose output
docker exec client1 ping -v 172.19.0.3

# 6. Access shell for deeper investigation
docker exec -it client1 /bin/bash
```

### Workflow 4: Custom Testing

```bash
# Access router shell
docker exec -it router /bin/bash

# Inside router:
ping 172.18.0.3        # Verify client1 connectivity
ping 172.19.0.3        # Verify client2 connectivity
iptables -L -v         # View firewall rules
netstat -tlnp          # View listening ports

# Exit and test reverse direction
exit

# Access client1 shell
docker exec -it client1 /bin/bash

# Inside client1:
route -n               # View routing table
ssh -v root@172.19.0.3 # Verbose SSH test
tcpdump -i eth0        # Monitor traffic
```

---

## 🎓 Learning Resources

### Key Concepts

1. **Docker Networking**
   - Bridge networks: Isolated networks for container communication
   - Network drivers: How containers connect
   - Container networking model: How IP addresses are assigned

2. **IP Routing**
   - Static routes: Manually configured routing paths
   - Route tables: How packets are forwarded
   - Gateways: Default routing points

3. **Network Address Translation (NAT)**
   - MASQUERADE: Source NAT for outgoing traffic
   - Port forwarding: Mapping external ports to internal services
   - Connection tracking: Maintaining state for bidirectional communication

4. **iptables**
   - Table types: filter, nat, mangle, raw
   - Chains: INPUT, OUTPUT, FORWARD, PREROUTING, POSTROUTING
   - Rules: How packets are processed

5. **SSH**
   - Public key authentication
   - Password authentication
   - SSH configuration files

### Exercises

1. **Modify NAT Rules**
   - Block outgoing traffic from one network
   - Implement port forwarding
   - Create reverse NAT rules

2. **Change Network Subnets**
   - Use different CIDR ranges
   - Test with overlapping subnets
   - Understand routing precedence

3. **Add Firewall Rules**
   - Allow only specific ports
   - Implement stateful filtering
   - Create logging rules

4. **Add a Third Network**
   - Create network-three
   - Connect router
   - Configure additional routes

---

## 📞 Support and Feedback

### Common Questions

**Q: Can I modify the network subnets?**
A: Yes, edit the network creation commands in setup.sh to use different CIDR ranges.

**Q: How do I add more clients?**
A: Duplicate the client container creation in setup.sh and configure appropriate routes.

**Q: Can I use this with docker-compose?**
A: Yes, you can create a docker-compose.yml file based on the setup.sh commands.

**Q: How do I monitor realtime traffic?**
A: Use `docker exec router tcpdump -i eth1` to monitor specific network interfaces.

**Q: Can I run this on Windows/macOS?**
A: Yes, using Docker Desktop with enabled virtualization.

---

## 📄 Version Information

- **Docker**: 20.10+ required
- **Ubuntu Images**: 22.04
- **OpenSSH**: 8.9p1
- **Last Updated**: February 21, 2026

---

## 📝 Changelog

### Version 1.0 (Current)
- Initial release
- Full router and client implementation
- Comprehensive test suite
- Complete documentation
- Fixed Docker inspect template syntax
- Added sshpass for SSH testing

---

## Summary Quick Reference

| Task | Command |
|------|---------|
| Full Setup | `bash setup.sh` |
| Reset Everything | `bash setup.sh reset` |
| Cleanup | `bash setup.sh clean` |
| Run All Tests | `bash test.sh test` |
| Check Status | `bash test.sh check` |
| Test Ping | `bash test.sh ping` |
| Test SSH | `bash test.sh ssh` |
| Router Shell | `docker exec -it router /bin/bash` |
| Client1 Shell | `docker exec -it client1 /bin/bash` |
| Client2 Shell | `docker exec -it client2 /bin/bash` |
| View Container Logs | `docker logs router` |
| List Containers | `docker ps` |
| List Networks | `docker network ls` |

---

This documentation provides comprehensive guidance for understanding, building, deploying, testing, and troubleshooting the containerized router network simulation.
