#!/bin/bash

set -e  # Exit on error
cd /tmp/socarium/iris-web/ || handle_error "Failed to change to irisweb directory"
sudo docker-compose down || handle_error "Failed to shutdown iris container"
sudo docker-compose up -d || handle_error "Failed to run iris"