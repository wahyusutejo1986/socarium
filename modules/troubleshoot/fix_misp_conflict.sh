#!/bin/bash

# Function to check if a port is in use
is_port_in_use() {
    local port=$1
    if lsof -i :$port &>/dev/null; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to find the next available port
find_next_available_port() {
    local start_port=$1
    while is_port_in_use $start_port; do
        start_port=$((start_port + 1))
    done
    echo $start_port
}

# Function to update a key-value pair in the .env file
update_env_var() {
    local env_file=$1
    local key=$2
    local value=$3

    if grep -q "^${key}=" "$env_file"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$env_file"
    else
        echo "${key}=${value}" >> "$env_file"
    fi
}

# Function to fetch the public IP
get_public_ip() {
    echo "🌐 Fetching public IP..."
    curl -s https://api.ipify.org || echo "127.0.0.1"
}

# Function to update BASE_URL dynamically
update_base_url() {
    local env_file=$1
    local public_ip
    public_ip=$(get_public_ip)

    if [[ $public_ip != "127.0.0.1" ]]; then
        echo "🔧 Setting BASE_URL to https://${public_ip}"
        update_env_var "$env_file" "BASE_URL" "https://${public_ip}"
    else
        echo "⚠️ Failed to fetch public IP. Using default BASE_URL=https://localhost"
        update_env_var "$env_file" "BASE_URL" "https://localhost"
    fi
}

# Function to restart MISP services
restart_misp() {
    local compose_file=$1
    echo "🔄 Restarting MISP services..."
    docker-compose -f "$compose_file" down --remove-orphans
    docker-compose -f "$compose_file" up -d
    echo "✅ MISP services restarted successfully."
}

# Main function
fix_misp_only() {
    local env_file="/opt/socarium/MISP/.env"
    local compose_file="/opt/socarium/MISP/docker-compose.yml"

    echo "🔧 Fixing MISP configuration..."

    # Update BASE_URL dynamically
    update_base_url "$env_file"

    # Check and resolve port conflicts for MISP
    echo "🔍 Checking ports for MISP..."
    local default_http_port=80
    local default_https_port=443

    if is_port_in_use $default_http_port; then
        local http_port=$(find_next_available_port $default_http_port)
        echo "⚠️ HTTP port $default_http_port is in use. Using $http_port instead."
        sed -i "s/${default_http_port}:80/${http_port}:80/g" "$compose_file"
    fi

    if is_port_in_use $default_https_port; then
        local https_port=$(find_next_available_port $default_https_port)
        echo "⚠️ HTTPS port $default_https_port is in use. Using $https_port instead."
        sed -i "s/${default_https_port}:443/${https_port}:443/g" "$compose_file"
    fi

    # Restart MISP services
    restart_misp "$compose_file"

    echo "✅ MISP configuration fixed and services restarted!"
}

# Run the main function
fix_misp_only
