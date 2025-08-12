# Database Management - Cyprine Heroes

This directory contains database configuration and management tools for the Cyprine Heroes application.

## 📁 Files

- **`.env`** - Database connection configuration (production)
- **`.env.example`** - Template for database configuration
- **`seed_heroes.py`** - Script to populate database with sample heroes

## 🐘 PostgreSQL Configuration

The application uses PostgreSQL 16 with the following setup:

```bash
Database Name: cyprine_heroes
Database User: cyprine_user
Database Password: cyprinadeApp21
Connection: localhost:5432
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