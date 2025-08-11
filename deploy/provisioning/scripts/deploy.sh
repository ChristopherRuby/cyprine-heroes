#!/bin/bash
set -e

# Cyprine Heroes Deployment Script with Rollback Support
# Usage: ./deploy.sh [--rollback]

WORK_DIR="/opt/cyprine-heroes"
BACKUP_DIR="/opt/cyprine-heroes-backups"
SERVICE_NAME="cyprine-backend"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
    exit 1
fi

# Rollback function
rollback() {
    if [ -z "$1" ]; then
        echo "Available backups:"
        ls -la "$BACKUP_DIR/" 2>/dev/null || echo "No backups found"
        echo ""
        echo "Usage: $0 --rollback BACKUP_NAME"
        echo "Example: $0 --rollback backup_20240101_120000"
        exit 1
    fi
    
    ROLLBACK_PATH="$BACKUP_DIR/$1"
    
    if [ ! -d "$ROLLBACK_PATH" ]; then
        error "Backup not found: $ROLLBACK_PATH"
        exit 1
    fi
    
    log "Rolling back to: $1"
    
    # Stop service
    systemctl stop $SERVICE_NAME
    
    # Restore backup
    rsync -av --delete "$ROLLBACK_PATH/" "$WORK_DIR/"
    chown -R cyprine:cyprine "$WORK_DIR"
    
    # Restart service
    systemctl start $SERVICE_NAME
    
    # Wait and check health
    sleep 10
    if systemctl is-active --quiet $SERVICE_NAME; then
        success "Rollback completed successfully"
        systemctl status $SERVICE_NAME --no-pager
    else
        error "Service failed to start after rollback"
        systemctl status $SERVICE_NAME --no-pager
        exit 1
    fi
    
    exit 0
}

# Handle rollback option
if [ "$1" = "--rollback" ]; then
    rollback "$2"
fi

log "Starting Cyprine Heroes deployment..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Pre-deployment checks
log "Running pre-deployment checks..."

if [ ! -d "$WORK_DIR" ]; then
    error "Work directory not found: $WORK_DIR"
    exit 1
fi

if ! systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
    error "Service not found: $SERVICE_NAME"
    exit 1
fi

success "Pre-deployment checks passed"

# Create backup
log "Creating backup..."
cp -r "$WORK_DIR" "$BACKUP_PATH"
success "Backup created: $BACKUP_PATH"

# Stop service
log "Stopping service..."
systemctl stop $SERVICE_NAME

# Pull latest changes
log "Updating code..."
cd "$WORK_DIR"
sudo -u cyprine git fetch --all
sudo -u cyprine git pull --rebase origin main

# Update backend dependencies
log "Updating backend dependencies..."
sudo -u cyprine bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r backend/requirements.txt"

# Build frontend
log "Building frontend..."
cd frontend
sudo -u cyprine npm ci
sudo -u cyprine npm run build
cd ..

# Run database migrations
log "Running database migrations..."
sudo -u cyprine bash -c "source venv/bin/activate && cd backend && alembic upgrade head"

# Fix permissions
log "Setting correct permissions..."
chown -R cyprine:cyprine "$WORK_DIR"
chmod -R 755 "$WORK_DIR"
chmod -R 755 "$WORK_DIR/backend/uploads"

# Start service
log "Starting service..."
systemctl start $SERVICE_NAME

# Wait for service to start
sleep 10

# Health check
log "Performing health check..."
if systemctl is-active --quiet $SERVICE_NAME; then
    # Additional health check via HTTP
    if /opt/cyprine-heroes/deploy/scripts/health-check.sh; then
        success "Deployment completed successfully!"
        systemctl status $SERVICE_NAME --no-pager
        
        # Clean old backups (keep last 5)
        log "Cleaning old backups..."
        cd "$BACKUP_DIR"
        ls -t | tail -n +6 | xargs -r rm -rf
        success "Old backups cleaned"
        
    else
        error "Health check failed, rolling back..."
        systemctl stop $SERVICE_NAME
        rsync -av --delete "$BACKUP_PATH/" "$WORK_DIR/"
        chown -R cyprine:cyprine "$WORK_DIR"
        systemctl start $SERVICE_NAME
        
        if systemctl is-active --quiet $SERVICE_NAME; then
            warning "Rollback completed, but deployment failed"
        else
            error "Rollback failed! Manual intervention required"
        fi
        exit 1
    fi
else
    error "Service failed to start, rolling back..."
    rsync -av --delete "$BACKUP_PATH/" "$WORK_DIR/"
    chown -R cyprine:cyprine "$WORK_DIR"
    systemctl start $SERVICE_NAME
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        warning "Rollback completed, but deployment failed"
    else
        error "Rollback failed! Manual intervention required"
    fi
    exit 1
fi

log "Deployment completed successfully!"