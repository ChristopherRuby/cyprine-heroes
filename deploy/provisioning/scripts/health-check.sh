#!/bin/bash
set -e

HEALTH_URL="http://127.0.0.1:8000/api/health"
MAX_RETRIES=10
RETRY_DELAY=2

echo "Starting health check for Cyprine Heroes backend..."

for i in $(seq 1 $MAX_RETRIES); do
    if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
        echo "✓ Health check passed (attempt $i/$MAX_RETRIES)"
        exit 0
    else
        echo "✗ Health check failed (attempt $i/$MAX_RETRIES)"
        if [ $i -lt $MAX_RETRIES ]; then
            sleep $RETRY_DELAY
        fi
    fi
done

echo "❌ Health check failed after $MAX_RETRIES attempts"
exit 1