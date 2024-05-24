#!/bin/bash

# Autoriser tout le trafic entrant
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

netfilter-persistent save
echo "Les règles iptables ont été configurées avec succès."
