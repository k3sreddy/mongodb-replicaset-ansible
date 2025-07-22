#!/bin/bash
# MongoDB SSL Certificate Generation Script
# This script generates SSL certificates for MongoDB cluster

set -e

# Configuration
CERT_DIR="/etc/ssl/mongodb"
CA_KEY="$CERT_DIR/ca-key.pem"
CA_CERT="$CERT_DIR/ca.pem"
DAYS_VALID=3650
KEY_SIZE=4096

# Create certificate directory
mkdir -p $CERT_DIR
cd $CERT_DIR

echo "Generating MongoDB SSL Certificates..."

# Generate CA private key
echo "1. Generating CA private key..."
openssl genpkey -algorithm RSA -out $CA_KEY -pkcs8 -aes256

# Generate CA certificate
echo "2. Generating CA certificate..."
openssl req -new -x509 -key $CA_KEY -out $CA_CERT -days $DAYS_VALID -subj "/C=US/ST=State/L=City/O=Organization/CN=MongoDB CA"

# Generate server certificates for each MongoDB node
HOSTS=("172.16.90.163" "172.16.90.164" "172.16.90.165")
HOSTNAMES=("mongodb1" "mongodb2" "mongodb3")

for i in "${!HOSTS[@]}"; do
    HOST="${HOSTS[$i]}"
    HOSTNAME="${HOSTNAMES[$i]}"

    echo "3. Generating certificate for $HOSTNAME ($HOST)..."

    # Generate server private key
    openssl genpkey -algorithm RSA -out "${HOSTNAME}-key.pem" -pkcs8

    # Generate server certificate request
    openssl req -new -key "${HOSTNAME}-key.pem" -out "${HOSTNAME}.csr" -subj "/C=US/ST=State/L=City/O=Organization/CN=$HOSTNAME"

    # Create extensions file
    cat > "${HOSTNAME}.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $HOSTNAME
DNS.2 = localhost
IP.1 = $HOST
IP.2 = 127.0.0.1
EOF

    # Generate server certificate
    openssl x509 -req -in "${HOSTNAME}.csr" -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out "${HOSTNAME}-cert.pem" -days $DAYS_VALID -extensions v3_req -extfile "${HOSTNAME}.ext"

    # Combine key and certificate
    cat "${HOSTNAME}-key.pem" "${HOSTNAME}-cert.pem" > "${HOSTNAME}.pem"

    # Set proper permissions
    chmod 600 "${HOSTNAME}-key.pem" "${HOSTNAME}.pem"
    chmod 644 "${HOSTNAME}-cert.pem"

    # Cleanup
    rm "${HOSTNAME}.csr" "${HOSTNAME}.ext"
done

# Generate client certificate
echo "4. Generating client certificate..."
openssl genpkey -algorithm RSA -out client-key.pem -pkcs8
openssl req -new -key client-key.pem -out client.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=MongoDB Client"
openssl x509 -req -in client.csr -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out client-cert.pem -days $DAYS_VALID
cat client-key.pem client-cert.pem > client.pem

# Set permissions
chmod 600 client-key.pem client.pem
chmod 644 client-cert.pem ca.pem

# Cleanup
rm client.csr ca.srl

echo "SSL certificates generated successfully in $CERT_DIR"
echo "CA Certificate: $CA_CERT"
echo "Server Certificates: mongodb1.pem, mongodb2.pem, mongodb3.pem"
echo "Client Certificate: client.pem"
