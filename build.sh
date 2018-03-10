#!/bin/bash

set -e 
set -x

CERTIFICATE_VALIDITY=${1:-365}
SUBJECT=${2:-"/C=FR/O=krkr/OU=Domain Control Validated/CN=*.conas.io"}

# Generate ssl certificate
function certificate() {
    # Generate a passphrase
    openssl rand -base64 48 > passphrase.txt

    # Generate a Private Key
    openssl genrsa -aes128 -passout file:passphrase.txt -out server.key 2048

    # Generate a CSR (Certificate Signing Request)
    openssl req -new -passin file:passphrase.txt -key server.key -out server.csr \
                -subj $1

    # Remove Passphrase from Key
    cp server.key server.key.org
    openssl rsa -in server.key.org -passin file:passphrase.txt -out server.key

    # Generating a Self-Signed Certificate for 100 years
    openssl x509 -req -days $CERTIFICATE_VALIDITY -in server.csr -signkey server.key -out server.crt

    mkdir -p nginx/cert
    mv server.crt nginx/cert/ssl.crt
    mv server.key nginx/cert/ssl.key

    rm passphrase.txt server.csr server.key.org
}

certificate $SUBJECT

if hash docker-compose 2>/dev/null; then    
    docker-compose build
else
    echo "docker-compose not installed"
    exit 1
fi
