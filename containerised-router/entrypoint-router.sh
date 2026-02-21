#!/bin/bash

# Enable IP forwarding at runtime
sysctl -w net.ipv4.ip_forward=1

# Clear existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Set default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Enable NAT for outgoing traffic from both networks
# This allows containers on network-one and network-two to reach the internet
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Allow forwarding between network-one and network-two through the router
# Allow established/related connections
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow forwarding from network-one (eth1) to network-two (eth2)
iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT

# Allow forwarding from network-two (eth2) to network-one (eth1)
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT

# Allow forwarding to internet (eth0)
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -j ACCEPT

echo "Router iptables rules configured successfully"
iptables -L -v
iptables -t nat -L -v

# Start SSH server
/usr/sbin/sshd -D
