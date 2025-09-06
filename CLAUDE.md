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

### Core Playbook Operations
```bash
# Apply main configuration (idempotent)
ansible-playbook -i inventory.ini configure-802.1ad-bond.yml

# Validate current configuration
ansible-playbook -i inventory.ini validate-bond-config.yml

# Setup automated management with hourly execution
ansible-playbook -i inventory.ini install-ansible-pull.yml
```

### Automated Management Commands
```bash
# Check status and recent logs
sudo /usr/local/bin/manage-ansible-pull status

# Execute immediately (bypass timer)
sudo /usr/local/bin/manage-ansible-pull run-now

# View detailed logs
sudo /usr/local/bin/manage-ansible-pull logs

# Disable/enable automatic execution
sudo /usr/local/bin/manage-ansible-pull disable
sudo /usr/local/bin/manage-ansible-pull enable
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

# Check hardware speeds
ethtool enp9s0f0 | grep Speed
ethtool enp9s0f1 | grep Speed

# Monitor real-time bond activity
watch -n 1 'cat /proc/net/bonding/bond0'
```

## Safety Features

- **Idempotent Operations**: All playbooks can be run multiple times safely
- **Automatic Backups**: Creates timestamped backups in `/etc/netplan/ansible-backup/`
- **Hardware Validation**: Verifies 10Gb NIC speeds before configuration
- **Comprehensive Error Handling**: Includes graceful failure handling and detailed logging
- **Generated Rollback Scripts**: Automatic creation of restoration scripts for each configuration change
- **Automated Management**: Hourly ansible-pull execution with automatic revert on persistent failures
- **Failure Detection**: Monitors validation failures and triggers automatic rollback after 60 minutes of persistent issues
- **Logging**: Comprehensive logging to `/var/log/ansible-pull-network.log` with logrotate configuration

## Architecture Overview

The system uses a layered approach for network configuration management:

1. **Configuration Layer**: Ansible playbooks define desired network state
2. **Automation Layer**: ansible-pull provides continuous configuration management
3. **Validation Layer**: Comprehensive validation ensures configuration correctness
4. **Safety Layer**: Backup and rollback mechanisms provide fail-safe operations

### Key Design Patterns

- **Idempotency**: All operations check current state before making changes
- **Fail-Safe Operations**: Every configuration change creates automatic rollback capability
- **Continuous Validation**: ansible-pull monitors and maintains configuration compliance
- **Timestamped Backups**: All changes are versioned with Unix timestamps for easy tracking

## Repository Structure

```
.
├── configure-802.1ad-bond.yml    # Primary configuration playbook
├── validate-bond-config.yml      # Validation and health checks
├── ansible-pull-main.yml         # Continuous management (runs hourly)
├── install-ansible-pull.yml      # One-time setup for automation
├── rollback_script.j2            # Jinja2 template for rollback scripts
├── inventory.ini                 # Ansible inventory (localhost)
└── .claude/settings.local.json   # Claude Code permissions for system access
```

## Development Notes

- Playbooks use NetworkManager (nmcli) for interface management
- Configuration changes are backed up before application
- VLAN 500 requires special handling as it's bridged to bridgeLab
- All network changes include verification steps to ensure proper operation
- The repository URL in `ansible-pull-main.yml` must be updated after GitHub setup
- Backup timestamps use `ansible_date_time.epoch` for consistency across operations

## Testing and Validation

### Syntax Validation
```bash
# Check playbook syntax
ansible-playbook --syntax-check -i inventory.ini configure-802.1ad-bond.yml
ansible-playbook --syntax-check -i inventory.ini validate-bond-config.yml
```

### Dry Run Testing
```bash
# Test configuration changes without applying
ansible-playbook -i inventory.ini configure-802.1ad-bond.yml --check
```

### Post-Configuration Validation
Always run validation after configuration changes:
```bash
ansible-playbook -i inventory.ini validate-bond-config.yml
```

## GitHub Setup and Automation Workflow

### Initial GitHub Repository Setup
1. Create repository named `system-network-config` on GitHub (public visibility)
2. Update repository URLs in both `ansible-pull-main.yml` and `install-ansible-pull.yml`
3. Push code to GitHub: `git push -u origin main`
4. Run setup: `ansible-playbook -i inventory.ini install-ansible-pull.yml`

### Emergency Procedures
```bash
# Manual rollback (find latest backup first)
ls -1t /etc/netplan/ansible-backup/
sudo /etc/netplan/ansible-backup/{timestamp}/rollback.sh restore

# Disable automation if needed
sudo /usr/local/bin/manage-ansible-pull disable
```

## Critical Configuration Values

- **Repository URL**: `https://github.com/slagathor34/system-network-config.git` (update in both ansible-pull files)
- **Bond Interface**: bond0 (802.3ad LACP mode)
- **Physical NICs**: enp9s0f0, enp9s0f1 (Intel 82599ES 10Gb)
- **System MAC**: 80:61:5F:11:00:BD
- **VLAN IDs**: 200 (DHCP), 500 (bridged to bridgeLab), 700 (DHCP)
- **Backup Location**: `/etc/netplan/ansible-backup/`
- **Log File**: `/var/log/ansible-pull-network.log`

## Architecture Dependencies

The playbooks assume:
- NetworkManager is the primary network management service
- Netplan is used for static configuration
- SystemD timers are available for ansible-pull automation
- Both physical NICs support 10Gb speeds and are properly cabled
- Switch ports are configured for 802.3ad LACP bonding