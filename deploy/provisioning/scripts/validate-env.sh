#!/bin/bash
set -e

ENV_FILE="/etc/cyprine-heroes/backend.env"

echo "Validating environment configuration..."

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Environment file not found: $ENV_FILE"
    exit 1
fi

# Source the env file
set -a
source "$ENV_FILE"
set +a

# Required variables
REQUIRED_VARS=(
    "DATABASE_URL"
    "SECRET_KEY"
    "ADMIN_PASSWORD"
    "UPLOAD_DIR"
    "CORS_ORIGINS"
)

# Check each required variable
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Required environment variable $var is not set"
        exit 1
    fi
    
    # Check for default/placeholder values
    case "$var" in
        "SECRET_KEY")
            if [ "${!var}" = "change-me" ]; then
                echo "❌ $var still has default value 'change-me'"
                exit 1
            fi
            ;;
        "ADMIN_PASSWORD")
            if [ "${!var}" = "change-me" ]; then
                echo "❌ $var still has default value 'change-me'"
                exit 1
            fi
            ;;
        "DATABASE_URL")
            if [[ "${!var}" == *"user:password@host"* ]]; then
                echo "❌ $var still has placeholder values"
                exit 1
            fi
            ;;
        "CORS_ORIGINS")
            if [ "${!var}" = "https://your-domain.tld" ]; then
                echo "❌ $var still has default value"
                exit 1
            fi
            ;;
    esac
    
    echo "✓ $var is properly configured"
done

echo "✅ Environment validation passed"