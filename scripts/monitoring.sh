#!/bin/bash
# MongoDB Monitoring Script
# Checks the health and status of MongoDB replica set

# Configuration
MONGO_USER="admin"
MONGO_PASS="abcd123."
MONGO_AUTH_DB="admin"
REPLICA_SET="rs0"
HOSTS=("172.16.90.163:27017" "172.16.90.164:27017" "172.16.90.165:27017")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

echo "============================================"
echo "MongoDB Replica Set Health Check"
echo "============================================"
echo

# Check individual host connectivity
log "${YELLOW}Checking individual host connectivity...${NC}"
for host in "${HOSTS[@]}"; do
    echo -n "Testing $host: "
    if mongosh "mongodb://$MONGO_USER:$MONGO_PASS@$host/$MONGO_AUTH_DB?authSource=$MONGO_AUTH_DB" --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
    fi
done

echo

# Check replica set status
log "${YELLOW}Checking replica set status...${NC}"
RS_STATUS=$(mongosh "mongodb://$MONGO_USER:$MONGO_PASS@${HOSTS[0]}/$MONGO_AUTH_DB?authSource=$MONGO_AUTH_DB" --eval "
    var status = rs.status();
    print('Replica Set: ' + status.set);
    print('Date: ' + status.date);
    print('My State: ' + status.myState);
    print('');
    print('Members:');
    status.members.forEach(function(member) {
        print('  ' + member.name + ' - ' + member.stateStr + ' (health: ' + member.health + ')');
        if (member.stateStr === 'PRIMARY') {
            print('    PRIMARY NODE');
        }
    });
" --quiet 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Replica set is accessible${NC}"
    echo "$RS_STATUS"
else
    echo -e "${RED}Failed to get replica set status${NC}"
fi

echo

# Check database statistics
log "${YELLOW}Database statistics...${NC}"
DB_STATS=$(mongosh "mongodb://$MONGO_USER:$MONGO_PASS@${HOSTS[0]}/$MONGO_AUTH_DB?authSource=$MONGO_AUTH_DB" --eval "
    var stats = db.serverStatus();
    print('MongoDB Version: ' + stats.version);
    print('Uptime: ' + Math.floor(stats.uptime / 3600) + ' hours');
    print('Current Connections: ' + stats.connections.current + '/' + stats.connections.available);
    print('Memory Usage: ' + Math.round(stats.mem.resident) + ' MB resident, ' + Math.round(stats.mem.virtual) + ' MB virtual');
    print('Network: ' + stats.network.bytesIn + ' bytes in, ' + stats.network.bytesOut + ' bytes out');
" --quiet 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "$DB_STATS"
else
    echo -e "${RED}Failed to get database statistics${NC}"
fi

echo

# Check replication lag
log "${YELLOW}Checking replication lag...${NC}"
REP_LAG=$(mongosh "mongodb://$MONGO_USER:$MONGO_PASS@${HOSTS[0]}/$MONGO_AUTH_DB?authSource=$MONGO_AUTH_DB" --eval "rs.printSecondaryReplicationInfo()" --quiet 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "$REP_LAG"
else
    echo -e "${RED}Failed to get replication information${NC}"
fi

echo

# Check disk space
log "${YELLOW}Checking disk space on local system...${NC}"
df -h /var/lib/mongo | tail -1 | awk '{print "MongoDB Data Directory: " $5 " used (" $3 "/" $2 ")"}'
df -h /var/log/mongodb | tail -1 | awk '{print "MongoDB Log Directory: " $5 " used (" $3 "/" $2 ")"}'

echo

# Summary
log "${YELLOW}Health Check Summary${NC}"
echo "- Replica set connectivity: $(mongosh "mongodb://$MONGO_USER:$MONGO_PASS@${HOSTS[0]}/$MONGO_AUTH_DB?authSource=$MONGO_AUTH_DB" --eval "print('OK')" --quiet 2>/dev/null || echo 'FAILED')"
echo "- Authentication: $(mongosh "mongodb://$MONGO_USER:$MONGO_PASS@${HOSTS[0]}/$MONGO_AUTH_DB?authSource=$MONGO_AUTH_DB" --eval "db.runCommand({listUsers: 1})" --quiet > /dev/null 2>&1 && echo 'OK' || echo 'FAILED')"

echo
echo "============================================"
echo "Health check completed at $(date)"
echo "============================================"
