# Cyprine Heroes - Deployment & Infrastructure

Production-ready deployment using **Infrastructure as Code** (Terraform) with **AWS EC2**, enhanced security, monitoring, and operational tools.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS EC2 Instance                        │
│                         (t3.small)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────────────────────────────┐    │
│  │   Nginx     │    │              React Frontend          │    │
│  │   (Port 80) │────▶  (Vite build → /dist)              │    │
│  │             │    │  • Dynamic API URL detection        │    │
│  └─────────────┘    │  • Hero management interface        │    │
│         │            └─────────────────────────────────────┘    │
│         │ API Proxy                                             │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              FastAPI Backend                           │    │
│  │              (Port 8000)                               │    │
│  │  • REST API endpoints (/api/heroes, /api/auth)        │    │
│  │  • JWT Authentication                                  │    │
│  │  • File upload handling                               │    │
│  │  • Pydantic validation                                │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │            PostgreSQL 16 Database                      │    │
│  │            (Local installation)                        │    │
│  │  • Database: cyprine_heroes                           │    │
│  │  • User: cyprine_user                                 │    │
│  │  • Tables: heroes, alembic_version                    │    │
│  │  • Automatic migrations via Alembic                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                    ┌─────────────────────────┐
                    │      Internet Users     │
                    │   via Elastic IP        │
                    │   (HTTP Port 80)        │
                    └─────────────────────────┘
```

### 🏗️ **Composants et Relations**

- **Infrastructure**: Terraform-managed AWS EC2 with Elastic IP
- **Web Server**: Nginx reverse proxy (Port 80 → Backend 8000)
- **Frontend**: React (Vite) with dynamic API URL configuration
- **Backend**: FastAPI with JWT auth and file upload
- **Database**: PostgreSQL 16 (local installation)
- **Process Management**: systemd services with dependencies
- **Monitoring**: systemd journal + custom health checks
- **Security**: Hardened systemd service + UFW firewall

## 📁 Directory Structure

```
project-root/
├── backend/                           # 🎯 FastAPI Application
│   ├── app/                          # Application code
│   │   ├── api/endpoints/            # API routes (heroes, auth)
│   │   ├── core/                     # Core config & security
│   │   ├── db/                       # Database session management
│   │   ├── models/                   # SQLAlchemy models
│   │   └── schemas/                  # Pydantic schemas
│   ├── alembic/                      # Database migrations
│   ├── requirements.txt              # Python dependencies
│   └── .env                          # Runtime environment config
├── frontend/                         # ⚛️ React Application
│   ├── src/                          # React source code
│   │   ├── components/               # React components
│   │   ├── services/                 # API client
│   │   └── pages/                    # Application pages
│   ├── dist/                         # Built assets (served by Nginx)
│   ├── package.json                  # Node.js dependencies
│   └── .env                          # Build-time environment (API URL)
├── database/                         # 🆕 Database Management
│   ├── .env                          # Database connection config
│   ├── .env.example                  # Database config template
│   └── seed_heroes.py                # Sample data initialization
└── deploy/                           # 🚀 Infrastructure & Deployment
    ├── README.md                     # This file
    ├── terraform/                    # Infrastructure as Code
    │   ├── environments/prod/        # Production environment config
    │   ├── modules/ec2/              # EC2 instance module
    │   │   ├── user_data.sh          # 🔧 Automated setup script
    │   │   └── *.tf                  # Terraform configurations
    │   └── scripts/                  # Infrastructure management
    │       ├── deploy-infra.sh       # Main deployment script
    │       └── manage-instance.sh    # Instance operations
    ├── provisioning/                 # Application provisioning
    │   ├── nginx/                    # Nginx reverse proxy config
    │   ├── systemd/                  # systemd service definitions
    │   └── scripts/                  # Application deployment
    └── docs/                         # Documentation
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI configured**:
   ```bash
   aws configure
   aws sts get-caller-identity  # Verify credentials
   ```

2. **Terraform installed** (>= 1.0):
   ```bash
   # macOS
   brew install terraform
   
   # Ubuntu/Debian
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   sudo apt update && sudo apt install terraform
   ```

3. **SSH Key Pair**:
   ```bash
   # Create AWS key pair (replace 'cyprine-key' with your preferred name)
   aws ec2 create-key-pair --key-name cyprine-key --region eu-west-3 --query 'KeyMaterial' --output text > ~/.ssh/cyprine-key.pem
   chmod 400 ~/.ssh/cyprine-key.pem
   ```

### Initial Deployment

1. **Configure environment**:
   ```bash
   cd deploy/terraform/environments/prod
   cp terraform.tfvars.example terraform.tfvars
   
   # Edit terraform.tfvars with your values:
   # - key_name: Your AWS key pair name
   # - allowed_ssh_cidrs: Your public IP (/32)
   # - database_url: PostgreSQL connection (configured automatically)
   # - secret_key: See "Secure Secret Management" section below
   # - admin_password: Your admin password
   ```

2. **Deploy infrastructure**:
   ```bash
   # From deploy/terraform/scripts/
   ./deploy-infra.sh init     # Initialize Terraform
   ./deploy-infra.sh plan     # Preview changes
   ./deploy-infra.sh apply    # Deploy infrastructure
   ```

3. **Get connection information**:
   ```bash
   ./deploy-infra.sh output   # Show all outputs
   ./deploy-infra.sh ssh      # Connect to instance
   ```

## 🔐 Secure Secret Management

### JWT Secret Key Setup

The `secret_key` is critical for JWT token authentication security. Use AWS Parameter Store for secure storage:

```bash
# 1. Generate and store secret in AWS Parameter Store
aws ssm put-parameter --name "/cyprine-heroes/prod/secret-key" \
  --value "$(openssl rand -base64 32)" \
  --type "SecureString"

# 2. Retrieve the secret for terraform.tfvars
SECRET_KEY=$(aws ssm get-parameter --name "/cyprine-heroes/prod/secret-key" \
  --with-decryption --query 'Parameter.Value' --output text)

# 3. Add to terraform.tfvars
echo "secret_key = \"$SECRET_KEY\"" >> terraform.tfvars
```

### Alternative: Environment Variables
```bash
# Set as environment variable (Terraform will auto-detect TF_VAR_*)
export TF_VAR_secret_key="$(openssl rand -base64 32)"

# No need to add to terraform.tfvars file
```

### Security Best Practices
- **Never commit secrets** to Git repositories
- **Use AWS Parameter Store** for production secrets
- **Rotate secrets regularly** (recommended: every 90 days)
- **Set file permissions**: `chmod 600 terraform.tfvars`
- **Add to .gitignore**: `echo "terraform.tfvars" >> .gitignore`

### Other Sensitive Variables
Apply the same pattern for other secrets:
```bash
# Store admin password
aws ssm put-parameter --name "/cyprine-heroes/prod/admin-password" \
  --value "your-secure-admin-password" \
  --type "SecureString"

# Database URL is automatically configured for local PostgreSQL
# No need to store database credentials in Parameter Store
```

## 🛠️ Management Commands

### Infrastructure Management
```bash
cd deploy/terraform/scripts/

# Deployment
./deploy-infra.sh init              # First-time setup
./deploy-infra.sh plan              # Preview changes
./deploy-infra.sh apply             # Deploy/update infrastructure
./deploy-infra.sh output            # Show connection info
./deploy-infra.sh destroy           # ⚠️  Destroy all resources

# Instance Management
./manage-instance.sh                # Interactive menu
./manage-instance.sh status         # Show instance status
./manage-instance.sh start          # Start stopped instance
./manage-instance.sh stop           # Stop instance (save costs)
./manage-instance.sh restart        # Restart instance
./manage-instance.sh health         # Health check
./manage-instance.sh monitor        # Real-time monitoring
./manage-instance.sh ssh            # SSH connect
```

### Application Management
```bash
# SSH into instance first
./deploy-infra.sh ssh

# Then on the instance:
sudo systemctl status cyprine-backend     # Service status
sudo journalctl -u cyprine-backend -f     # View logs
./check-status.sh                          # Quick health check

# Application deployment (updates)
cd /opt/cyprine-heroes/deploy/provisioning/scripts/
./deploy.sh                               # Deploy latest version
./deploy.sh --rollback backup_name       # Rollback to backup
./monitor-service.sh                      # Service monitoring
```

## 💰 Cost Optimization

### EC2 Instance Costs (eu-west-3)
- **t3.small running**: ~€0.022/hour (~€16/month)
- **t3.small stopped**: €0.00/hour (only EBS charged)
- **EBS 20GB**: ~€2/month

### Cost Optimization Strategies
```bash
# Daily routine: Stop overnight to save ~50%
./manage-instance.sh stop     # Evening
./manage-instance.sh start    # Morning

# Weekend shutdown: Save additional ~€3/month
./manage-instance.sh stop     # Friday evening
./manage-instance.sh start    # Monday morning

# Total optimized cost: ~€8-12/month vs €18/month continuous
```

## 🔒 Security Features

### Infrastructure Security
- **Elastic IP**: Fixed IP address for consistent access
- **Security Groups**: Restricted access (SSH from your IP only)
- **Encrypted EBS**: All storage encrypted at rest
- **IAM**: Minimal required permissions

