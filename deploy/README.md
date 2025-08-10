# Deployment (EC2 + systemd)

This is a minimal, robust setup for Ubuntu on EC2 using systemd and Nginx.

## 1) Provision
- Ubuntu 22.04 EC2, small instance (t3.micro fine to start)
- Open ports: 80 (HTTP), 443 (HTTPS/if using certbot), 22 (SSH)

## 2) Server prep (run as root)
```bash
adduser --system --group cyprine
mkdir -p /opt/cyprine-heroes
chown -R cyprine:cyprine /opt/cyprine-heroes
apt update && apt install -y python3.11 python3.11-venv nginx
```

## 3) App deploy
```bash
# as user cyprine
sudo -u cyprine bash -lc '
  cd /opt/cyprine-heroes && \
  git clone https://github.com/ChristopherRuby/cyprine-heroes.git . && \
  python3.11 -m venv venv && \
  source venv/bin/activate && \
  pip install -r backend/requirements.txt && \
  cd frontend && npm ci && npm run build && cd ..
'
```

## 4) Env & systemd
```bash
mkdir -p /etc/cyprine-heroes
cp deploy/env/backend.env.example /etc/cyprine-heroes/backend.env
# edit values in /etc/cyprine-heroes/backend.env

cp deploy/systemd/cyprine-backend.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now cyprine-backend
```

## 5) Nginx
```bash
cp deploy/nginx/cyprine-frontend.conf /etc/nginx/sites-available/cyprine-frontend
ln -s /etc/nginx/sites-available/cyprine-frontend /etc/nginx/sites-enabled/cyprine-frontend
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

## 6) HTTPS (optional)
Install certbot nginx, then:
```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d your-domain.tld
```

## 7) DB & Migrations
- Point DATABASE_URL to your managed Postgres (e.g., Neon/ RDS).
- Run Alembic once:
```bash
sudo -u cyprine bash -lc '
  source /opt/cyprine-heroes/venv/bin/activate && \
  cd /opt/cyprine-heroes/backend && \
  alembic upgrade head
'
```

## Notes
- API served on 127.0.0.1:8000, proxied by Nginx.
- Frontend is static (built) from frontend/dist under Nginx.
- Uploads path: /opt/cyprine-heroes/backend/uploads (ensure write perms for user cyprine).
