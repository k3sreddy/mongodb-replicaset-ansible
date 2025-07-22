# MongoDB Replica Set Deployment Guide

## Prerequisites Checklist

Before running the Ansible playbooks, ensure the following requirements are met:

### Control Node (Ansible Host)
- [ ] Ansible 2.9+ installed
- [ ] Python 3.6+ installed
- [ ] SSH key pair generated (`ssh-keygen -t rsa`)
- [ ] SSH access to all target hosts configured

### Target Hosts (MongoDB Servers)
- [ ] Rocky Linux 9.4 installed and updated
- [ ] Root access or sudo privileges
- [ ] Minimum 4GB RAM per node
- [ ] Minimum 20GB disk space per node
- [ ] Network connectivity between all nodes
- [ ] Firewall configured (will be automated)

### Network Requirements
- [ ] Port 27017 accessible between MongoDB nodes
- [ ] SSH port (22) accessible from control node
- [ ] DNS resolution or /etc/hosts entries for hostnames

## Quick Start Deployment

### 1. Install Ansible Collections
```bash
cd mongodb-replicaset-ansible
ansible-galaxy install -r requirements.yml
```

### 2. Test Connectivity
```bash
ansible -i inventory/hosts.yml all -m ping
```

### 3. Deploy MongoDB Cluster
```bash
# Complete deployment (recommended)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Or step-by-step deployment
ansible-playbook -i inventory/hosts.yml playbooks/install-mongodb.yml
ansible-playbook -i inventory/hosts.yml playbooks/configure-security.yml
ansible-playbook -i inventory/hosts.yml playbooks/setup-replicaset.yml
```

### 4. Verify Deployment
```bash
# Run monitoring script
./scripts/monitoring.sh

# Or connect manually
mongosh "mongodb://admin:abcd123.@172.16.90.164:27017/?authSource=admin"
```

## Step-by-Step Deployment Process

### Phase 1: System Preparation
```bash
ansible-playbook -i inventory/hosts.yml playbooks/install-mongodb.yml
```

This phase will:
- Update system packages
- Configure firewall rules
- Create MongoDB user and directories
- Install MongoDB 8.0 packages
- Configure system limits
- Generate keyfile for replica set authentication

### Phase 2: Security Configuration
```bash
ansible-playbook -i inventory/hosts.yml playbooks/configure-security.yml
```

This phase will:
- Generate SSL/TLS certificates
- Configure MongoDB for TLS encryption
- Set up authentication
- Update MongoDB configuration files

### Phase 3: Replica Set Initialization
```bash
ansible-playbook -i inventory/hosts.yml playbooks/setup-replicaset.yml
```

This phase will:
- Initialize replica set on primary node (172.16.90.164)
- Add secondary nodes
- Configure replica set priorities
- Create admin user
- Verify replica set status

## Post-Deployment Tasks

### 1. Verify Replica Set Status
```bash
mongosh "mongodb://admin:abcd123.@172.16.90.164:27017/?authSource=admin" --eval "rs.status()"
```

### 2. Create Application Users
```javascript
// Connect to primary and create application users
use myapp
db.createUser({
  user: "appuser",
  pwd: "securepassword",
  roles: [ { role: "readWrite", db: "myapp" } ]
})
```

### 3. Configure Backups
```bash
# Test backup script
./scripts/backup-mongodb.sh

# Add to crontab for automated backups
crontab -e
# Add line: 0 2 * * * /path/to/mongodb-replicaset-ansible/scripts/backup-mongodb.sh
```

### 4. Set up Monitoring
```bash
# Test monitoring script
./scripts/monitoring.sh

# Add to crontab for regular health checks
crontab -e
# Add line: */15 * * * * /path/to/mongodb-replicaset-ansible/scripts/monitoring.sh >> /var/log/mongodb_monitoring.log
```

## Connection Examples

### MongoDB Shell (mongosh)
```bash
# Basic connection to primary
mongosh "mongodb://admin:abcd123.@172.16.90.164:27017/?authSource=admin"

# Replica set connection
mongosh "mongodb://admin:abcd123.@172.16.90.163:27017,172.16.90.164:27017,172.16.90.165:27017/?authSource=admin&replicaSet=rs0"

# With TLS/SSL
mongosh "mongodb://admin:abcd123.@172.16.90.164:27017/?authSource=admin&tls=true&tlsCAFile=/etc/ssl/mongodb/ca.pem"
```

### Application Connection Strings

**Production Connection String (Replica Set with TLS):**
```
mongodb://admin:abcd123.@172.16.90.163:27017,172.16.90.164:27017,172.16.90.165:27017/?authSource=admin&replicaSet=rs0&tls=true&maxPoolSize=10&w=majority&readPreference=secondaryPreferred
```

**Development Connection String (Primary Only):**
```
mongodb://admin:abcd123.@172.16.90.164:27017/?authSource=admin
```

## Troubleshooting

### Common Issues and Solutions

1. **"Authentication failed"**
   - Verify username/password in group_vars/mongodb.yml
   - Check if admin user was created successfully
   - Ensure authSource=admin in connection string

2. **"No replica set members reachable"**
   - Check network connectivity between nodes
   - Verify firewall rules allow port 27017
   - Check MongoDB service status on all nodes

3. **"SSL connection failed"**
   - Verify SSL certificates were generated correctly
   - Check certificate permissions and ownership
   - Ensure TLS is enabled in MongoDB configuration

4. **"Primary election failed"**
   - Wait for replica set to stabilize (up to 30 seconds)
   - Check replica set configuration with rs.conf()
   - Verify node priorities and voting configuration

### Log Files
- MongoDB logs: `/var/log/mongodb/mongod.log`
- System logs: `journalctl -u mongod`
- Deployment logs: `./ansible.log`
- Backup logs: `/var/log/mongodb_backup.log`

### Useful Commands
```bash
# Check MongoDB service status
systemctl status mongod

# View MongoDB logs
tail -f /var/log/mongodb/mongod.log

# Check replica set status
mongosh --eval "rs.status()" "mongodb://admin:abcd123.@172.16.90.164:27017/?authSource=admin"

# Check database sizes
mongosh --eval "db.stats()" "mongodb://admin:abcd123.@172.16.90.164:27017/?authSource=admin"
```

## Security Best Practices

1. **Change Default Password**: Update mongodb_admin_password in group_vars
2. **Certificate Management**: Replace self-signed certificates with CA-signed ones for production
3. **Network Security**: Implement proper firewall rules and VPN access
4. **Regular Updates**: Keep MongoDB and system packages updated
5. **Backup Encryption**: Encrypt backup files before storing
6. **User Management**: Create specific users with minimal required permissions

## Maintenance

### Regular Tasks
- Monitor replica set health
- Check disk space usage
- Verify backup integrity
- Update MongoDB and system packages
- Rotate SSL certificates before expiry

### Scaling
- To add more replica set members, update inventory and run playbook
- For horizontal scaling, consider implementing sharding
- Monitor performance and adjust resource allocation as needed

## Support and Documentation

- MongoDB Official Documentation: https://docs.mongodb.com/
- Ansible MongoDB Collection: https://docs.ansible.com/ansible/latest/collections/community/mongodb/
- Rocky Linux Documentation: https://docs.rockylinux.org/

For issues specific to this deployment, check the troubleshooting section or review the generated log files.
