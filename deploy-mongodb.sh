#!/bin/bash
# MongoDB Replica Set Deployment Script
# Quick deployment wrapper for the Ansible MongoDB project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="mongodb-replicaset-ansible"
MONGODB_HOSTS=("172.16.90.163" "172.16.90.164" "172.16.90.165")
PRIMARY_HOST="172.16.90.164"
ADMIN_USER="admin"
ADMIN_PASS="abcd123."

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}MongoDB Replica Set Deployment with Ansible${NC}"
echo -e "${BLUE}============================================${NC}"
echo

# Function to print status
print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in project directory
if [ ! -f "ansible.cfg" ] || [ ! -d "roles" ]; then
    print_error "Please run this script from the $PROJECT_NAME directory"
    exit 1
fi

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check Ansible installation
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed. Please install Ansible 2.9 or later."
        exit 1
    fi

    # Check Ansible version
    ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f2)
    print_success "Ansible version: $ANSIBLE_VERSION"

    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed."
        exit 1
    fi

    print_success "Python version: $(python3 --version)"

    # Check SSH key
    if [ ! -f ~/.ssh/id_rsa ]; then
        print_error "SSH key not found. Please generate an SSH key pair:"
        echo "ssh-keygen -t rsa -b 4096 -C 'your_email@example.com'"
        exit 1
    fi

    print_success "Prerequisites check completed"
    echo
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Ansible collections..."

    if ansible-galaxy install -r requirements.yml; then
        print_success "Ansible collections installed successfully"
    else
        print_error "Failed to install Ansible collections"
        exit 1
    fi
    echo
}

# Function to test connectivity
test_connectivity() {
    print_status "Testing connectivity to MongoDB hosts..."

    for host in "${MONGODB_HOSTS[@]}"; do
        echo -n "Testing $host: "
        if ansible -i inventory/hosts.yml -m ping "$host" &> /dev/null; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAILED${NC}"
            print_error "Cannot connect to $host. Please check:"
            echo "  1. Host is reachable via SSH"
            echo "  2. SSH key is configured"
            echo "  3. Root access is available"
            exit 1
        fi
    done

    print_success "All hosts are reachable"
    echo
}

# Function to deploy MongoDB
deploy_mongodb() {
    print_status "Starting MongoDB replica set deployment..."
    echo

    print_status "Phase 1: System preparation and MongoDB installation..."
    if ansible-playbook -i inventory/hosts.yml playbooks/install-mongodb.yml; then
        print_success "MongoDB installation completed"
    else
        print_error "MongoDB installation failed"
        exit 1
    fi
    echo

    print_status "Phase 2: Security configuration (TLS/SSL + Authentication)..."
    if ansible-playbook -i inventory/hosts.yml playbooks/configure-security.yml; then
        print_success "Security configuration completed"
    else
        print_error "Security configuration failed"
        exit 1
    fi
    echo

    print_status "Phase 3: Replica set initialization..."
    if ansible-playbook -i inventory/hosts.yml playbooks/setup-replicaset.yml; then
        print_success "Replica set setup completed"
    else
        print_error "Replica set setup failed"
        exit 1
    fi
    echo
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying MongoDB deployment..."

    # Wait for services to stabilize
    sleep 10

    if [ -x "./scripts/monitoring.sh" ]; then
        print_status "Running health check script..."
        if ./scripts/monitoring.sh; then
            print_success "Health check completed"
        else
            print_error "Health check failed - please check MongoDB status manually"
        fi
    else
        print_status "Manual verification required:"
        echo "  mongosh \"mongodb://$ADMIN_USER:$ADMIN_PASS@$PRIMARY_HOST:27017/?authSource=admin\" --eval \"rs.status()\""
    fi
    echo
}

# Function to display connection information
display_connection_info() {
    print_success "MongoDB Replica Set Deployment Completed!"
    echo
    echo -e "${BLUE}Connection Information:${NC}"
    echo "  Primary Node: $PRIMARY_HOST"
    echo "  Replica Set: rs0"
    echo "  Admin User: $ADMIN_USER"
    echo "  Admin Password: $ADMIN_PASS"
    echo
    echo -e "${BLUE}Connection Examples:${NC}"
    echo
    echo "1. Primary connection:"
    echo "   mongosh \"mongodb://$ADMIN_USER:$ADMIN_PASS@$PRIMARY_HOST:27017/?authSource=admin\""
    echo
    echo "2. Replica set connection:"
    echo "   mongosh \"mongodb://$ADMIN_USER:$ADMIN_PASS@${MONGODB_HOSTS[0]}:27017,${MONGODB_HOSTS[1]}:27017,${MONGODB_HOSTS[2]}:27017/?authSource=admin&replicaSet=rs0\""
    echo
    echo "3. Secure TLS connection:"
    echo "   mongosh \"mongodb://$ADMIN_USER:$ADMIN_PASS@$PRIMARY_HOST:27017/?authSource=admin&tls=true&tlsCAFile=/etc/ssl/mongodb/ca.pem\""
    echo
    echo -e "${BLUE}Maintenance Commands:${NC}"
    echo "  Health Check: ./scripts/monitoring.sh"
    echo "  Backup: ./scripts/backup-mongodb.sh"
    echo "  Certificate Renewal: ./scripts/generate-certs.sh"
    echo
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "  - Change the default admin password in production"
    echo "  - Replace self-signed certificates with CA-signed certificates"
    echo "  - Set up regular backups and monitoring"
    echo "  - Review firewall and network security settings"
    echo
}

# Main deployment function
main() {
    echo "This script will deploy a secure MongoDB replica set with the following configuration:"
    echo "  - MongoDB 8.0 (Latest Community Edition)"
    echo "  - 3-node replica set on Rocky Linux 9.4"
    echo "  - Primary: $PRIMARY_HOST"
    echo "  - Secondaries: ${MONGODB_HOSTS[0]}, ${MONGODB_HOSTS[2]}"
    echo "  - TLS/SSL encryption enabled"
    echo "  - Authentication with admin user"
    echo

    read -p "Do you want to continue with the deployment? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled by user"
        exit 0
    fi

    echo
    check_prerequisites
    install_dependencies
    test_connectivity
    deploy_mongodb
    verify_deployment
    display_connection_info
}

# Handle command line arguments
case "${1:-}" in
    --check)
        check_prerequisites
        test_connectivity
        ;;
    --install-deps)
        install_dependencies
        ;;
    --deploy)
        deploy_mongodb
        ;;
    --verify)
        verify_deployment
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --check       Check prerequisites and connectivity only"
        echo "  --install-deps Install Ansible dependencies only"
        echo "  --deploy      Run deployment only (skip checks)"
        echo "  --verify      Run verification only"
        echo "  --help        Show this help message"
        echo
        echo "Without options, runs complete deployment process"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
