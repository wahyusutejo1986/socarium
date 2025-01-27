#!/bin/bash

# Function to check container status
check_container_status() {
    container_name=$1
    status=$(sudo docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || echo "not_found")
    echo "$status"
}

# Ensure misp-docker-misp-core-1 is running
MISP_CONTAINER_NAME="misp-docker-misp-core-1"
MISP_STATUS=$(check_container_status "$MISP_CONTAINER_NAME")

if [ "$MISP_STATUS" != "running" ]; then
    echo "Container $MISP_CONTAINER_NAME is not running (status: $MISP_STATUS). Attempting to start it..."
    sudo docker start "$MISP_CONTAINER_NAME"
    sleep 5
    MISP_STATUS=$(check_container_status "$MISP_CONTAINER_NAME")
    if [ "$MISP_STATUS" != "running" ]; then
        echo "Failed to start $MISP_CONTAINER_NAME. Please check the container logs for details."
        exit 1
    fi
fi

# Ensure misp-docker-db-1 is running
DB_CONTAINER_NAME="misp-docker-db-1"
DB_STATUS=$(check_container_status "$DB_CONTAINER_NAME")

if [ "$DB_STATUS" != "running" ]; then
    echo "Container $DB_CONTAINER_NAME is not running (status: $DB_STATUS). Attempting to start it..."
    sudo docker start "$DB_CONTAINER_NAME"
    sleep 5
    DB_STATUS=$(check_container_status "$DB_CONTAINER_NAME")
    if [ "$DB_STATUS" != "running" ]; then
        echo "Failed to start $DB_CONTAINER_NAME. Please check the container logs for details."
        exit 1
    fi
fi

# Step 1: Check .env file for BASE_URL
ENV_FILE="/tmp/socarium/misp-docker/.env"
if [ -f "$ENV_FILE" ]; then
    BASE_URL_VALUE=$(grep -E '^BASE_URL=' "$ENV_FILE" | cut -d'=' -f2)
    if [ "$BASE_URL_VALUE" = "https://your ip or domain:10443" ]; then
        echo "The BASE_URL in .env is still set to the default: $BASE_URL_VALUE. Please update it manually to the correct IP or domain."
        exit 1
    fi
else
    echo "The .env file was not found at $ENV_FILE. Please ensure it exists and try again."
    exit 1
fi

# Step 2: Display database configuration files
sudo docker exec -it misp-docker-misp-core-1 cat /var/www/MISP/app/Config/database.php
sudo docker exec -it misp-docker-misp-core-1 cat /var/www/MISP/app/Config/database.default.php
sudo docker exec -it misp-docker-misp-core-1 cat /var/www/MISP/app/Config.dist/database.default.php

# Step 3: Find files in Config and Config.dist directories
sudo docker exec -it misp-docker-misp-core-1 bash -c "ls -la /var/www/MISP/app/Config/"
sudo docker exec -it misp-docker-misp-core-1 bash -c "ls -la /var/www/MISP/app/Config.dist/"

# Step 4: Copy all files from Config.dist to Config
sudo docker exec -it misp-docker-misp-core-1 bash -c "cp -r /var/www/MISP/app/Config.dist/* /var/www/MISP/app/Config/"

# Step 5: Change ownership of files to www-data
sudo docker exec -it misp-docker-misp-core-1 bash -c "chown -R www-data:www-data /var/www/MISP/app/Config/*"

# Step 6: Retrieve the IP address of the misp-docker-db-1 container
DB_CONTAINER_IP=$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$DB_CONTAINER_NAME")

# Update MySQL host in database.default.php
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "echo \"<?php class DATABASE_CONFIG { public \\\$default = [ 'datasource' => 'Database/MysqlObserverExtended', 'persistent' => false, 'host' => '$DB_CONTAINER_IP', 'login' => 'misp', 'port' => 3306, 'password' => 'socarium2024', 'database' => 'misp', 'prefix' => '', 'encoding' => 'utf8', 'flags' => [ PDO::ATTR_STRINGIFY_FETCHES => true ] ]; }\" > /var/www/MISP/app/Config.dist/database.default.php"

# Restart nginx
sudo docker exec -it "$MISP_CONTAINER_NAME" service nginx restart

# Copy additional configuration files
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "cp -r /var/www/MISP/app/Config.dist/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.default.php"
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "cp -r /var/www/MISP/app/Config.dist/config.default.php /var/www/MISP/app/Config/config.default.php"
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "cp -r /var/www/MISP/app/Config.dist/core.default.php /var/www/MISP/app/Config/core.default.php"
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "cp -r /var/www/MISP/app/Config.dist/email.php /var/www/MISP/app/Config/email.php"
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "cp -r /var/www/MISP/app/Config.dist/routes.php /var/www/MISP/app/Config/routes.php"

# Set up nginx configuration
sudo docker cp ./modules/misp/nginx/misp "$MISP_CONTAINER_NAME:/etc/nginx/sites-available/misp"
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "ln -s /etc/nginx/sites-available/misp /etc/nginx/sites-enabled/misp"
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "mkdir -p /etc/ssl/certs /etc/ssl/private"
sudo docker exec -it "$MISP_CONTAINER_NAME" bash -c "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/misp.key -out /etc/ssl/certs/misp.crt -subj '/CN=localhost'"

# Restart MISP Docker environment
cd /tmp/socarium/misp-docker || exit
docker-compose down -v
sudo docker-compose restart
