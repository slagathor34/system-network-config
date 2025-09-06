#!/bin/bash
# GitHub Self-Hosted Runner Setup Script for Network Configuration GitOps
# This script sets up a GitHub Actions self-hosted runner on the target system

set -euo pipefail

# Configuration variables
RUNNER_USER="github-runner"
RUNNER_HOME="/opt/github-runner"
SERVICE_NAME="github-runner"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# Check prerequisites
log "Checking prerequisites..."
command -v ansible >/dev/null 2>&1 || error "Ansible is not installed. Please install Ansible first."
command -v git >/dev/null 2>&1 || error "Git is not installed. Please install Git first."
command -v curl >/dev/null 2>&1 || error "curl is not installed. Please install curl first."

# Get the latest runner version
log "Getting latest GitHub Actions runner version..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//')
RUNNER_ARCH="x64"  # Assuming x64 architecture

log "Latest runner version: $RUNNER_VERSION"

# Create runner user
log "Creating GitHub runner user..."
if id "$RUNNER_USER" &>/dev/null; then
    warn "User $RUNNER_USER already exists"
else
    useradd -r -m -d "$RUNNER_HOME" -s /bin/bash "$RUNNER_USER"
    log "Created user $RUNNER_USER"
fi

# Create runner directory
log "Setting up runner directory..."
mkdir -p "$RUNNER_HOME"
chown "$RUNNER_USER:$RUNNER_USER" "$RUNNER_HOME"

# Download and extract runner
log "Downloading GitHub Actions runner..."
cd "$RUNNER_HOME"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

sudo -u "$RUNNER_USER" curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L "$RUNNER_URL"
sudo -u "$RUNNER_USER" tar xzf actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz
sudo -u "$RUNNER_USER" rm actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz

# Install dependencies
log "Installing runner dependencies..."
sudo ./bin/installdependencies.sh

# Add runner user to necessary groups
log "Adding runner user to necessary groups..."
usermod -aG sudo "$RUNNER_USER"
# Allow passwordless sudo for network configuration commands
cat > /etc/sudoers.d/github-runner << 'EOF'
# Allow github-runner user to run ansible and network commands without password
github-runner ALL=(ALL) NOPASSWD: /usr/bin/ansible-playbook
github-runner ALL=(ALL) NOPASSWD: /usr/bin/ansible
github-runner ALL=(ALL) NOPASSWD: /usr/sbin/ip
github-runner ALL=(ALL) NOPASSWD: /usr/bin/nmcli
github-runner ALL=(ALL) NOPASSWD: /bin/cat /proc/net/bonding/*
github-runner ALL=(ALL) NOPASSWD: /usr/sbin/ethtool
github-runner ALL=(ALL) NOPASSWD: /bin/systemctl
EOF

# Create systemd service
log "Creating systemd service..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Type=simple
User=$RUNNER_USER
WorkingDirectory=$RUNNER_HOME
ExecStart=$RUNNER_HOME/run.sh
Restart=always
RestartSec=5
KillMode=process
KillSignal=SIGTERM
TimeoutStopSec=5min

[Install]
WantedBy=multi-user.target
EOF

# Set up runner configuration script
cat > "$RUNNER_HOME/configure-runner.sh" << 'EOF'
#!/bin/bash
# Interactive runner configuration script
# Run this as the github-runner user after the main setup

if [[ $EUID -eq 0 ]]; then
   echo "Do not run this script as root. Run as github-runner user:"
   echo "sudo -u github-runner ./configure-runner.sh"
   exit 1
fi

echo "GitHub Actions Runner Configuration"
echo "=================================="
echo ""
echo "You need the following information from your GitHub repository:"
echo "1. Repository URL (e.g., https://github.com/username/system-network-config)"
echo "2. Runner registration token (get from GitHub repo Settings > Actions > Runners > New runner)"
echo ""
echo "To get the registration token:"
echo "1. Go to your GitHub repository"
echo "2. Click Settings > Actions > Runners"
echo "3. Click 'New self-hosted runner'"
echo "4. Select Linux and x64"
echo "5. Copy the token from the configure command"
echo ""

read -p "Enter your repository URL: " REPO_URL
read -p "Enter your registration token: " TOKEN

# Configure the runner
./config.sh --url "$REPO_URL" --token "$TOKEN" --name "$(hostname)-network-config" --labels "self-hosted,linux,x64,network-config" --work "_work"

echo ""
echo "Runner configured successfully!"
echo "To start the runner service:"
echo "sudo systemctl enable github-runner"
echo "sudo systemctl start github-runner"
echo "sudo systemctl status github-runner"
EOF

chown "$RUNNER_USER:$RUNNER_USER" "$RUNNER_HOME/configure-runner.sh"
chmod +x "$RUNNER_HOME/configure-runner.sh"

# Set ownership
chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_HOME"

# Reload systemd
systemctl daemon-reload

log "GitHub Actions runner setup completed!"
echo ""
echo "Next steps:"
echo "1. Configure the runner by running:"
echo "   sudo -u $RUNNER_USER $RUNNER_HOME/configure-runner.sh"
echo ""
echo "2. Start the runner service:"
echo "   sudo systemctl enable $SERVICE_NAME"
echo "   sudo systemctl start $SERVICE_NAME"
echo ""
echo "3. Check the service status:"
echo "   sudo systemctl status $SERVICE_NAME"
echo ""
echo "The runner will be available with labels: self-hosted, linux, x64, network-config"
echo ""
warn "SECURITY NOTE: The runner user has sudo privileges for network configuration commands."
warn "Ensure your repository has proper access controls and review all workflows carefully."