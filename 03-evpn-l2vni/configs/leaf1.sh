#!/bin/bash
# leaf1: underlay, VLAN 100 mapped to VNI 10100, EVPN. Runs once at deploy.
set -e

# Wait for the last front panel port, then for the switch to settle.
until ip link show Ethernet4 >/dev/null 2>&1; do sleep 1; done
sleep 5

config loopback add Loopback0
config interface ip add Loopback0 10.1.1.1/32
config interface ip add Ethernet0 10.0.1.1/31
config interface startup Ethernet0

# The host port is an untagged member of VLAN 100.
config vlan add 100
config vlan member add -u 100 Ethernet4
config interface startup Ethernet4

# One VTEP sourced from the loopback, one EVPN NVO, one VLAN to VNI map.
config vxlan add vtep1 10.1.1.1
config vxlan evpn_nvo add nvo1 vtep1
config vxlan map add vtep1 100 10100

# docker-sonic-vs ships with bgpd stopped.
supervisorctl start bgpd

vtysh <<EOF
configure terminal
router bgp 65001
 bgp router-id 10.1.1.1
 no bgp ebgp-requires-policy
 neighbor 10.0.1.0 remote-as 65000
 address-family ipv4 unicast
  network 10.1.1.1/32
 exit-address-family
 address-family l2vpn evpn
  neighbor 10.0.1.0 activate
  advertise-all-vni
 exit-address-family
end
EOF
