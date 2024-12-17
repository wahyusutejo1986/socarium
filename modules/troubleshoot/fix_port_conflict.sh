#!/bin/bash

# Define default custom ports to reassign if conflicts are found
IRIS_HTTPS_PORT=9443
IRIS_HTTP_PORT=9080
SHUFFLE_HTTPS_PORT=8443
SHUFFLE_HTTP_PORT=8080

# Function to check if a port is in use
check_port_usage() {
    local port=$1
    if sudo lsof -i :$port &>/dev/null; then
        echo "Port $port is in use."
        return 0
    else
        echo "Port $port is free."
        return 1
    fi
}

# Function to stop and reassign ports for a container
reassign_ports() {
    local container_name=$1
    local new_http_port=$2
    local new_https_port=$3
    local image_name=$4

    echo "Stopping and removing container: $container_name"
    sudo docker stop $container_name &>/dev/null
    sudo docker rm $container_name &>/dev/null

    echo "Starting container $container_name with new ports: HTTP=$new_http_port, HTTPS=$new_https_port"
    sudo docker run -d \
        --name $container_name \
        -p $new_https_port:443 \
        -p $new_http_port:80 \
        $image_name
}

# Check and resolve port conflicts for IRIS
if check_port_usage 443; then
    echo "Conflict detected on port 443 for IRIS. Reassigning to $IRIS_HTTPS_PORT."
    reassign_ports "iriswebapp_nginx" $IRIS_HTTP_PORT $IRIS_HTTPS_PORT "ghcr.io/dfir-iris/iriswebapp_nginx:v2.4.18"
fi

if check_port_usage 80; then
    echo "Conflict detected on port 80 for IRIS. Reassigning to $IRIS_HTTP_PORT."
    reassign_ports "iriswebapp_nginx" $IRIS_HTTP_PORT $IRIS_HTTPS_PORT "ghcr.io/dfir-iris/iriswebapp_nginx:v2.4.18"
fi

# Check and resolve port conflicts for Shuffle
if check_port_usage 3443 || check_port_usage 443; then
    echo "Conflict detected on ports for Shuffle. Reassigning HTTPS to $SHUFFLE_HTTPS_PORT."
    reassign_ports "shuffle-frontend" $SHUFFLE_HTTP_PORT $SHUFFLE_HTTPS_PORT "ghcr.io/shuffle/shuffle-frontend:1.4.0"
fi

if check_port_usage 3001 || check_port_usage 80; then
    echo "Conflict detected on ports for Shuffle. Reassigning HTTP to $SHUFFLE_HTTP_PORT."
    reassign_ports "shuffle-frontend" $SHUFFLE_HTTP_PORT $SHUFFLE_HTTPS_PORT "ghcr.io/shuffle/shuffle-frontend:1.4.0"
fi

# Verify running containers and their ports
echo "\nUpdated Docker container list:"
sudo docker ps

# Verify updated firewall rules
echo "\nEnsuring firewall allows new ports:"
sudo iptables -A INPUT -p tcp --dport $IRIS_HTTPS_PORT -j ACCEPT
sudo iptables -A INPUT -p tcp --dport $IRIS_HTTP_PORT -j ACCEPT
sudo iptables -A INPUT -p tcp --dport $SHUFFLE_HTTPS_PORT -j ACCEPT
sudo iptables -A INPUT -p tcp --dport $SHUFFLE_HTTP_PORT -j ACCEPT
sudo iptables-save

# Final status
echo "\nPort conflict resolution completed. Verify services on the following ports:"
echo "- IRIS: HTTPS=$IRIS_HTTPS_PORT, HTTP=$IRIS_HTTP_PORT"
echo "- Shuffle: HTTPS=$SHUFFLE_HTTPS_PORT, HTTP=$SHUFFLE_HTTP_PORT"
