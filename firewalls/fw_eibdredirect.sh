#!/bin/sh

echo "0" > /proc/sys/net/ipv4/ip_forward
echo "1" > /proc/sys/net/ipv4/conf/all/rp_filter

iptables -F -t nat
iptables -X -t nat

iptables -F FORWARD
iptables -P FORWARD ACCEPT

iptables -A PREROUTING -p udp -i eth0 --dport 3000 \
-j DNAT --to-destination 192.168.0.180:3671 -t nat

iptables -A PREROUTING -p tcp -i eth0 --dport 3001 \
-j DNAT --to-destination 192.168.0.183:1935 -t nat

echo "1" > /proc/sys/net/ipv4/ip_forward
