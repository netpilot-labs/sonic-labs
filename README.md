# SONiC labs for containerlab

Three containerlab labs for the SONiC network operating system. Each one runs on the community `docker-sonic-vs` image with the `sonic-vs` kind.

| Lab | What it builds | Tutorial |
|---|---|---|
| [01-two-switches](01-two-switches) | Two SONiC switches on one link, configured by hand | [Run SONiC in containerlab](https://www.netpilot.io/blog/sonic-containerlab) |
| [02-bgp-leaf-spine](02-bgp-leaf-spine) | Two spines, two leaves and two Linux hosts with eBGP and ECMP, configured at deploy | [SONiC FRR: configure BGP on a SONiC switch](https://www.netpilot.io/blog/sonic-frr-bgp) |
| [03-evpn-l2vni](03-evpn-l2vni) | One spine, two leaves and two hosts with VLAN 100 stretched over VNI 10100, configured at deploy | [Learn VXLAN EVPN on SONiC](https://www.netpilot.io/solutions/learn-vxlan-evpn-sonic) |

## Requirements

- containerlab, tested on v0.77.0 and v0.82.0
- A Linux host with Docker. No KVM needed, `sonic-vs` is a plain container.
- About 150 MB of memory per SONiC node at idle

## Get the image

The SONiC project publishes `docker-sonic-vs` as a build artifact, not on a registry. This downloads the latest 202511 branch build and loads it as `docker-sonic-vs:latest`:

```bash
curl -L -o docker-sonic-vs.gz "https://sonic-build.azurewebsites.net/api/sonic/artifacts?branchName=202511&platform=vs&target=target/docker-sonic-vs.gz"
docker load -i docker-sonic-vs.gz
```

## Run a lab

```bash
git clone https://github.com/netpilot-labs/sonic-labs
cd sonic-labs/02-bgp-leaf-spine
sudo containerlab deploy -t bgp-leaf-spine.clab.yml
```

Deploy returns in about 20 seconds, while the switches are still starting. Labs 02 and 03 configure themselves and were ready about 60 seconds after the deploy began. Each switch is a container with a root shell:

```bash
docker exec -it clab-sonic-bgp-leaf1 bash
vtysh -c 'show bgp summary'
```

Remove the lab when you are done:

```bash
sudo containerlab destroy -t bgp-leaf-spine.clab.yml --cleanup
```

## What to know about this image

- `sudo` is not in the image. You are already root, so run `config` and `show` directly. A `show` command that shells out to `sudo` prints `sudo: not found`, and `show ip interfaces` fails. Use `ip -br addr` for the same answer.
- `show version` fails with `KeyError: 'debian_version'`. Read `/etc/sonic/sonic_version.yml`.
- `bgpd` is stopped at boot. `supervisorctl start bgpd` starts it.
- BGP state is read through `vtysh`. `show ip bgp summary` answers `No such command 'bgp'`.
- Do not use `docker restart` on a node. It loses the node's links and its services do not come back. Destroy and deploy again, which is why labs 02 and 03 keep their config in `configs/`.

## Tested with

`docker-sonic-vs` from the 202511 branch (build 1262664, FRR 10.4.1) on containerlab v0.77.0 and v0.82.0, Ubuntu 24.04.

## Links

- [sonic-vs kind documentation](https://containerlab.dev/manual/kinds/sonic-vs/)
- [SONiC NOS lab on NetPilot](https://www.netpilot.io/sonic-nos-lab), where an AI agent builds the same kind of lab from a prompt in the browser

Maintained by the NetPilot team. AI for network engineers. Not affiliated with or endorsed by the SONiC project, the SONiC Foundation or the containerlab project.
