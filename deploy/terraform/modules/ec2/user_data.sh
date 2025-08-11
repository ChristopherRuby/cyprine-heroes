#!/bin/bash
set -e

# Enhanced user data script for Cyprine Heroes
# This script runs on EC2 instance boot to set up the application

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> /var/log/cyprine-setup.log
}

log "Starting Cyprine Heroes setup..."

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y \
    git \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    nginx \
    curl \
    wget \
    unzip \
    htop \
    tree \
    jq \
    fail2ban \
    ufw

log "System packages installed"

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

log "Node.js installed: $(node --version)"

# Create system user
adduser --system --group --home /opt/cyprine-heroes cyprine || true
mkdir -p /opt/cyprine-heroes /opt/cyprine-heroes-backups
chown -R cyprine:cyprine /opt/cyprine-heroes /opt/cyprine-heroes-backups

log "System user 'cyprine' created"

# Create environment file
mkdir -p /etc/cyprine-heroes
cat > /etc/cyprine-heroes/backend.env << EOF
DATABASE_URL=${database_url}
SECRET_KEY=${secret_key}
ADMIN_PASSWORD=${admin_password}
UPLOAD_DIR=/opt/cyprine-heroes/backend/uploads
CORS_ORIGINS=${cors_origins}
EOF

chown root:root /etc/cyprine-heroes/backend.env
chmod 600 /etc/cyprine-heroes/backend.env

log "Environment file created"

# Clone repository
cd /opt/cyprine-heroes
sudo -u cyprine git clone ${github_repo} . || true
sudo -u cyprine git pull --rebase origin main || true

log "Repository cloned"

# Setup Python virtual environment
sudo -u cyprine python3.11 -m venv venv
sudo -u cyprine bash -c "source venv/bin/activate && pip install --upgrade pip"
sudo -u cyprine bash -c "source venv/bin/activate && pip install -r backend/requirements.txt"

log "Python dependencies installed"

# Build frontend
cd /opt/cyprine-heroes/frontend
sudo -u cyprine npm ci
sudo -u cyprine npm run build

log "Frontend built"

# Create uploads directory
mkdir -p /opt/cyprine-heroes/backend/uploads
chown -R cyprine:cyprine /opt/cyprine-heroes/backend/uploads
chmod 755 /opt/cyprine-heroes/backend/uploads

# Install systemd service
cp /opt/cyprine-heroes/deploy/provisioning/systemd/cyprine-backend.service /etc/systemd/system/ || \
cp /opt/cyprine-heroes/deploy/systemd/cyprine-backend.service /etc/systemd/system/

# Make deployment scripts executable
chmod +x /opt/cyprine-heroes/deploy/provisioning/scripts/*.sh || \
chmod +x /opt/cyprine-heroes/deploy/scripts/*.sh

systemctl daemon-reload
systemctl enable cyprine-backend

log "Systemd service installed"

# Setup logging
cp /opt/cyprine-heroes/deploy/provisioning/systemd/rsyslog-cyprine.conf /etc/rsyslog.d/30-cyprine.conf || \
cp /opt/cyprine-heroes/deploy/systemd/rsyslog-cyprine.conf /etc/rsyslog.d/30-cyprine.conf || true

mkdir -p /var/log/cyprine-heroes
chown cyprine:cyprine /var/log/cyprine-heroes

# Setup log rotation
cp /opt/cyprine-heroes/deploy/provisioning/systemd/cyprine-backend-logrotate /etc/logrotate.d/cyprine-backend || \
cp /opt/cyprine-heroes/deploy/systemd/cyprine-backend-logrotate /etc/logrotate.d/cyprine-backend || true

systemctl restart rsyslog || true

log "Logging configured"

# Configure Nginx
cp /opt/cyprine-heroes/deploy/provisioning/nginx/cyprine-frontend.conf /etc/nginx/sites-available/cyprine-frontend || \
cp /opt/cyprine-heroes/deploy/nginx/cyprine-frontend.conf /etc/nginx/sites-available/cyprine-frontend

ln -sf /etc/nginx/sites-available/cyprine-frontend /etc/nginx/sites-enabled/cyprine-frontend
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
if nginx -t; then
    systemctl reload nginx
    log "Nginx configured and reloaded"
else
    log "Nginx configuration test failed"
fi

# Setup firewall (basic security)
ufw --force enable
ufw allow ssh
ufw allow 'Nginx Full'

log "Basic firewall configured"

# Run database migrations
cd /opt/cyprine-heroes
sudo -u cyprine bash -c "source venv/bin/activate && cd backend && alembic upgrade head" || true

log "Database migrations attempted"

# Start the backend service
systemctl start cyprine-backend

# Wait a moment and check service status
sleep 10
if systemctl is-active --quiet cyprine-backend; then
    log "Backend service started successfully"
else
    log "Backend service failed to start"
    systemctl status cyprine-backend >> /var/log/cyprine-setup.log 2>&1 || true
fi

log "Cyprine Heroes setup completed"

# Create a simple status script
cat > /home/ubuntu/check-status.sh << 'EOF'
#!/bin/bash
echo "=== Cyprine Heroes Status ==="
echo "Backend service: $(systemctl is-active cyprine-backend)"
echo "Nginx service: $(systemctl is-active nginx)"
echo "Disk usage: $(df -h / | tail -1 | awk '{print $5}')"
echo "Memory usage: $(free -h | grep '^Mem:' | awk '{print $3"/"$2}')"
echo "Application URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
EOF

chmod +x /home/ubuntu/check-status.sh
chown ubuntu:ubuntu /home/ubuntu/check-status.sh

log "Status script created at /home/ubuntu/check-status.sh"

# Final system status
/home/ubuntu/check-status.sh >> /var/log/cyprine-setup.log 2>&1

log "Setup script completed successfully"