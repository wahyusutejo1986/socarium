#!/bin/bash

# Determine the longest container name length
max_name_length=$(sudo docker ps -a --format "{{.Names}}" | awk '{ print length }' | sort -nr | head -1)

# Add a minimum width for the container column
min_name_length=20
if [ "$max_name_length" -lt "$min_name_length" ]; then
    max_name_length=$min_name_length
fi

# Define column widths
ip_width=15
status_width=10

# Print the table header
printf "| %-*s | %-*s | %-*s |\n" "$max_name_length" "Container" "$ip_width" "IP Address" "$status_width" "Status"
printf "| %-${max_name_length}s | %-${ip_width}s | %-${status_width}s |\n" "$(head -c $max_name_length < /dev/zero | tr '\0' '-')" "$(head -c $ip_width < /dev/zero | tr '\0' '-')" "$(head -c $status_width < /dev/zero | tr '\0' '-')"

# Loop through all containers (running and stopped)
sudo docker ps -a --format "{{.Names}}" | while read container; do
    # Get the container IP address
    ip_address=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
    
    # Get the container status
    health_status=$(sudo docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container")
    
    # Display the container name, IP address, and status in a formatted table
    printf "| %-*s | %-*s | %-*s |\n" "$max_name_length" "$container" "$ip_width" "$ip_address" "$status_width" "$health_status"
done
