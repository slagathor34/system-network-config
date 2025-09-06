# GitHub Repository and Ansible-Pull Automation Setup Guide

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository:
   - **Repository name**: `system-network-config`
   - **Description**: `Ansible playbooks for 802.1ad bond configuration on 10Gb NICs with automatic validation and rollback`
   - **Visibility**: Public
   - **Do not** initialize with README (we already have files)

2. After creating the repository, GitHub will show you the commands to push existing code.

## Step 2: Push Code to GitHub

Replace `YOUR_USERNAME` with your GitHub username in the commands below:

```bash
# Add remote origin (update YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/system-network-config.git

# Rename branch to main
git branch -M main

# Push to GitHub
git push -u origin main
```

## Step 3: Update Repository URLs

Before setting up ansible-pull, update the repository URL in these files:

### Update ansible-pull-main.yml
```bash
# Edit the repo_url variable (line 8)
sed -i 's|YOUR_USERNAME|your-actual-username|g' ansible-pull-main.yml
```

### Update install-ansible-pull.yml
```bash
# Edit the repo_url variable (line 5)
sed -i 's|YOUR_USERNAME|your-actual-username|g' install-ansible-pull.yml
```

## Step 4: Setup Ansible-Pull Automation

Run the installation playbook to set up hourly execution:

```bash
# Install and configure ansible-pull with systemd timer
ansible-playbook -i inventory.ini install-ansible-pull.yml
```

## Step 5: Verify Setup

Check that everything is working:

```bash
# Check timer status
sudo /usr/local/bin/manage-ansible-pull status

# Run ansible-pull immediately to test
sudo /usr/local/bin/manage-ansible-pull run-now

# Check logs
sudo /usr/local/bin/manage-ansible-pull logs
```

## What This Setup Provides

### Automated Features
- **Hourly Execution**: Ansible-pull runs every hour via systemd timer
- **Automatic Updates**: Pulls latest playbooks from GitHub repository
- **Smart Configuration**: Only applies changes when network state differs from desired state
- **Validation**: Runs validation checks after any configuration changes
- **Auto-Revert**: Automatically reverts to last known good configuration if failures persist for more than 60 minutes
- **Comprehensive Logging**: All actions logged to `/var/log/ansible-pull-network.log`

### Safety Mechanisms
- **Pre-validation**: Checks current state before making changes
- **Post-validation**: Verifies configuration after changes
- **Failure Detection**: Monitors for persistent failures
- **Automatic Rollback**: Uses existing backup/rollback scripts
- **Randomized Delay**: Timer includes random delay to avoid thundering herd

### Management Commands
- `sudo /usr/local/bin/manage-ansible-pull status` - Show status and recent logs
- `sudo /usr/local/bin/manage-ansible-pull run-now` - Execute immediately
- `sudo /usr/local/bin/manage-ansible-pull logs` - Show detailed logs
- `sudo /usr/local/bin/manage-ansible-pull disable` - Stop automatic execution
- `sudo /usr/local/bin/manage-ansible-pull enable` - Resume automatic execution

## Workflow After Setup

1. **Make Changes**: Edit playbooks locally and push to GitHub
2. **Automatic Deployment**: Changes are pulled and applied within the hour
3. **Monitoring**: Check logs or status as needed
4. **Rollback**: System automatically reverts if issues persist

## Emergency Procedures

### Manual Rollback
If immediate rollback is needed:
```bash
# Find latest backup
ls -1t /etc/netplan/ansible-backup/

# Execute rollback (replace TIMESTAMP with actual timestamp)
sudo /etc/netplan/ansible-backup/TIMESTAMP/rollback.sh restore
```

### Disable Automation
If you need to stop automated management:
```bash
sudo /usr/local/bin/manage-ansible-pull disable
```

### Re-enable Automation
To resume automated management:
```bash
sudo /usr/local/bin/manage-ansible-pull enable
```