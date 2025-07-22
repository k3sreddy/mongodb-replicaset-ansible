# MongoDB Replica Set Deployment with Ansible

This project automates the deployment of a secure MongoDB replica set on Rocky Linux 9.4 using Ansible. It includes comprehensive security features including TLS/SSL encryption for data in transit and keyfile authentication for replica set members.

## Features

- **Automated MongoDB 8.0 Installation**: Latest MongoDB Community Edition
- **Replica Set Configuration**: 3-node replica set for high availability
- **Data Security**: 
  - TLS/SSL encryption for data in transit
  - Keyfile authentication for internal communication
  - User authentication with SCRAM-SHA-256
- **Firewall Configuration**: UFW/firewalld rules for secure access
- **Production Ready**: Optimized configuration for production environments
- **Backup Scripts**: Automated backup and monitoring scripts

## Requirements

- Ansible 2.9+ installed on control node
- Rocky Linux 9.4 target hosts
- Root access to target hosts
- Python 3.6+ on target hosts
- Minimum 4GB RAM and 20GB disk space per node

## Target Infrastructure

- **Host 1**: 172.16.90.163 (Primary candidate)
- **Host 2**: 172.16.90.164 (Secondary)
- **Host 3**: 172.16.90.165 (Secondary)
- **MongoDB Version**: 8.0 (latest)
- **Operating System**: Rocky Linux 9.4

## Quick Start

1. **Install Ansible Collections**:
   ```bash
   ansible-galaxy install -r requirements.yml
   ```

2. **Configure Inventory**:
   Update `inventory/hosts.yml` with your server details

3. **Deploy MongoDB Cluster**:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/site.yml
   ```

## Detailed Usage

### 1. Install Dependencies
```bash
# Install required Ansible collections
ansible-galaxy collection install community.mongodb
ansible-galaxy collection install community.general
```

### 2. Configure Variables
Edit the following files as needed:
- `inventory/group_vars/all.yml` - Global settings
- `inventory/group_vars/mongodb.yml` - MongoDB specific settings
- `inventory/host_vars/*.yml` - Host specific settings

### 3. Run Playbooks

**Complete deployment**:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

**Step-by-step deployment**:
```bash
# Install MongoDB
ansible-playbook -i inventory/hosts.yml playbooks/install-mongodb.yml

# Configure security
ansible-playbook -i inventory/hosts.yml playbooks/configure-security.yml

# Setup replica set
ansible-playbook -i inventory/hosts.yml playbooks/setup-replicaset.yml
```

## Security Features

### TLS/SSL Configuration
- Self-signed CA certificate generation
- Server certificates for each node
- Client certificate authentication
- TLS 1.2+ encryption

### Authentication
- MongoDB admin user: `admin` (password: `abcd123.`)
- SCRAM-SHA-256 authentication mechanism
- Keyfile authentication for replica set members

### Network Security
- Firewall rules to allow only necessary ports
- Bind to specific network interfaces
- IP-based access control

## Monitoring and Maintenance

### Backup Script
```bash
# Run backup script
./scripts/backup-mongodb.sh
```

### Monitoring Script
```bash
# Check cluster status
./scripts/monitoring.sh
```

### Connection Examples

**Connect using MongoDB Shell**:
```bash
# With TLS
mongosh "mongodb://admin:abcd123.@172.16.90.163:27017/?authSource=admin&tls=true&tlsCAFile=/etc/ssl/mongodb/ca.pem"

# Replica set connection
mongosh "mongodb://admin:abcd123.@172.16.90.163:27017,172.16.90.164:27017,172.16.90.165:27017/?authSource=admin&replicaSet=rs0&tls=true&tlsCAFile=/etc/ssl/mongodb/ca.pem"
```

## Project Structure

```
mongodb-replicaset-ansible/
├── inventory/                 # Inventory and variables
│   ├── hosts.yml             # Host definitions
│   ├── group_vars/           # Group variables
│   └── host_vars/            # Host-specific variables
├── roles/                    # Ansible roles
│   ├── common/               # Common system tasks
│   ├── mongodb-install/      # MongoDB installation
│   ├── mongodb-security/     # Security configuration
│   └── mongodb-replicaset/   # Replica set setup
├── playbooks/                # Main playbooks
├── scripts/                  # Utility scripts
└── README.md                 # This file
```

## Troubleshooting

### Common Issues

1. **Connection Refused**: Check firewall settings and MongoDB bind configuration
2. **Authentication Failed**: Verify user credentials and authentication database
3. **Replica Set Issues**: Check network connectivity between nodes
4. **Certificate Errors**: Ensure certificates are properly generated and placed

### Logs
- MongoDB logs: `/var/log/mongodb/mongod.log`
- System logs: `journalctl -u mongod`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review MongoDB and Ansible documentation
3. Open an issue in the repository

---

**Note**: This configuration is optimized for production use but should be reviewed and tested in your specific environment before deployment.
