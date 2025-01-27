#!/bin/bash

# setting for elasticsearch
sudo sysctl -w vm.max_map_count=1048575

# Check and create Docker network socarium-network if it doesn't exist
if sudo docker network ls | grep "socarium-network"; then
    echo "Docker network 'socarium-network' already exists. Skipping creation."
else
    echo "Creating Docker network 'socarium-network'..."
    sudo docker network create socarium-network
fi

sudo cp .env.sample .env

# Append configuration to .env
cat << EOF | sudo tee -a .env
OPENCTI_ADMIN_EMAIL=admin@opencti.io
OPENCTI_ADMIN_PASSWORD=ChangeMePlease
OPENCTI_ADMIN_TOKEN=$(cat /proc/sys/kernel/random/uuid)
OPENCTI_BASE_URL=http://103.82.92.195:8282
MINIO_ROOT_USER=$(cat /proc/sys/kernel/random/uuid)
MINIO_ROOT_PASSWORD=$(cat /proc/sys/kernel/random/uuid)
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
ELASTIC_MEMORY_SIZE=4G
CONNECTOR_HISTORY_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_EXPORT_FILE_STIX_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_EXPORT_FILE_CSV_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_IMPORT_FILE_STIX_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_EXPORT_FILE_TXT_ID=$(cat /proc/sys/kernel/random/uuid)
CONNECTOR_IMPORT_DOCUMENT_ID=$(cat /proc/sys/kernel/random/uuid)
SMTP_HOSTNAME=localhost
EOF


# running openCTI Container
sudo docker-compose up -d