### Application Security
- **systemd hardening**: Process isolation, read-only filesystem
- **Firewall**: UFW configured with minimal ports
- **SSL/TLS**: HTTPS support with Let's Encrypt
- **Environment isolation**: Secrets in separate file

### Security Best Practices
```bash
# 1. Restrict SSH access in terraform.tfvars
allowed_ssh_cidrs = ["YOUR.IP.ADDRESS/32"]

# 2. Use strong passwords and keys (see "Secure Secret Management" section)
# Store secrets in AWS Parameter Store, not in files

# 3. Regular updates (automated in user_data.sh)
apt-get update && apt-get upgrade -y

# 4. Monitor access
./manage-instance.sh logs | grep -i "failed\|unauthorized"
```

## 📊 Monitoring & Operations

### Health Checks
```bash
# Quick status
./manage-instance.sh status

# Comprehensive health check
./manage-instance.sh health

# Real-time monitoring
./manage-instance.sh monitor

# Application-specific checks
./deploy-infra.sh ssh
./check-status.sh
```

### Log Management
```bash
# Infrastructure logs
sudo journalctl -u cyprine-backend -f

# Setup logs
sudo tail -f /var/log/cyprine-setup.log

# System logs
sudo tail -f /var/log/syslog

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Backup & Recovery
```bash
# Manual backup (via AWS snapshots)
aws ec2 create-snapshot --volume-id $(aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id) --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text)

# Application-level backup
./deploy.sh  # Creates automatic backups before deployment
```

## 🔄 Deployment Workflows

### New Feature Deployment
```bash
# 1. Update code in GitHub
git push origin main

# 2. SSH to instance and deploy
./deploy-infra.sh ssh
cd /opt/cyprine-heroes/deploy/provisioning/scripts/
./deploy.sh

# 3. Verify deployment
./monitor-service.sh
```

### Infrastructure Updates
```bash
# 1. Update terraform configuration
vim deploy/terraform/environments/prod/terraform.tfvars

# 2. Plan and apply changes
./deploy-infra.sh plan
./deploy-infra.sh apply

# 3. Verify changes
./manage-instance.sh status
```

### Rollback Procedures
```bash
# Application rollback
./deploy.sh --rollback backup_20240101_120000

# Infrastructure rollback (if needed)
git checkout previous-version
./deploy-infra.sh plan
./deploy-infra.sh apply
```

## 🔧 Customization

### Instance Configuration
Edit `deploy/terraform/environments/prod/terraform.tfvars`:
```hcl
instance_type = "t3.medium"  # More CPU/RAM
volume_size   = 40           # More storage
```

### Security Configuration
```hcl
# Restrict access further
allowed_ssh_cidrs = ["YOUR.HOME.IP/32", "YOUR.OFFICE.IP/32"]

# Different region
aws_region = "eu-west-1"  # Ireland instead of Paris
```

### Application Configuration
```bash
# Edit environment variables
sudo vim /etc/cyprine-heroes/backend.env
sudo systemctl restart cyprine-backend
```

## 🆘 Troubleshooting

### Common Issues

**Instance won't start**:
```bash
./manage-instance.sh status
aws logs describe-log-groups  # Check CloudWatch logs
```

**Application not responding**:
```bash
./manage-instance.sh health
./deploy-infra.sh ssh
sudo systemctl status cyprine-backend
sudo tail -f /var/log/cyprine-setup.log
```

**Terraform errors**:
```bash
cd deploy/terraform/environments/prod
terraform refresh
terraform plan  # Check for drift
```

**SSH connection issues**:
```bash
# Check security group and IP
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)

# Verify key permissions
ls -la ~/.ssh/cyprine-key.pem  # Should be 400
```

### Emergency Procedures

**Complete rebuild**:
```bash
# 1. Backup data if needed
./deploy-infra.sh ssh "sudo tar czf backup.tar.gz /opt/cyprine-heroes/backend/uploads"

# 2. Destroy and recreate
./deploy-infra.sh destroy
./deploy-infra.sh apply
```

**Service recovery**:
```bash
# Reset systemd service
sudo systemctl stop cyprine-backend
sudo systemctl daemon-reload
sudo systemctl start cyprine-backend
```

## 📚 Advanced Topics

### Custom Domain Setup
```bash
# 1. Point your domain to the Elastic IP
# 2. SSH to instance and setup SSL
./deploy-infra.sh ssh
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com

# 3. Update CORS settings
sudo vim /etc/cyprine-heroes/backend.env
# CORS_ORIGINS=https://yourdomain.com
sudo systemctl restart cyprine-backend
```

### Database Management

Local PostgreSQL 16 is automatically installed and configured:

```bash
# Connect to database
./deploy-infra.sh ssh
sudo -u postgres psql -d cyprine_heroes

# Database backup
sudo -u postgres pg_dump cyprine_heroes > backup.sql

# Database restore
sudo -u postgres psql -d cyprine_heroes < backup.sql

# View database status
sudo systemctl status postgresql
```

**Database Configuration:**
- **Database**: `cyprine_heroes`
- **User**: `cyprine_user` (full privileges)
- **Connection**: `localhost:5432`
- **Version**: PostgreSQL 16

### Multi-Environment Setup
```bash
# Create staging environment
cp -r deploy/terraform/environments/prod deploy/terraform/environments/staging
# Edit staging/terraform.tfvars for staging values
cd deploy/terraform/environments/staging
terraform init
terraform apply
```

## 🔄 Recent Improvements (v2.2)

### ✅ **Database & Installation Reliability**
- **🐘 Local PostgreSQL 16**: Complete local database setup with proper user management
- **⚡ Installation Sequence**: Fixed PostgreSQL → Backend initialization order
- **🔄 Database Connectivity**: Active waiting and connectivity verification before migrations
- **🎯 Sample Data**: Automated hero seeding with `database/seed_heroes.py`
- **⚙️ Service Dependencies**: systemd services with proper PostgreSQL dependencies

### ✅ **Configuration & Error Handling**  
- **🔧 Pydantic Model**: Fixed `cors_origins` field missing in Settings model
- **📋 Environment Management**: Centralized database config in `database/` directory
- **🚨 Error Visibility**: Improved logging and error detection in user_data.sh
- **🔍 Migration Diagnostics**: Explicit success/failure reporting for database migrations

### 🔧 **Technical Implementation**
```bash
# PostgreSQL readiness verification
for i in {1..30}; do
    if sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
        log "PostgreSQL is ready"
        break
    fi
    sleep 2
done

# Application connectivity test before migrations
python -c "
from app.core.config import settings
import psycopg
conn = psycopg.connect(settings.database_url)
conn.close()
print('Database connection successful')
"

# systemd service with database dependency
[Unit]
After=network.target postgresql.service
Requires=postgresql.service
```

### 📊 **Database Configuration**
```bash
# Automatic database setup
DATABASE_NAME=cyprine_heroes
DATABASE_USER=cyprine_user  
DATABASE_PASSWORD=cyprinadeApp21
DATABASE_URL=postgresql+psycopg://cyprine_user:cyprinadeApp21@localhost:5432/cyprine_heroes

# Sample heroes automatically created
- Tony Stark (Iron Man)
- Natasha Romanoff (Black Widow)  
- Loki Laufeyson (God of Mischief)
- Steve Rogers (Captain America)
- Bruce Banner (The Hulk)
```

### 🔄 **Installation Flow (Corrected Order)**
```mermaid
graph TD
    A[System Updates] --> B[Install PostgreSQL 16]
    B --> C[Start PostgreSQL Service]
    C --> D[Wait PostgreSQL Ready]
    D --> E[Create Database & User]
    E --> F[Test DB Connectivity]
    F --> G[Install Node.js & Python]
    G --> H[Clone Repository]
    H --> I[Configure Frontend .env]
    I --> J[Build Frontend]
    J --> K[Install Python Dependencies]
    K --> L[Test App → DB Connection]
    L --> M[Run Alembic Migrations]
    M --> N[Configure Nginx]
    N --> O[Create systemd Service]
    O --> P[Start Backend Service]
    P --> Q[Initialize Sample Data]
    Q --> R[Application Ready! 🎉]

    style D fill:#e1f5fe
    style F fill:#e1f5fe  
    style L fill:#e1f5fe
    style M fill:#4caf50,color:#fff
    style Q fill:#ff9800,color:#fff
    style R fill:#4caf50,color:#fff
```

## 🌟 What's New vs Legacy Deploy

### ✅ Added
- **Infrastructure as Code**: Full Terraform automation
- **Instance Management**: Start/stop for cost optimization  
- **Enhanced Monitoring**: Real-time resource monitoring
- **Automated Deployment**: One-command infrastructure setup
- **Cost Optimization**: Built-in cost management tools
- **Better Documentation**: Comprehensive guides and examples
- **Automated Fixes**: All deployment issues resolved in user_data.sh

### 🔄 Improved
- **Security**: Hardened configurations and best practices
- **Reliability**: Health checks and automated recovery
- **Maintainability**: Modular Terraform structure
- **Operations**: Rich set of management scripts
- **Deployment**: Zero-touch installation from fresh instance

### 📦 Preserved
- **Application Scripts**: All existing deployment scripts moved to `provisioning/`
- **Configurations**: Nginx, systemd, and environment configs preserved
- **Compatibility**: Existing workflows still work from `provisioning/scripts/`

---

**Need Help?** Check the `docs/` directory for detailed guides or run scripts with `-h` for help.