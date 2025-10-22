# High-Availability Kubernetes Cluster Setup (5 Nodes)

This guide sets up a production-ready Kubernetes cluster with 3 master nodes and 2 worker nodes for high availability using VMware Workstation.

**Cluster Architecture:**
- 3 Master Nodes (HA - tolerates 1 node loss)
- 2 Worker Nodes
- Subnet: `192.168.43.0/24`
- Gateway: `192.168.43.1`

---

## Node Configuration

| Node | Type | IP Address | Hostname |
|------|------|-----------|----------|
| master-01 | Master | 192.168.43.10 | master-01 |
| master-02 | Master | 192.168.43.11 | master-02 |
| master-03 | Master | 192.168.43.12 | master-03 |
| worker-01 | Worker | 192.168.43.20 | worker-01 |
| worker-02 | Worker | 192.168.43.21 | worker-02 |

---

## Prerequisites

- VMware Workstation Pro/Player
- Ubuntu 20.04 template VM
- Git installed locally
- VSCode (recommended for configuration file editing)

---

## Step 1: Prepare VMware VMs

### Create VMs from Template

1. Copy the Ubuntu 20.04 template folder 5 times from:
   ```
   C:\Users\user_name\Documents\Virtual Machines\ubuntu-20.04-template\
   ```

2. For each copy:
   - Rename folder: `master-01`, `master-02`, `master-03`, `worker-01`, `worker-02`
   - Open the `.vmx` file in each folder
   - Update the VM name and displayName in the `.vmx` file to match the folder name

3. Add each VM to VMware Workstation and configure network to **Bridged**

---

## Step 2: Configure Network (Netplan)

Configure static IP for each node. Repeat for all 5 VMs with respective IPs.

### Example: master-01

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Add the following configuration (adjust IP for each node):

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 192.168.43.10/24
      gateway4: 192.168.43.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

Apply configuration:

```bash
sudo netplan apply
sleep 2
ping -c 2 8.8.8.8
```

Set hostname:

```bash
sudo hostnamectl set-hostname master-01
```

**Repeat for all nodes** with their respective IPs and hostnames:
- master-02: `192.168.43.11`
- master-03: `192.168.43.12`
- worker-01: `192.168.43.20`
- worker-02: `192.168.43.21`

---

## Step 3: Install Git & Clone Repository

On all 5 nodes, run:

```bash
sudo apt update
sudo apt install -y git

mkdir mirasys-assignment
cd mirasys-assignment/
git clone https://github.com/Bluerate90/ServiceExample-DevOps
cd ServiceExample-DevOps/scripts/

chmod +x *.sh
```

---

## Step 4: Configure config.sh

Edit `config.sh` to match your environment:

```bash
nano config.sh
```

Update the following variables with your subnet:

```bash
SUBNET="192.168.43.0/24"
GATEWAY="192.168.43.1"
MASTER_IPS=("192.168.43.10" "192.168.43.11" "192.168.43.12")
WORKER_IPS=("192.168.43.20" "192.168.43.21")
```

---

## Step 5: Prepare All Nodes

Run on **all 5 nodes** (master and worker):

```bash
sudo ./01-prepare-nodes.sh
```

This script:
- Installs container runtime (Docker/containerd)
- Installs kubeadm, kubelet, kubectl
- Configures kernel parameters
- Disables swap

---

## Step 6: Initialize Master-01

On **master-01 only**, run:

```bash
sudo ./02-init-master-1.sh
```

This script initializes the first master node and generates the certificate key for HA cluster setup.

**Important:** Save the output containing:
- Certificate key
- Join commands for other masters and workers

Example output:
```
[upload-certs] Using certificate key:
3a009f737ce97301981ec0888580a8968362dfe3d9ced5d2bf6751f1dffb2628
```

---

## Step 7: Join Additional Masters

On **master-02 and master-03**, run:

```bash
sudo ./03-join-masters.sh
```

You'll be prompted for the certificate key from Step 6.

---

## Step 8: Join Worker Nodes

On **worker-01 and worker-02**, run:

```bash
sudo ./04-join-workers.sh
```

You'll be prompted for the worker join token from Step 6.

---

## Step 9: Verify Cluster

On master-01, verify all nodes joined successfully:

```bash
kubectl get nodes
```

Expected output:
```
NAME       STATUS   ROLES           AGE   VERSION
master-01  Ready    control-plane   5m    v1.28.x
master-02  Ready    control-plane   3m    v1.28.x
master-03  Ready    control-plane   2m    v1.28.x
worker-01  Ready    <none>          1m    v1.28.x
worker-02  Ready    <none>          1m    v1.28.x
```

---

## Step 10: Install Add-ons

On master-01:

```bash
# Storage (Longhorn)
sudo ./05-install-longhorn.sh

# Observability (Prometheus, Grafana)
sudo ./06-install-observability.sh

# GitOps (Flux)
sudo ./07-install-flux.sh

# Sealed Secrets
sudo ./08-setup-sealed-secrets.sh
```

---

## Verification

Run the verification script on master-01:

```bash
sudo ./verify-deployment.sh
```

---

## Troubleshooting

**Network not working:**
- Verify bridged network in VMware settings
- Check netplan config with: `ip addr show`
- Test connectivity: `ping 8.8.8.8`

**Node not joining cluster:**
- Verify hostname is set correctly: `hostnamectl`
- Check kubelet logs: `sudo journalctl -u kubelet -n 50`
- Ensure all nodes can reach each other: `ping <other-node-ip>`

**High Availability Check:**
Stop master-01 and verify cluster still works on master-02/master-03. Cluster should remain operational.

---

## Future Improvements

- Implement vSphere integration for automated VM provisioning
- Use Infrastructure-as-Code (Terraform) for configuration
- Automated backup and disaster recovery

---

## Notes

- All scripts are idempotent and safe to re-run
- Keep certificate key secure
- Document any customizations made to scripts
- Monitor cluster health regularly with `kubectl get nodes` and `kubectl get pods --all-namespaces`
