#!/bin/bash

# # Flush existing rules
# iptables -F
# iptables -X
# iptables -t nat -F
# iptables -t nat -X
# iptables -t mangle -F
# iptables -t mangle -X

# # Allow all traffic on loopback interface
# iptables -A INPUT -i lo -j ACCEPT
# iptables -A OUTPUT -o lo -j ACCEPT

# # Allow established and related incoming connections
# iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# # Allow established outgoing connections
# iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT

# # Allow Docker Swarm management communication (port 2377)
# iptables -A INPUT -p tcp --dport 2377 -j ACCEPT

# # Allow communication between nodes (port 7946 TCP/UDP)
# iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
# iptables -A INPUT -p udp --dport 7946 -j ACCEPT

# # Allow overlay network traffic (port 4789 UDP)
# iptables -A INPUT -p udp --dport 4789 -j ACCEPT

# # Allow HTTP/HTTPS traffic
# iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# # Allow traffic on Docker bridge network
# iptables -A INPUT -i docker0 -j ACCEPT
# iptables -A INPUT -o docker0 -j ACCEPT

# # Allow outgoing traffic
# iptables -P OUTPUT ACCEPT

# # Save the rules
# iptables-save | tee /etc/iptables/rules.v4

# # Ensure iptables rules are applied on reboot
# apt-get install -y iptables-persistent
# netfilter-persistent save
# netfilter-persistent reload

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
netfilter-persistent save