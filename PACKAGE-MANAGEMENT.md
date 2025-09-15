# Package Management Guide

This document explains how to manage system packages using the automated package management system in the ansible-pull playbook.

## Overview

The package management system is located in `tasks/hourly/package-management.yml` and runs hourly as part of the ansible-pull automation. It provides organized package lists for easy maintenance and ensures your system has all required software.

## Package Categories

The system organizes packages into logical categories:

### Essential System Packages
Basic system utilities and tools that should always be installed:
- `curl`, `wget`, `git`, `htop`, `tree`, `vim`, `nano`
- `unzip`, `zip`, `jq`, `rsync`, `screen`, `tmux`
- `net-tools`, `dnsutils`, `iputils-ping`, `traceroute`, `telnet`
- `ncdu`, `iotop`, `iftop`, `lsof`, `strace`, `tcpdump`
- `ca-certificates`, `gnupg`, `lsb-release`, `apt-transport-https`

### Development Packages
Tools for software development:
- `build-essential`, `make`, `gcc`, `g++`, `gdb`
- `python3`, `python3-pip`, `python3-venv`, `python3-dev`
- `nodejs`, `npm`

### Monitoring Packages
System monitoring and logging tools:
- `rsyslog`, `logrotate`, `cron`, `systemd-timesyncd`
- `fail2ban`, `ufw`

### Network Packages
Network configuration and tools:
- `openssh-server`, `openssh-client`, `rsync`, `sshpass`
- `netplan.io`, `networkd-dispatcher`, `bridge-utils`
- `vlan`, `ethtool`

### Storage Packages
Storage management tools:
- `btrfs-progs`, `smartmontools`, `hdparm`, `nvme-cli`
- `lvm2`, `cryptsetup`, `nfs-common`, `nfs-kernel-server`

### Optional Packages
Advanced packages that can be enabled/disabled:
- `docker-ce`, `docker-ce-cli`, `docker-buildx-plugin`, `docker-compose-plugin`
- `ansible`, `ansible-core`
- `cockpit`, `cockpit-docker`, `cockpit-machines`, `cockpit-networkmanager`
- `ollama`

## How to Add New Packages

### 1. Adding to Existing Categories

Edit `tasks/hourly/package-management.yml` and add your package to the appropriate list:

```yaml
- name: "Package Management - Set essential system packages"
  set_fact:
    essential_packages:
      - curl
      - wget
      - git
      - your-new-package  # Add here
```

### 2. Adding New Package Categories

Create a new package category:

```yaml
- name: "Package Management - Set your custom packages"
  set_fact:
    custom_packages:
      - package1
      - package2
      - package3

# Then add the installation task:
- name: "Package Management - Install custom packages"
  apt:
    name: "{{ custom_packages }}"
    state: present
  become: yes
  register: custom_install_result
```

### 3. Adding Conditional Packages

For packages that should only be installed under certain conditions:

```yaml
- name: "Package Management - Install conditional packages"
  apt:
    name: 
      - special-package
    state: present
  become: yes
  when: ansible_hostname == "specific-server"
```

## How to Remove Packages

### 1. Enable Package Removal

Set `package_removal_enabled: true` in the playbook:

```yaml
- name: "Package Management - Set packages to remove"
  set_fact:
    packages_to_remove:
      - unwanted-package1
      - unwanted-package2
    package_removal_enabled: true  # Change to true
```

### 2. Add Packages to Removal List

Add packages to the `packages_to_remove` list:

```yaml
packages_to_remove:
  - snapd           # Example: remove snap support
  - telnet          # Example: remove telnet for security
  - old-package     # Your package here
```

## Configuration Options

### Enable/Disable Optional Packages

```yaml
optional_packages_enabled: true   # Set to false to skip optional packages
```

### Enable/Disable Package Removal

```yaml
package_removal_enabled: false   # Set to true to enable removal
```

### Cache Management

The system automatically:
- Updates package cache hourly (if older than 1 hour)
- Removes orphaned packages with `autoremove`
- Cleans package cache with `autoclean`

## Testing Changes

### 1. Syntax Check
```bash
ansible-playbook --syntax-check -i inventory.ini ansible-pull-main.yml
```

### 2. Dry Run Test
```bash
ansible-playbook -i inventory.ini ansible-pull-main.yml --check --diff
```

### 3. Apply Changes
```bash
ansible-playbook -i inventory.ini ansible-pull-main.yml
```

## Monitoring Package Changes

The system logs all package management activities:

- **Local logs**: Check `/var/log/ansible-pull-network.log`
- **Syslog**: Package info messages in system logs
- **Debug output**: Detailed results during playbook execution

## Examples

### Adding a New Development Tool

```yaml
development_packages:
  - build-essential
  - make
  - gcc
  - g++
  - gdb
  - python3
  - python3-pip
  - python3-venv
  - python3-dev
  - nodejs
  - npm
  - code          # Add VS Code
  - terraform     # Add Terraform
```

### Adding Security Tools

```yaml
- name: "Package Management - Set security packages"
  set_fact:
    security_packages:
      - nmap
      - wireshark
      - fail2ban
      - rkhunter
      - chkrootkit

- name: "Package Management - Install security packages"
  apt:
    name: "{{ security_packages }}"
    state: present
  become: yes
  when: install_security_tools | default(false) | bool
```

### Removing Unwanted Services

```yaml
packages_to_remove:
  - snapd                    # Remove snap package system
  - apache2                  # Remove if using nginx instead
  - sendmail                 # Remove if using postfix
package_removal_enabled: true
```

## Best Practices

1. **Test First**: Always test changes with `--check --diff` before applying
2. **Categorize**: Keep packages organized in logical categories
3. **Document**: Comment why specific packages are needed
4. **Version Control**: Commit changes to git for tracking
5. **Monitor**: Check logs to ensure packages install successfully
6. **Backup**: Ansible automatically creates backups where applicable

## Troubleshooting

### Package Installation Fails
- Check if package name is correct: `apt search package-name`
- Verify package is available: `apt show package-name`
- Check repository access: `apt update`

### Missing Dependencies
- The system will automatically install dependencies
- Check error messages in ansible output
- Use `apt install --dry-run package-name` to preview

### Repository Issues
- Package cache is updated automatically
- Check network connectivity
- Verify repository configuration in `/etc/apt/sources.list`

The package management system ensures your infrastructure stays up-to-date with all necessary software while providing flexibility to customize package installations per your requirements.