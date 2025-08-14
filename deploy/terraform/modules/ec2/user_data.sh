#!/bin/bash
set -e
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> /var/log/cyprine-setup.log; }
log "Starting Cyprine Heroes setup..."

apt-get update -y && apt-get upgrade -y
apt-get install -y git python3.11 python3.11-venv python3.11-dev nginx curl wget unzip htop tree jq fail2ban ufw ca-certificates gnupg snapd
log "System packages installed"

curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs
log "Node.js installed: $(node --version)"

sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update -y && apt-get install -y postgresql-16 postgresql-client-16
systemctl start postgresql && systemctl enable postgresql
log "PostgreSQL installed and started"

for i in {1..30}; do
    if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then break; fi
    sleep 2
done

sudo -u postgres psql -c "CREATE USER cyprine_user WITH PASSWORD 'cyprinadeApp21';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE cyprine_heroes OWNER cyprine_user;" 2>/dev/null || true  
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE cyprine_heroes TO cyprine_user;" 2>/dev/null || true
sudo -u postgres psql -c "ALTER USER cyprine_user CREATEDB;" 2>/dev/null || true
log "Database configured"

adduser --system --group --home /opt/cyprine-heroes cyprine || true
mkdir -p /opt/cyprine-heroes /opt/cyprine-heroes-backups /etc/cyprine-heroes
chown -R cyprine:cyprine /opt/cyprine-heroes /opt/cyprine-heroes-backups

cat > /etc/cyprine-heroes/backend.env << EOF
DATABASE_URL=${database_url}
SECRET_KEY=${secret_key}
ADMIN_PASSWORD=${admin_password}
UPLOAD_DIR=/opt/cyprine-heroes/backend/uploads
CORS_ORIGINS=${cors_origins}
EOF
chown root:root /etc/cyprine-heroes/backend.env && chmod 600 /etc/cyprine-heroes/backend.env

cd /opt/cyprine-heroes
sudo -u cyprine git clone ${github_repo} . || sudo -u cyprine git pull --rebase origin main || true
log "Repository cloned"

sudo -u cyprine python3.11 -m venv venv
sudo -u cyprine bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r backend/requirements.txt && pip install psycopg requests"
log "Python environment ready"

# Configure frontend environment - use domain if provided, otherwise IP
if [ -n "${domain_name}" ] && [ "${domain_name}" != "" ]; then
    # Build with HTTPS from the start if domain is provided (SSL will be added later)
    cat > /opt/cyprine-heroes/frontend/.env << EOF
VITE_API_URL=https://${domain_name}/api
EOF
    log "Frontend configured for domain: https://${domain_name}/api"
else
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    cat > /opt/cyprine-heroes/frontend/.env << EOF
VITE_API_URL=http://$PUBLIC_IP/api
EOF
    log "Frontend configured with IP-based API URL: http://$PUBLIC_IP/api"
fi
chown cyprine:cyprine /opt/cyprine-heroes/frontend/.env

# Install frontend dependencies first
cd /opt/cyprine-heroes/frontend && sudo -u cyprine npm ci
log "Frontend dependencies installed"

# We'll build the frontend AFTER nginx/SSL is configured to ensure correct API URL

mkdir -p /opt/cyprine-heroes/backend/uploads
chown -R cyprine:cyprine /opt/cyprine-heroes/backend/uploads

cat > /etc/systemd/system/cyprine-backend.service << 'EOF'
[Unit]
Description=Cyprine Heroes FastAPI backend
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=cyprine
Group=cyprine
WorkingDirectory=/opt/cyprine-heroes/backend
EnvironmentFile=/etc/cyprine-heroes/backend.env
ExecStart=/opt/cyprine-heroes/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable cyprine-backend
log "Service configured"

snap install core && snap refresh core && snap install --classic certbot && ln -sf /snap/bin/certbot /usr/bin/certbot

if [ -n "${domain_name}" ] && [ "${domain_name}" != "" ]; then
cat > /etc/nginx/sites-available/cyprine-frontend << 'EOF'
server {
    listen 80;
    server_name ${domain_name};
    root /opt/cyprine-heroes/frontend/dist;
    index index.html;
    
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
    location / { try_files $uri /index.html; }
}
EOF
else
cat > /etc/nginx/sites-available/cyprine-frontend << 'EOF'
server {
    listen 80;
    server_name _;
    root /opt/cyprine-heroes/frontend/dist;
    index index.html;
    
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
    location / { try_files $uri /index.html; }
}
EOF
fi

ln -sf /etc/nginx/sites-available/cyprine-frontend /etc/nginx/sites-enabled/cyprine-frontend
rm -f /etc/nginx/sites-enabled/default
chmod 755 /opt/cyprine-heroes/frontend /opt/cyprine-heroes

