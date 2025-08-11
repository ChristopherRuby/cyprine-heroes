#!/bin/bash
set -e

WORK_DIR="/opt/cyprine-heroes"
VENV_PATH="$WORK_DIR/venv"
BACKEND_DIR="$WORK_DIR/backend"
UPLOAD_DIR="$WORK_DIR/backend/uploads"

echo "Running pre-start checks..."

# Check if working directory exists
if [ ! -d "$WORK_DIR" ]; then
    echo "❌ Working directory not found: $WORK_DIR"
    exit 1
fi
echo "✓ Working directory exists"

# Check if virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
    echo "❌ Virtual environment not found: $VENV_PATH"
    exit 1
fi
echo "✓ Virtual environment exists"

# Check if uvicorn is available
if [ ! -x "$VENV_PATH/bin/uvicorn" ]; then
    echo "❌ uvicorn not found in virtual environment"
    exit 1
fi
echo "✓ uvicorn is available"

# Check if backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Backend directory not found: $BACKEND_DIR"
    exit 1
fi
echo "✓ Backend directory exists"

# Check if main application exists
if [ ! -f "$BACKEND_DIR/app/main.py" ]; then
    echo "❌ Main application file not found: $BACKEND_DIR/app/main.py"
    exit 1
fi
echo "✓ Main application file exists"

# Check if uploads directory exists and has correct permissions
if [ ! -d "$UPLOAD_DIR" ]; then
    echo "⚠️  Upload directory not found, creating: $UPLOAD_DIR"
    mkdir -p "$UPLOAD_DIR"
    chown cyprine:cyprine "$UPLOAD_DIR"
    chmod 755 "$UPLOAD_DIR"
fi

# Check permissions on uploads directory
if [ ! -w "$UPLOAD_DIR" ]; then
    echo "❌ Upload directory is not writable: $UPLOAD_DIR"
    exit 1
fi
echo "✓ Upload directory is accessible"

# Check if port 8000 is available
if ss -tlnp | grep -q ":8000 "; then
    echo "⚠️  Port 8000 is already in use"
    # Don't exit here as systemd will handle the restart
fi

echo "✅ Pre-start checks completed successfully"