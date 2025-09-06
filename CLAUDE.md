# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a system administration repository containing Ansible playbooks for configuring and managing 802.1ad bonding on 10Gb network interfaces. The repository focuses on network infrastructure automation with comprehensive backup and rollback capabilities.

## Core Components

### Main Playbooks
- `configure-802.1ad-bond.yml` - Primary configuration playbook that sets up 802.3ad LACP bonding on Intel 10Gb NICs (enp9s0f0, enp9s0f1) with VLAN configuration
- `validate-bond-config.yml` - Validation playbook that verifies bond configuration, LACP status, and VLAN interfaces
- `ansible-pull-main.yml` - Main playbook for ansible-pull execution with automatic validation and revert capabilities
- `install-ansible-pull.yml` - Setup playbook that configures systemd timer for hourly ansible-pull execution
- `rollback_script.j2` - Jinja2 template for generating rollback scripts with backup restoration capabilities

### Configuration Files
- `inventory.ini` - Ansible inventory targeting localhost with elevated privileges
- `.claude/settings.local.json` - Claude Code permissions configuration allowing network and system analysis commands

## Network Architecture

**Bond Configuration:**
- Interface: bond0 (802.3ad LACP mode)
- Slave NICs: enp9s0f0, enp9s0f1 (Intel 82599ES 10Gb)
- MAC Address: 80:61:5F:11:00:BD

**VLAN Setup:**
- VLAN 200: DHCP enabled
- VLAN 500: Bridged to bridgeLab (special configuration)
- VLAN 700: DHCP enabled

## Commands

### Apply Configuration
```bash
ansible-playbook -i inventory.ini configure-802.1ad-bond.yml
```

### Validate Configuration
```bash
ansible-playbook -i inventory.ini validate-bond-config.yml
```

### Setup Automated Management (Ansible-Pull)
```bash
# Install ansible-pull with hourly execution
ansible-playbook -i inventory.ini install-ansible-pull.yml

# Management commands
sudo /usr/local/bin/manage-ansible-pull status
sudo /usr/local/bin/manage-ansible-pull run-now
sudo /usr/local/bin/manage-ansible-pull logs
```

### Rollback Configuration
```bash
# Check current state
/etc/netplan/ansible-backup/{timestamp}/rollback.sh verify

# Perform rollback
/etc/netplan/ansible-backup/{timestamp}/rollback.sh restore
```

### Manual Network Analysis
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

## Safety Features

- **Idempotent Operations**: All playbooks can be run multiple times safely
- **Automatic Backups**: Creates timestamped backups in `/etc/netplan/ansible-backup/`
- **Hardware Validation**: Verifies 10Gb NIC speeds before configuration
- **Comprehensive Error Handling**: Includes graceful failure handling and detailed logging
- **Generated Rollback Scripts**: Automatic creation of restoration scripts for each configuration change
- **Automated Management**: Hourly ansible-pull execution with automatic revert on persistent failures
- **Failure Detection**: Monitors validation failures and triggers automatic rollback after 60 minutes of persistent issues

## Development Notes

- Playbooks use NetworkManager (nmcli) for interface management
- Configuration changes are backed up before application
- VLAN 500 requires special handling as it's bridged to bridgeLab
- All network changes include verification steps to ensure proper operation