#!/bin/bash
set -e

# Cyprine Heroes Instance Management Script
# Inspired by mbot-infra manage.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/environments/prod"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

get_instance_info() {
    cd "$TERRAFORM_DIR"
    INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null)
    ELASTIC_IP=$(terraform output -raw elastic_ip 2>/dev/null)
    
    if [ -z "$INSTANCE_ID" ]; then
        error "Could not get instance information. Is infrastructure deployed?"
        exit 1
    fi
}

show_help() {
    cat << EOF
Cyprine Heroes Instance Management

Usage: $0 [COMMAND]

Commands:
    status      Show instance status
    start       Start the instance
    stop        Stop the instance (saves costs)
    restart     Restart the instance
    reboot      Reboot the instance (hard restart)
    logs        Show application logs
    health      Check application health
    monitor     Real-time monitoring
    connect     SSH to the instance
    help        Show this help

Interactive Mode:
    $0          Run without arguments for interactive menu

Cost Optimization:
    - stop: Stops instance to save costs (~€16/month -> €2/month)
    - start: Starts stopped instance and waits for readiness

Examples:
    $0 status      # Check if instance is running
    $0 stop        # Stop to save costs overnight
    $0 start       # Start in the morning
    $0 monitor     # Watch resource usage
EOF
}

show_interactive_menu() {
    while true; do
        echo
        echo -e "${BLUE}=== Cyprine Heroes Instance Manager ===${NC}"
        echo "1) Status"
        echo "2) Start instance"
        echo "3) Stop instance"
        echo "4) Restart instance"
        echo "5) Reboot instance"
        echo "6) View logs"
        echo "7) Health check"
        echo "8) Monitor resources"
        echo "9) SSH connect"
        echo "0) Exit"
        echo
        read -p "Choose an option [0-9]: " choice
        
        case $choice in
            1) show_status ;;
            2) start_instance ;;
            3) stop_instance ;;
            4) restart_instance ;;
            5) reboot_instance ;;
            6) show_logs ;;
            7) health_check ;;
            8) monitor_resources ;;
            9) ssh_connect ;;
            0) exit 0 ;;
            *) warning "Invalid option. Please choose 0-9." ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

show_status() {
    log "Checking instance status..."
    get_instance_info
    
    # Get detailed instance information
    INSTANCE_INFO=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0]')
    STATE=$(echo $INSTANCE_INFO | jq -r '.State.Name')
    INSTANCE_TYPE=$(echo $INSTANCE_INFO | jq -r '.InstanceType')
    LAUNCH_TIME=$(echo $INSTANCE_INFO | jq -r '.LaunchTime')
    
    echo
    echo -e "${BLUE}=== Instance Status ===${NC}"
    echo "Instance ID: $INSTANCE_ID"
    echo "State: $STATE"
    echo "Type: $INSTANCE_TYPE"
    echo "Elastic IP: $ELASTIC_IP"
    echo "Launch Time: $LAUNCH_TIME"
    
    if [ "$STATE" = "running" ]; then
        success "Instance is running"
        
        # Check application health
        echo
        log "Checking application health..."
        if curl -f -s "http://$ELASTIC_IP" >/dev/null 2>&1; then
            success "Application is responding"
            echo "Application URL: http://$ELASTIC_IP"
        else
            warning "Application might be starting or has issues"
        fi
    elif [ "$STATE" = "stopped" ]; then
        warning "Instance is stopped (cost optimization mode)"
    else
        log "Instance state: $STATE"
    fi
}

start_instance() {
    log "Starting instance..."
    get_instance_info
    
    aws ec2 start-instances --instance-ids $INSTANCE_ID
    
    log "Waiting for instance to be running..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID
    
    success "Instance started successfully"
    
    log "Waiting for application to be ready (this may take 2-3 minutes)..."
    for i in {1..18}; do  # 3 minutes maximum
        if curl -f -s "http://$ELASTIC_IP" >/dev/null 2>&1; then
            success "Application is ready!"
            echo "Application URL: http://$ELASTIC_IP"
            break
        else
            echo -n "."
            sleep 10
        fi
    done
    echo
}

stop_instance() {
    warning "This will stop the instance to save costs."
    echo "The instance can be started again with '$0 start'"
    echo
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "Stopping instance..."
        get_instance_info
        
        aws ec2 stop-instances --instance-ids $INSTANCE_ID
        
        log "Waiting for instance to stop..."
        aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
        
        success "Instance stopped successfully"
        log "Monthly cost reduced from ~€16 to ~€2 (EBS storage only)"
    else
        log "Stop cancelled"
    fi
}

restart_instance() {
    log "Restarting instance..."
    get_instance_info
    
    aws ec2 reboot-instances --instance-ids $INSTANCE_ID
    
    log "Instance restart initiated. Waiting for services..."
    sleep 30
    
    # Wait for application
    for i in {1..12}; do  # 2 minutes maximum
        if curl -f -s "http://$ELASTIC_IP" >/dev/null 2>&1; then
            success "Application is ready after restart!"
            break
        else
            echo -n "."
            sleep 10
        fi
    done
    echo
}

