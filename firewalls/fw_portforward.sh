#!/bin/sh

echo "0" > /proc/sys/net/ipv4/ip_forward
echo "1" > /proc/sys/net/ipv4/conf/all/rp_filter

iptables -F -t nat
iptables -X -t nat

iptables -F FORWARD
iptables -P FORWARD ACCEPT

iptables -A PREROUTING -p tcp -i eth0 --dport 90 \
-j DNAT --to-destination 192.168.0.10 -t nat
iptables -A PREROUTING -p udp -i eth0 --dport 90 \
-j DNAT --to-destination 192.168.0.10 -t nat

iptables -A PREROUTING -p tcp -i eth0 --dport 1600 \
-j DNAT --to-destination 192.168.0.10 -t nat
iptables -A PREROUTING -p udp -i eth0 --dport 1600 \
-j DNAT --to-destination 192.168.0.10 -t nat

iptables -A PREROUTING -p tcp -i eth0 --dport 37260 \
-j DNAT --to-destination 192.168.0.10 -t nat
iptables -A PREROUTING -p udp -i eth0 --dport 37260 \
-j DNAT --to-destination 192.168.0.10 -t nat

#iptables -A PREROUTING -p icmp -i eth0 -j DNAT --to-destination 192.168.0.10 \
#-t nat

#iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

#iptables -A FORWARD -p TCP -i eth0 -o eth0 \
#--dport 90 -d 192.168.0.10 -m state --state NEW -j ACCEPT
#iptables -A FORWARD -p udp -i eth0 -o eth0 \
#--dport 90 -d 192.168.0.10 -m state --state NEW -j ACCEPT

echo "1" > /proc/sys/net/ipv4/ip_forward
