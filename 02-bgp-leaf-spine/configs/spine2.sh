#!/bin/bash
# spine2: interfaces in CONFIG_DB, BGP in FRR. Runs once at deploy.
set -e

# Wait for the last front panel port, then for the switch to settle.
until ip link show Ethernet4 >/dev/null 2>&1; do sleep 1; done
sleep 5

config loopback add Loopback0
config interface ip add Loopback0 10.255.0.2/32
config interface ip add Ethernet0 10.0.3.0/31
config interface startup Ethernet0
config interface ip add Ethernet4 10.0.4.0/31
config interface startup Ethernet4

# docker-sonic-vs ships with bgpd stopped.
supervisorctl start bgpd

vtysh <<EOF
configure terminal
router bgp 65000
 bgp router-id 10.255.0.2
 no bgp ebgp-requires-policy
 neighbor 10.0.3.1 remote-as 65001
 neighbor 10.0.4.1 remote-as 65002
 address-family ipv4 unicast
  network 10.255.0.2/32
 exit-address-family
end
EOF