reboot_instance() {
    warning "This will perform a hard reboot of the instance."
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        restart_instance
    else
        log "Reboot cancelled"
    fi
}

show_logs() {
    log "Connecting to view application logs..."
    get_instance_info
    
    # Get SSH key name from terraform
    cd "$TERRAFORM_DIR"
    SSH_CMD=$(terraform output -raw ssh_connection_command 2>/dev/null)
    KEY_NAME=$(echo $SSH_CMD | grep -o "\.ssh/[^.]*" | cut -d'/' -f2)
    
    echo "Showing recent logs (press Ctrl+C to exit)..."
    ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@$ELASTIC_IP "sudo journalctl -u cyprine-backend -f --since '10 minutes ago'"
}

health_check() {
    log "Running comprehensive health check..."
    get_instance_info
    
    cd "$TERRAFORM_DIR"
    KEY_NAME=$(terraform output -raw ssh_connection_command 2>/dev/null | grep -o "\.ssh/[^.]*" | cut -d'/' -f2)
    
    echo
    echo -e "${BLUE}=== Health Check Results ===${NC}"
    
    # HTTP health check
    if curl -f -s "http://$ELASTIC_IP" >/dev/null 2>&1; then
        success "HTTP endpoint responding"
    else
        error "HTTP endpoint not responding"
    fi
    
    # SSH health check and service status
    ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@$ELASTIC_IP << 'EOF'
        echo "Backend service: $(systemctl is-active cyprine-backend)"
        echo "Nginx service: $(systemctl is-active nginx)"
        echo "Disk usage: $(df -h / | tail -1 | awk '{print $5}' | tr -d '\n') used"
        echo "Memory usage: $(free -h | grep '^Mem:' | awk '{print $3"/"$2}')"
        echo "Load average: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
        
        # Check for errors in logs
        ERROR_COUNT=$(sudo journalctl -u cyprine-backend --since "1 hour ago" | grep -i "error\|critical\|fatal" | wc -l)
        if [ $ERROR_COUNT -gt 0 ]; then
            echo "⚠️  Found $ERROR_COUNT error(s) in the last hour"
        else
            echo "✅ No errors in the last hour"
        fi
EOF
}

monitor_resources() {
    log "Starting real-time monitoring (press Ctrl+C to exit)..."
    get_instance_info
    
    cd "$TERRAFORM_DIR"
    KEY_NAME=$(terraform output -raw ssh_connection_command 2>/dev/null | grep -o "\.ssh/[^.]*" | cut -d'/' -f2)
    
    ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@$ELASTIC_IP << 'EOF'
        echo "Starting resource monitor..."
        while true; do
            clear
            echo "=== Cyprine Heroes Resource Monitor ==="
            echo "Time: $(date)"
            echo
            echo "CPU Usage:"
            top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  " 100 - $1"% used"}'
            
            echo
            echo "Memory Usage:"
            free -h | grep '^Mem:' | awk '{print "  " $3"/"$2" used (" $3/$2*100 "%)"}'
            
            echo
            echo "Disk Usage:"
            df -h / | tail -1 | awk '{print "  " $5" used (" $3"/"$2")"}'
            
            echo
            echo "Network Connections:"
            ss -tuln | grep ":80\|:443\|:8000" | wc -l | awk '{print "  " $1" active connections"}'
            
            echo
            echo "Services Status:"
            echo "  Backend: $(systemctl is-active cyprine-backend)"
            echo "  Nginx: $(systemctl is-active nginx)"
            
            echo
            echo "Recent Errors (last 5 minutes):"
            ERROR_COUNT=$(sudo journalctl -u cyprine-backend --since "5 minutes ago" | grep -i "error\|critical\|fatal" | wc -l)
            if [ $ERROR_COUNT -gt 0 ]; then
                echo "  ⚠️  $ERROR_COUNT error(s) found"
            else
                echo "  ✅ No errors"
            fi
            
            sleep 5
        done
EOF
}

ssh_connect() {
    log "Connecting via SSH..."
    get_instance_info
    
    cd "$TERRAFORM_DIR"
    SSH_CMD=$(terraform output -raw ssh_connection_command 2>/dev/null)
    
    log "Executing: $SSH_CMD"
    eval $SSH_CMD
}

# Main execution
COMMAND="$1"

if [ -z "$COMMAND" ]; then
    show_interactive_menu
    exit 0
fi

case "$COMMAND" in
    status)
        show_status
        ;;
    start)
        start_instance
        ;;
    stop)
        stop_instance
        ;;
    restart)
        restart_instance
        ;;
    reboot)
        reboot_instance
        ;;
    logs)
        show_logs
        ;;
    health)
        health_check
        ;;
    monitor)
        monitor_resources
        ;;
    connect|ssh)
        ssh_connect
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac