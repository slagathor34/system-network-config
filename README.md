# 802.1ad Bond Configuration with Ansible

This Ansible playbook configures and manages your system's 802.1ad bond on 10Gb NICs with full rollback capabilities.

## Current System Configuration

- **Bond Interface**: bond0
- **10Gb NICs**: enp9s0f0, enp9s0f1 (Intel 82599ES)
- **Bond Mode**: 802.3ad (LACP)
- **VLANs**: 200, 500, 700
- **Special Configuration**: VLAN 500 is bridged to bridgeLab

## Files

- `configure-802.1ad-bond.yml` - Main configuration playbook
- `validate-bond-config.yml` - Validation playbook
- `rollback_script.j2` - Rollback script template
- `inventory.ini` - Ansible inventory
- `README.md` - This file

## Usage

### 1. Apply Configuration (Idempotent)

```bash
ansible-playbook -i inventory.ini configure-802.1ad-bond.yml
```

This playbook is idempotent and will:
- Backup current configuration
- Configure bond0 with 802.3ad mode
- Set up VLAN interfaces (200, 500, 700)
- Create rollback script

### 2. Validate Configuration

```bash
ansible-playbook -i inventory.ini validate-bond-config.yml
```

This will verify:
- Bond interface is up and in 802.3ad mode
- Both 10Gb NICs are active slaves
- All VLAN interfaces are operational
- LACP is active

### 3. Rollback Configuration

If anything goes wrong, use the generated rollback script:

```bash
# Check current state
/etc/netplan/ansible-backup/{timestamp}/rollback.sh verify

# Perform rollback
/etc/netplan/ansible-backup/{timestamp}/rollback.sh restore
```

## Features

### Idempotency
- Checks existing configuration before making changes
- Only applies necessary modifications
- Safe to run multiple times

### Backup and Rollback
- Automatic backup of netplan and NetworkManager configurations
- Timestamped backups in `/etc/netplan/ansible-backup/`
- Generated rollback script for easy restoration

### Validation
- Verifies NIC speeds (10Gb)
- Checks bond mode and LACP status
- Validates VLAN interface configuration

### Error Handling
- Comprehensive error checking
- Graceful failure handling
- Detailed logging and status reporting

## Current Configuration Details

```
Bond: bond0 (802.3ad LACP)
├── Slave: enp9s0f0 (10Gb)
├── Slave: enp9s0f1 (10Gb)
├── VLAN 200: DHCP enabled
├── VLAN 500: Bridged to bridgeLab
└── VLAN 700: DHCP enabled
```

## Prerequisites

- Ansible installed
- Root/sudo access
- NetworkManager installed
- Both 10Gb NICs physically connected

## Safety Features

- Creates timestamped backups before any changes
- Validates configuration before and after changes
- Provides rollback mechanism
- Idempotent operations prevent accidental changes
- Comprehensive error checking and reporting

## Troubleshooting

1. **Playbook fails to run**: Check sudo permissions and Ansible installation
2. **Bond not forming**: Verify physical connections and switch configuration
3. **VLANs not working**: Check switch VLAN configuration
4. **Need to rollback**: Use the generated rollback script in backup directory

## Manual Commands for Reference

```bash
# Check bond status
cat /proc/net/bonding/bond0

# Check interface status
ip link show bond0
nmcli connection show

# Check VLAN status
ip link show bond0.200
ip addr show bond0.200
```