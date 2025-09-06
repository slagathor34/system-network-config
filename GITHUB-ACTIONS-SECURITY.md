# GitHub Actions Security Considerations for Network Configuration

## Overview

This document outlines security considerations and best practices for the GitOps deployment of network configurations using GitHub Actions with self-hosted runners.

## Security Model

### Risk Assessment
- **HIGH RISK**: Self-hosted runner has sudo privileges for network configuration
- **MEDIUM RISK**: Automated deployment of network changes
- **MEDIUM RISK**: Repository access controls critical for system security

### Threat Vectors
1. **Malicious PR/Push**: Unauthorized network configuration changes
2. **Runner Compromise**: Self-hosted runner system compromise
3. **Repository Access**: Unauthorized repository access
4. **Supply Chain**: Dependency poisoning in Ansible/Python packages

## Security Controls

### Repository Security

#### Branch Protection
```bash
# Required branch protection rules for main branch:
- Require pull request reviews (minimum 2 reviewers)
- Require status checks to pass
- Require linear history
- Include administrators in restrictions
- Restrict pushes to specific users/teams
```

#### Required Reviews
- All network configuration changes MUST be reviewed
- Reviewers must understand network implications
- Use CODEOWNERS file to enforce review requirements

#### Secrets Management
- Never store sensitive data in repository
- Use GitHub Secrets for any required credentials
- Rotate secrets regularly

### Self-Hosted Runner Security

#### System Hardening
```bash
# Apply security updates
sudo apt update && sudo apt upgrade -y

# Configure firewall
sudo ufw enable
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow from 10.0.0.0/8 to any port 22  # Adjust as needed

# Disable unnecessary services
sudo systemctl list-unit-files --state=enabled | grep -v essential
```

#### User Isolation
- Runner user has minimal required privileges
- Sudo access limited to specific network commands only
- Regular audit of sudoers configuration

#### Monitoring
```bash
# Monitor runner activity
sudo journalctl -u github-runner -f

# Monitor sudo usage
sudo tail -f /var/log/auth.log | grep sudo

# Monitor network changes
sudo journalctl -u NetworkManager -f
```

### Workflow Security

#### Environment Protection
- Production environment requires manual approval
- Limit deployment to specific branches
- Use environment-specific secrets

#### Input Validation
```yaml
# Example validation in workflow
- name: Validate inputs
  run: |
    # Validate playbook paths
    test -f configure-802.1ad-bond.yml || exit 1
    test -f validate-bond-config.yml || exit 1
    
    # Check for suspicious content
    grep -r "eval\|exec\|system" *.yml && exit 1 || true
```

#### Logging and Auditing
- All deployment actions logged
- GitHub Actions logs retained
- System logs monitored for changes

## Access Controls

### GitHub Repository Access
```
Admin Access: System administrators only
Write Access: Network engineers, DevOps team
Read Access: Development team, monitoring systems
```

### Self-Hosted Runner Access
```bash
# SSH access to runner system
- Key-based authentication only
- Restricted to specific IP ranges
- Regular access review
```

### Network Device Access
- Runner system has minimal network access required
- Firewall rules restrict outbound connections
- Regular review of network access patterns

## Incident Response

### Detection
1. **Unauthorized Changes**: Monitor for unexpected network configuration
2. **Failed Deployments**: Alert on deployment failures
3. **Access Anomalies**: Monitor for unusual access patterns

### Response Plan
1. **Immediate**: Disable GitHub Actions runner service
2. **Assessment**: Review recent changes and logs
3. **Isolation**: Isolate affected systems if needed
4. **Recovery**: Use automated rollback capabilities
5. **Investigation**: Forensic analysis of compromise

### Emergency Contacts
```
Primary: Network Operations Team
Secondary: Security Team
Escalation: Infrastructure Management
```

## Compliance and Governance

### Change Management
- All changes tracked in Git history
- Deployment approvals documented
- Regular compliance audits

### Documentation Requirements
- All workflows documented
- Security controls documented
- Incident response procedures documented

### Regular Reviews
- Monthly security review of workflows
- Quarterly access review
- Annual security assessment

## Best Practices

### Development
1. **Test First**: Always test in non-production environment
2. **Small Changes**: Deploy incremental changes
3. **Review Process**: Mandatory peer review
4. **Rollback Plan**: Always have rollback capability

### Deployment
1. **Validation**: Pre and post-deployment validation
2. **Monitoring**: Real-time monitoring during deployment
3. **Documentation**: Document all changes
4. **Communication**: Notify stakeholders of changes

### Maintenance
1. **Updates**: Regular updates of runner and dependencies
2. **Cleanup**: Remove unused workflows and secrets
3. **Monitoring**: Continuous monitoring of security posture
4. **Training**: Regular security training for team

## Emergency Procedures

### Disable GitOps Pipeline
```bash
# Stop runner service
sudo systemctl stop github-runner
sudo systemctl disable github-runner

# Remove runner registration (if compromised)
cd /opt/github-runner
sudo -u github-runner ./config.sh remove --token YOUR_REMOVAL_TOKEN
```

### Manual Rollback
```bash
# Find latest backup
ls -1t /etc/netplan/ansible-backup/

# Execute rollback
sudo /etc/netplan/ansible-backup/TIMESTAMP/rollback.sh restore

# Verify rollback
ansible-playbook -i inventory.ini validate-bond-config.yml
```

### System Recovery
```bash
# If runner system compromised
1. Isolate system from network
2. Create forensic image
3. Rebuild runner system
4. Restore from known good backup
5. Re-register runner with new tokens
```

## Monitoring and Alerting

### Required Monitoring
- GitHub Actions workflow status
- Self-hosted runner health
- Network configuration changes
- System security events

### Alert Conditions
- Workflow failures
- Unauthorized access attempts
- Network configuration drift
- Runner system anomalies

### Dashboards
- GitHub Actions status dashboard
- Network health dashboard
- Security events dashboard
- System performance dashboard

## Conclusion

This GitOps approach provides automated network configuration deployment while maintaining security controls. Regular review and updates of these security measures are essential for maintaining a secure deployment pipeline.