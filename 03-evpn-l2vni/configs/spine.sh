#!/bin/bash
# spine: underlay and EVPN transit. Runs once at deploy.
set -e

# Wait for the last front panel port, then for the switch to settle.
until ip link show Ethernet4 >/dev/null 2>&1; do sleep 1; done
sleep 5

config loopback add Loopback0
config interface ip add Loopback0 10.1.1.100/32
config interface ip add Ethernet0 10.0.1.0/31
config interface startup Ethernet0
config interface ip add Ethernet4 10.0.2.0/31
config interface startup Ethernet4

# docker-sonic-vs ships with bgpd stopped.
supervisorctl start bgpd

vtysh <<EOF
configure terminal
router bgp 65000
 bgp router-id 10.1.1.100
 no bgp ebgp-requires-policy
 neighbor 10.0.1.1 remote-as 65001
 neighbor 10.0.2.1 remote-as 65002
 address-family ipv4 unicast
  network 10.1.1.100/32
 exit-address-family
 address-family l2vpn evpn
  neighbor 10.0.1.1 activate
  neighbor 10.0.2.1 activate
 exit-address-family
end
EOF
