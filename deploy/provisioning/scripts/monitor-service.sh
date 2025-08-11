#!/bin/bash

# Cyprine Heroes Service Monitor
# Usage: ./monitor-service.sh [--continuous]

SERVICE_NAME="cyprine-backend"
HEALTH_URL="http://127.0.0.1:8000/api/health"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_service_status() {
    echo -e "${BLUE}=== Service Status ===${NC}"
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Service is running${NC}"
    else
        echo -e "${RED}❌ Service is not running${NC}"
        return 1
    fi
    
    # Get service details
    echo -e "\n${BLUE}Service Details:${NC}"
    systemctl status $SERVICE_NAME --no-pager | head -10
    
    return 0
}

check_health_endpoint() {
    echo -e "\n${BLUE}=== Health Check ===${NC}"
    
    if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Health endpoint responding${NC}"
        # Try to get actual response
        RESPONSE=$(curl -s "$HEALTH_URL" 2>/dev/null || echo "Unable to fetch response")
        echo "Response: $RESPONSE"
    else
        echo -e "${RED}❌ Health endpoint not responding${NC}"
        return 1
    fi
    
    return 0
}

check_resources() {
    echo -e "\n${BLUE}=== Resource Usage ===${NC}"
    
    # Memory usage
    MEMORY_INFO=$(systemctl show $SERVICE_NAME --property=MemoryCurrent,MemoryMax | tr '\n' ' ')
    echo "Memory: $MEMORY_INFO"
    
    # CPU usage (approximate)
    PID=$(systemctl show $SERVICE_NAME --property=MainPID --value)
    if [ -n "$PID" ] && [ "$PID" != "0" ]; then
        CPU_USAGE=$(ps -p $PID -o %cpu --no-headers 2>/dev/null || echo "N/A")
        echo "CPU Usage: ${CPU_USAGE}%"
    fi
    
    # Check port
    if ss -tlnp | grep -q ":8000 "; then
        echo -e "${GREEN}✅ Port 8000 is listening${NC}"
    else
        echo -e "${RED}❌ Port 8000 is not listening${NC}"
    fi
}

check_logs() {
    echo -e "\n${BLUE}=== Recent Logs (last 10 lines) ===${NC}"
    journalctl -u $SERVICE_NAME --no-pager -n 10 --output=short
    
    # Check for errors in recent logs
    ERROR_COUNT=$(journalctl -u $SERVICE_NAME --since "1 hour ago" --no-pager | grep -i "error\|critical\|fatal" | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "\n${YELLOW}⚠️  Found $ERROR_COUNT error(s) in the last hour${NC}"
    fi
}

show_full_status() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Cyprine Heroes Monitor         ║${NC}"
    echo -e "${BLUE}║            $(date +'%Y-%m-%d %H:%M:%S')           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
    
    check_service_status
    STATUS_OK=$?
    
    check_health_endpoint
    HEALTH_OK=$?
    
    check_resources
    check_logs
    
    echo -e "\n${BLUE}=== Overall Status ===${NC}"
    if [ $STATUS_OK -eq 0 ] && [ $HEALTH_OK -eq 0 ]; then
        echo -e "${GREEN}✅ All checks passed${NC}"
        return 0
    else
        echo -e "${RED}❌ Some checks failed${NC}"
        return 1
    fi
}

# Continuous monitoring mode
if [ "$1" = "--continuous" ]; then
    echo "Starting continuous monitoring (press Ctrl+C to exit)..."
    while true; do
        show_full_status
        echo -e "\n${BLUE}Next check in 30 seconds...${NC}"
        sleep 30
    done
else
    show_full_status
fi