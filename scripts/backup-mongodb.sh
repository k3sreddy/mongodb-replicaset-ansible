#!/bin/bash
# MongoDB Backup Script
# Automated backup script for MongoDB replica set

set -e

# Configuration
BACKUP_DIR="/var/backups/mongodb"
RETENTION_DAYS=30
MONGO_USER="admin"
MONGO_PASS="abcd123."
MONGO_AUTH_DB="admin"
REPLICA_SET="rs0"
HOSTS="172.16.90.163:27017,172.16.90.164:27017,172.16.90.165:27017"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mongodb_backup_$DATE"
LOG_FILE="/var/log/mongodb_backup.log"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Create backup directory
mkdir -p $BACKUP_DIR

log "Starting MongoDB backup: $BACKUP_NAME"

# Check MongoDB connection
log "Testing MongoDB connection..."
mongosh "mongodb://$MONGO_USER:$MONGO_PASS@$HOSTS/$MONGO_AUTH_DB?replicaSet=$REPLICA_SET&authSource=$MONGO_AUTH_DB" --eval "db.adminCommand('ping')" --quiet

if [ $? -ne 0 ]; then
    log "ERROR: Unable to connect to MongoDB"
    exit 1
fi

# Create backup using mongodump
log "Creating backup with mongodump..."
mongodump \
    --uri "mongodb://$MONGO_USER:$MONGO_PASS@$HOSTS/$MONGO_AUTH_DB?replicaSet=$REPLICA_SET&authSource=$MONGO_AUTH_DB" \
    --out "$BACKUP_DIR/$BACKUP_NAME" \
    --oplog

if [ $? -eq 0 ]; then
    log "Backup created successfully: $BACKUP_DIR/$BACKUP_NAME"

    # Compress backup
    log "Compressing backup..."
    cd $BACKUP_DIR
    tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
    rm -rf "$BACKUP_NAME"

    log "Backup compressed: $BACKUP_NAME.tar.gz"

    # Remove old backups
    log "Removing backups older than $RETENTION_DAYS days..."
    find $BACKUP_DIR -name "mongodb_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

    log "Backup process completed successfully"
else
    log "ERROR: Backup failed"
    exit 1
fi

# Optional: Upload to cloud storage (uncomment and configure as needed)
# log "Uploading backup to cloud storage..."
# aws s3 cp "$BACKUP_DIR/$BACKUP_NAME.tar.gz" s3://your-backup-bucket/mongodb/

log "Backup process finished"