if nginx -t; then systemctl reload nginx; log "Nginx configured"; fi

if [ -n "${domain_name}" ] && [ "${domain_name}" != "" ]; then
    log "Setting up SSL for ${domain_name}..."
    sleep 5
    mkdir -p /var/www/html/.well-known/acme-challenge/
    chown -R www-data:www-data /var/www/html
    
    if certbot certonly --webroot -w /var/www/html -d ${domain_name} --non-interactive --agree-tos --email admin@cyprinade.com; then
        log "SSL obtained"
        
cat > /etc/nginx/sites-available/cyprine-frontend << 'EOF'
server {
    listen 80;
    server_name ${domain_name};
    return 301 https://$server_name$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${domain_name};
    ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    add_header Strict-Transport-Security "max-age=31536000" always;
    root /opt/cyprine-heroes/frontend/dist;
    index index.html;
    
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
    location / { try_files $uri /index.html; }
    location /.well-known/acme-challenge/ { root /var/www/html; }
}
EOF
        if nginx -t; then 
            systemctl reload nginx; 
            log "HTTPS configured"; 
        fi
        
        echo '#!/bin/bash
if certbot renew --quiet --no-self-upgrade; then
    nginx -t && systemctl reload nginx
    echo "[$(date)] SSL renewed" >> /var/log/cyprine-ssl-renewal.log
fi' > /opt/cyprine-heroes/renew-ssl.sh
        chmod +x /opt/cyprine-heroes/renew-ssl.sh
        (crontab -l 2>/dev/null; echo "0 */12 * * * /opt/cyprine-heroes/renew-ssl.sh") | crontab -
        log "SSL auto-renewal configured"
    else
        log "SSL setup failed, continuing with HTTP"
    fi
fi

# Now build frontend with the final configuration (HTTP or HTTPS)
log "Building frontend with final configuration..."
rm -rf /opt/cyprine-heroes/frontend/dist
mkdir -p /opt/cyprine-heroes/frontend/dist  
chown -R cyprine:cyprine /opt/cyprine-heroes/frontend/dist

cd /opt/cyprine-heroes/frontend && sudo -u cyprine npm run build
chmod -R 755 /opt/cyprine-heroes/frontend/dist && chown -R www-data:www-data /opt/cyprine-heroes/frontend/dist
log "Frontend built with API URL: $(grep VITE_API_URL /opt/cyprine-heroes/frontend/.env)"

# Configure firewall
ufw --force enable && ufw allow ssh && ufw allow 'Nginx Full'
log "Firewall configured"

# Setup backend environment and database
cp /etc/cyprine-heroes/backend.env /opt/cyprine-heroes/backend/.env
chown cyprine:cyprine /opt/cyprine-heroes/backend/.env
chgrp cyprine /etc/cyprine-heroes/backend.env && chmod 640 /etc/cyprine-heroes/backend.env
log "Backend environment configured"

# Run database migrations
cd /opt/cyprine-heroes && sudo -u cyprine bash -c "source venv/bin/activate && cd backend && alembic upgrade head"
if [ $? -eq 0 ]; then
    log "Database migrations completed successfully"
else
    log "ERROR: Database migrations failed"
fi

# Start backend service
systemctl start cyprine-backend && sleep 10

# Verify backend is running and seed database
if systemctl is-active --quiet cyprine-backend; then
    log "Backend service started successfully"
    
    # Seed the database with initial data
    cd /opt/cyprine-heroes && sudo -u cyprine bash -c "source venv/bin/activate && python database/seed_heroes.py"
    if [ $? -eq 0 ]; then
        log "Database seeding completed successfully"
    else
        log "WARNING: Database seeding failed, but backend is running"
    fi
else
    log "ERROR: Backend service failed to start"
    systemctl status cyprine-backend >> /var/log/cyprine-setup.log 2>&1 || true
fi

cat > /home/ubuntu/check-status.sh << 'EOF'
#!/bin/bash
echo "=== Cyprine Heroes Status ==="
echo "Backend: $(systemctl is-active cyprine-backend)"
echo "Nginx: $(systemctl is-active nginx)"
echo "Disk: $(df -h / | tail -1 | awk '{print $5}')"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3"/"$2}')"
if [ -f "/etc/letsencrypt/live/${domain_name}/fullchain.pem" ]; then
    echo "SSL: ✅ Active"
    echo "URL: https://${domain_name}"
else
    echo "SSL: ❌ Not configured"  
    echo "URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
fi
EOF
chmod +x /home/ubuntu/check-status.sh && chown ubuntu:ubuntu /home/ubuntu/check-status.sh

/home/ubuntu/check-status.sh >> /var/log/cyprine-setup.log 2>&1
log "Setup completed successfully"