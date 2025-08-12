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
    ufw \
    ca-certificates \
    gnupg

log "System packages installed"

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

log "Node.js installed: $(node --version)"

# Install PostgreSQL 16
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update -y
apt-get install -y postgresql-16 postgresql-client-16

log "PostgreSQL 16 installed"

# Configure PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Wait for PostgreSQL to be ready
log "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
        log "PostgreSQL is ready"
        break
    fi
    log "PostgreSQL not ready yet, waiting... ($i/30)"
    sleep 2
done

# Create database and user
sudo -u postgres psql -c "CREATE USER cyprine_user WITH PASSWORD 'cyprinadeApp21';"
sudo -u postgres psql -c "CREATE DATABASE cyprine_heroes OWNER cyprine_user;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE cyprine_heroes TO cyprine_user;"
sudo -u postgres psql -c "ALTER USER cyprine_user CREATEDB;"

# Test database connectivity
log "Testing database connectivity..."
if sudo -u postgres psql -d cyprine_heroes -c "SELECT 1;" > /dev/null 2>&1; then
    log "Database connectivity verified"
else
    log "ERROR: Database connectivity test failed"
fi

log "PostgreSQL database and user configured"

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
sudo -u cyprine bash -c "source venv/bin/activate && pip install psycopg requests"

log "Python dependencies installed (including psycopg)"

# Configure frontend environment
cat > /opt/cyprine-heroes/frontend/.env << EOF
# Production environment variables
VITE_API_URL=http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/api
EOF

chown cyprine:cyprine /opt/cyprine-heroes/frontend/.env

# Build frontend
cd /opt/cyprine-heroes/frontend
sudo -u cyprine npm ci
sudo -u cyprine npm run build

# Fix frontend permissions for nginx
chmod -R 755 /opt/cyprine-heroes/frontend/dist
chown -R www-data:www-data /opt/cyprine-heroes/frontend/dist

log "Frontend built and configured"

# Create uploads directory
mkdir -p /opt/cyprine-heroes/backend/uploads
chown -R cyprine:cyprine /opt/cyprine-heroes/backend/uploads
chmod 755 /opt/cyprine-heroes/backend/uploads

# Create simplified systemd service
cat > /etc/systemd/system/cyprine-backend.service << 'EOF'
[Unit]
Description=Cyprine Heroes FastAPI backend
After=network.target postgresql.service
Wants=network-online.target
Requires=postgresql.service

[Service]
Type=simple
User=cyprine
Group=cyprine
WorkingDirectory=/opt/cyprine-heroes/backend
EnvironmentFile=/etc/cyprine-heroes/backend.env

# Main service
ExecStart=/opt/cyprine-heroes/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1

# Graceful shutdown
KillMode=mixed
TimeoutStopSec=30

# Restart policy
Restart=always
RestartSec=5

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=cyprine-backend

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cyprine-backend

log "Simplified systemd service installed"

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

# Configure Nginx with corrected proxy settings
cat > /etc/nginx/sites-available/cyprine-frontend << 'EOF'
# Nginx site for serving built frontend and proxying API (HTTP only)
server {
    listen 80;
    server_name _;

    root /opt/cyprine-heroes/frontend/dist;
    index index.html;

    # API proxy - rewrite to add trailing slash for FastAPI
    location ~ ^/api/(.*)$ {
        proxy_pass http://127.0.0.1:8000/api/$1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Prevent redirects
        proxy_redirect off;
    }

    # Frontend
    location / {
        try_files $uri /index.html;
    }
}
EOF

ln -sf /etc/nginx/sites-available/cyprine-frontend /etc/nginx/sites-enabled/cyprine-frontend
rm -f /etc/nginx/sites-enabled/default

# Fix parent directory permissions for nginx access
chmod 755 /opt/cyprine-heroes/frontend
chmod 755 /opt/cyprine-heroes

# Test nginx configuration
if nginx -t; then
    systemctl reload nginx
    log "Nginx configured and reloaded with corrected proxy settings"
else
    log "Nginx configuration test failed"
fi

# Setup firewall (basic security)
ufw --force enable
ufw allow ssh
ufw allow 'Nginx Full'

log "Basic firewall configured"

# Copy environment file to backend directory for alembic
cp /etc/cyprine-heroes/backend.env /opt/cyprine-heroes/backend/.env
chown cyprine:cyprine /opt/cyprine-heroes/backend/.env

# Fix environment file permissions for cyprine user
chgrp cyprine /etc/cyprine-heroes/backend.env
chmod 640 /etc/cyprine-heroes/backend.env

# Test database connectivity from application
log "Testing database connectivity from application..."
cd /opt/cyprine-heroes
if sudo -u cyprine bash -c "source venv/bin/activate && cd backend && python -c \"
from app.core.config import settings
import psycopg
conn = psycopg.connect(settings.database_url)
conn.close()
print('Database connection successful')
\""; then
    log "Application can connect to database"
else
    log "ERROR: Application cannot connect to database"
fi

# Run database migrations
if sudo -u cyprine bash -c "source venv/bin/activate && cd backend && alembic upgrade head"; then
    log "Database migrations completed successfully"
else
    log "ERROR: Database migrations failed"
    # Try to get more details
    sudo -u cyprine bash -c "source venv/bin/activate && cd backend && alembic current" || true
fi

# Start the backend service
systemctl start cyprine-backend

# Wait a moment and check service status
sleep 10
if systemctl is-active --quiet cyprine-backend; then
    log "Backend service started successfully"
    
    # Initialize database with sample heroes
    log "Initializing database with sample heroes..."
    cd /opt/cyprine-heroes
    sudo -u cyprine bash -c "source venv/bin/activate && python database/seed_heroes.py" || true
    
    log "Database seeding completed"
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