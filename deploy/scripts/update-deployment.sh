#!/bin/bash
# Script to update Cyprine Heroes deployment
set -e

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/cyprine-update.log; }

log "Starting Cyprine Heroes update..."

# Pull latest code
cd /opt/cyprine-heroes
sudo -u cyprine git pull --rebase origin main
log "Code updated from repository"

# Update backend dependencies if requirements changed
sudo -u cyprine bash -c "source venv/bin/activate && pip install -r backend/requirements.txt"
log "Backend dependencies updated"

# Update frontend dependencies
cd frontend && sudo -u cyprine npm ci
log "Frontend dependencies updated"

# Rebuild frontend with current environment
log "Current API URL: $(grep VITE_API_URL /opt/cyprine-heroes/frontend/.env || echo 'Not set')"
rm -rf dist && mkdir -p dist && chown -R cyprine:cyprine dist
sudo -u cyprine npm run build
chmod -R 755 dist && chown -R www-data:www-data dist
log "Frontend rebuilt"

# Run any new database migrations
cd /opt/cyprine-heroes/backend
sudo -u cyprine bash -c "source ../venv/bin/activate && alembic upgrade head"
log "Database migrations applied"

# Restart backend service
systemctl restart cyprine-backend
sleep 5

# Check status
if systemctl is-active --quiet cyprine-backend; then
    log "✅ Backend service restarted successfully"
else
    log "❌ Backend service failed to restart"
    systemctl status cyprine-backend
    exit 1
fi

# Reload nginx
nginx -t && systemctl reload nginx
log "✅ Nginx reloaded"

log "🎉 Update completed successfully!"
echo ""
echo "Status check:"
/home/ubuntu/check-status.sh
