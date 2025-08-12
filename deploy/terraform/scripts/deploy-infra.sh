#!/bin/bash
set -e

# Cyprine Heroes Infrastructure Deployment Script
# Based on mbot-infra patterns with enhancements

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="cyprine-heroes"

# Default environment
ENVIRONMENT="${ENVIRONMENT:-prod}"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/environments/$ENVIRONMENT"

# Colors for output
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

show_help() {
    cat << EOF
Cyprine Heroes Infrastructure Deployment

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    init        Initialize Terraform (first time setup)
    plan        Show what will be created/changed
    apply       Deploy the infrastructure
    destroy     Destroy all infrastructure (DANGEROUS)
    output      Show deployment outputs
    ssh         SSH into the instance
    status      Show instance status
    help        Show this help

Options:
    -y, --yes   Auto-approve (skip confirmations)
    -v, --var-file FILE  Use custom tfvars file
    -e, --env ENV        Target environment (default: prod)

Examples:
    $0 init                    # First time setup (prod)
    $0 plan                    # Preview changes (prod)
    $0 apply                   # Deploy infrastructure (prod)
    $0 output                  # Show connection info (prod)
    $0 ssh                     # Connect to instance (prod)
    $0 status                  # Check instance status (prod)
    
    # Multi-environment examples:
    ENVIRONMENT=staging $0 apply    # Deploy to staging
    $0 --env dev plan               # Plan for dev environment

Prerequisites:
    1. AWS CLI configured (aws configure)
    2. Terraform installed (>= 1.0)
    3. SSH key pair created in AWS
    4. terraform.tfvars file configured

Setup:
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars with your values
    $0 init
    $0 apply
EOF
}

check_prerequisites() {
    log "Checking prerequisites for environment: $ENVIRONMENT..."
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &>/dev/null; then
        error "AWS CLI not configured. Run: aws configure"
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &>/dev/null; then
        error "Terraform not installed. Install from: https://www.terraform.io/downloads.html"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "$TERRAFORM_DIR/main.tf" ]; then
        error "Terraform configuration not found at $TERRAFORM_DIR"
        exit 1
    fi
    
    # Check if tfvars exists
    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        warning "terraform.tfvars not found"
        echo "Copy terraform.tfvars.example to terraform.tfvars and configure your values:"
        echo "  cd $TERRAFORM_DIR"
        echo "  cp terraform.tfvars.example terraform.tfvars"
        echo "  # Edit terraform.tfvars with your values"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

terraform_init() {
    log "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    terraform init
    success "Terraform initialized"
}

terraform_plan() {
    log "Planning Terraform deployment..."
    cd "$TERRAFORM_DIR"
    terraform plan ${VAR_FILE:+-var-file="$VAR_FILE"}
}

terraform_apply() {
    log "Applying Terraform configuration..."
    cd "$TERRAFORM_DIR"
    
    if [ "$AUTO_APPROVE" = "true" ]; then
        terraform apply -auto-approve ${VAR_FILE:+-var-file="$VAR_FILE"}
    else
        terraform apply ${VAR_FILE:+-var-file="$VAR_FILE"}
    fi
    
    if [ $? -eq 0 ]; then
        success "Infrastructure deployed successfully!"
        echo
        log "Getting deployment information..."
        terraform output deployment_info
        echo
        warning "IMPORTANT: Application setup is running in the background."
        warning "It may take 3-5 minutes for the application to be fully ready."
        echo
        log "To check setup progress:"
        echo "  $0 ssh"
        echo "  sudo tail -f /var/log/cyprine-setup.log"
        echo
        log "To check application status:"
        echo "  $0 status"
    fi
}

terraform_destroy() {
    error "⚠️  WARNING: This will destroy ALL infrastructure!"
    echo "This action cannot be undone."
    echo
    
    if [ "$AUTO_APPROVE" != "true" ]; then
        read -p "Are you sure you want to destroy everything? (type 'yes' to confirm): " confirm
        if [ "$confirm" != "yes" ]; then
            log "Destruction cancelled"
            exit 0
        fi
    fi
    
    log "Destroying infrastructure..."
    cd "$TERRAFORM_DIR"
    terraform destroy ${AUTO_APPROVE:+-auto-approve} ${VAR_FILE:+-var-file="$VAR_FILE"}
}

show_outputs() {
    log "Deployment outputs:"
    cd "$TERRAFORM_DIR"
    terraform output
}

ssh_to_instance() {
    log "Connecting to instance..."
    cd "$TERRAFORM_DIR"
    
    ELASTIC_IP=$(terraform output -raw elastic_ip 2>/dev/null)
    KEY_NAME=$(terraform output -raw ssh_connection_command 2>/dev/null | grep -o "\.ssh/[^.]*" | cut -d'/' -f2)
    
    if [ -z "$ELASTIC_IP" ]; then
        error "Could not get instance IP. Is infrastructure deployed?"
        exit 1
    fi
    
    log "Connecting to $ELASTIC_IP..."
    ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@$ELASTIC_IP
}

show_status() {
    log "Checking instance status..."
    cd "$TERRAFORM_DIR"
    
    INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null)
    ELASTIC_IP=$(terraform output -raw elastic_ip 2>/dev/null)
    
    if [ -z "$INSTANCE_ID" ]; then
        error "Could not get instance information. Is infrastructure deployed?"
        exit 1
    fi
    
    # AWS instance status
    aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --query 'InstanceStatuses[0].[InstanceState.Name,SystemStatus.Status,InstanceStatus.Status]' --output text
    
    # Application health check
    log "Checking application health..."
    if curl -f -s "http://$ELASTIC_IP" >/dev/null 2>&1; then
        success "Application is responding"
    else
        warning "Application might still be starting up"
        log "Check setup progress with: $0 ssh -> sudo tail -f /var/log/cyprine-setup.log"
    fi
    
    log "Application URL: http://$ELASTIC_IP"
}

# Parse command line arguments
AUTO_APPROVE=false
VAR_FILE=""
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        init|plan|apply|destroy|output|ssh|status|help)
            COMMAND="$1"
            shift
            ;;
        -y|--yes)
            AUTO_APPROVE=true
            shift
            ;;
        -v|--var-file)
            VAR_FILE="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/environments/$ENVIRONMENT"
            shift 2
            ;;
        -h|--help)
            COMMAND="help"
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Default command
if [ -z "$COMMAND" ]; then
    COMMAND="help"
fi

# Execute command
case "$COMMAND" in
    init)
        check_prerequisites
        terraform_init
        ;;
    plan)
        check_prerequisites
        terraform_plan
        ;;
    apply)
        check_prerequisites
        terraform_apply
        ;;
    destroy)
        check_prerequisites
        terraform_destroy
        ;;
    output)
        show_outputs
        ;;
    ssh)
        ssh_to_instance
        ;;
    status)
        show_status
        ;;
    help)
        show_help
        ;;
    *)
        error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac