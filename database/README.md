# Database Management - Cyprine Heroes

This directory contains database configuration and management tools for the Cyprine Heroes application.

## 📁 Files

- **`.env`** - Database connection configuration and sensitive data (production)
- **`.env.example`** - Template for database configuration
- **`seed_heroes.py`** - Script to populate database with sample heroes
- **`generate_curl_commands.py`** - Script to export heroes and generate curl recreation commands

## 🔒 Security Configuration

**Important:** All sensitive information is stored in the `.env` file and should never be committed to version control.

### Environment Variables

The following variables must be defined in your `.env` file:

```bash
# Database Configuration
DATABASE_NAME=cyprine_heroes
DATABASE_USER=cyprine_user
DATABASE_PASSWORD=your_secure_database_password
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_URL=postgresql+psycopg://user:password@host:port/database

# API Authentication
ADMIN_PASSWORD=your_secure_admin_password
```

### Security Best Practices

1. **Never commit `.env` files** - They contain sensitive passwords
2. **Use strong passwords** - Especially for `ADMIN_PASSWORD` and `DATABASE_PASSWORD`
3. **Different passwords per environment** - Production should have unique credentials
4. **Environment variable validation** - Scripts will fail safely if required variables are missing

## 🐘 PostgreSQL Configuration

The application uses PostgreSQL 16 with the following setup:

```bash
Database Name: cyprine_heroes
Database User: cyprine_user
Database Password: [from .env file]
Connection: localhost:5432
```

## 🛠️ Hero Export & Recreation

### generate_curl_commands.py

This script exports existing heroes from the API and generates bash scripts with curl commands to recreate them:

```bash
# Generate curl commands for current heroes
python generate_curl_commands.py

# This creates a timestamped file like:
# hero_curl_commands_YYYYMMDD_HHMMSS.sh
```

**Features:**
- Reads heroes from the running API backend
- Automatically filters out test heroes
- Uses environment variables for authentication (no hardcoded passwords)
- Generates executable bash script with curl commands
- Creates temporary JSON files for each hero
- Includes cleanup and verification commands

**Security:**
- Requires `ADMIN_PASSWORD` environment variable
- No passwords stored in generated files
- Generated scripts also validate environment variables

### Usage Example

```bash
# 1. Ensure your .env file has ADMIN_PASSWORD set
echo "ADMIN_PASSWORD=your_password" >> .env

# 2. Make sure the backend API is running
cd ../backend && uvicorn app.main:app --reload

# 3. Generate curl commands
cd ../database && python generate_curl_commands.py

# 4. Use the generated script on a new environment
./hero_curl_commands_20250816_123456.sh
```

## 🎯 Sample Data

The `seed_heroes.py` script automatically creates sample heroes:

1. **Tony Stark** (Iron Man) - Hero
2. **Natasha Romanoff** (Black Widow) - Hero  
3. **Loki Laufeyson** (God of Mischief) - Villain
4. **Steve Rogers** (Captain America) - Hero
5. **Bruce Banner** (The Hulk) - Hero

## 🚀 Usage

### Automatic Initialization
During infrastructure deployment, the database is automatically:
1. Installed (PostgreSQL 16)
2. Configured (user and database created)
3. Migrated (Alembic runs migrations)
4. Seeded (sample heroes created)

### Manual Operations

```bash
# Connect to database
sudo -u postgres psql -d cyprine_heroes

# Run sample data script manually
cd /opt/cyprine-heroes
source venv/bin/activate
python database/seed_heroes.py

# Database backup
sudo -u postgres pg_dump cyprine_heroes > backup.sql

# Database restore  
sudo -u postgres psql -d cyprine_heroes < backup.sql
```

## 🔧 Configuration

Copy `.env.example` to `.env` and customize if needed:

```bash
cp .env.example .env
# Edit .env with your values
```

The connection URL format is:
```
postgresql+psycopg://username:password@host:port/database
```

## 🔍 Troubleshooting

### Database Connection Issues
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connectivity
sudo -u postgres psql -d cyprine_heroes -c "SELECT 1;"

# Check database exists
sudo -u postgres psql -c "\l" | grep cyprine_heroes
```

### Migration Issues
```bash
# Check migration status
cd backend && source ../venv/bin/activate
alembic current
alembic history

# Run migrations manually
alembic upgrade head
```