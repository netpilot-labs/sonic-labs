#!/bin/bash
# leaf2: interfaces in CONFIG_DB, BGP in FRR. Runs once at deploy.
set -e

# Wait for the last front panel port, then for the switch to settle.
until ip link show Ethernet8 >/dev/null 2>&1; do sleep 1; done
sleep 5

config loopback add Loopback0
config interface ip add Loopback0 10.255.0.12/32
config interface ip add Ethernet0 10.0.2.1/31
config interface startup Ethernet0
config interface ip add Ethernet4 10.0.4.1/31
config interface startup Ethernet4
config interface ip add Ethernet8 192.168.2.1/24
config interface startup Ethernet8

# docker-sonic-vs ships with bgpd stopped.
supervisorctl start bgpd

vtysh <<EOF
configure terminal
router bgp 65002
 bgp router-id 10.255.0.12
 no bgp ebgp-requires-policy
 neighbor 10.0.2.0 remote-as 65000
 neighbor 10.0.4.0 remote-as 65000
 address-family ipv4 unicast
  network 10.255.0.12/32
  network 192.168.2.0/24
 exit-address-family
end
EOF
