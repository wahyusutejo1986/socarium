#!/bin/bash

install_dfir_iris() {
    echo "🚀 Installing DFIR IRIS..."
    local BASE_DIR="/opt/socarium"
    local DFIR_DIR="$BASE_DIR/iris-web"
    local DFIR_REPO="https://github.com/dfir-iris/iris-web.git"
    local CONTAINER_NAME="iriswebapp_nginx"

    # Check for existing container and its health
    if sudo docker ps --format '{{.Names}} {{.Status}}' | grep -q "^${CONTAINER_NAME} Up.*healthy$"; then
        echo "✅ Container '${CONTAINER_NAME}' already exists and is healthy. Skipping restart."
    else
        if sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo "⚠️ Container '${CONTAINER_NAME}' exists but is not healthy. Stopping and removing it..."
            sudo docker stop $CONTAINER_NAME || true
            sudo docker rm $CONTAINER_NAME || true
            echo "✅ Conflicting container '${CONTAINER_NAME}' has been removed."
        fi
    fi

    # Clone or update the repository
    if [ -d "$DFIR_DIR" ]; then
        echo "🛠 Checking existing DFIR IRIS repository..."
        cd $DFIR_DIR
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD || echo "detached")
        git fetch origin || error_handler "Fetching latest updates for DFIR IRIS"

        if [ "$CURRENT_BRANCH" = "detached" ]; then
            echo "⚠️ Detached HEAD state detected. Resetting to the default branch (main)."
            git checkout main || error_handler "Switching to main branch"
        fi

        LOCAL_COMMIT=$(git rev-parse HEAD)
        REMOTE_COMMIT=$(git rev-parse origin/$CURRENT_BRANCH)

        if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
            echo "✅ DFIR IRIS repository is up to date."
        else
            echo "🔄 Updating DFIR IRIS repository..."
            git pull origin $CURRENT_BRANCH || error_handler "Updating DFIR IRIS Repository"
        fi
    else
        echo "🌐 Cloning DFIR IRIS repository..."
        git clone $DFIR_REPO $DFIR_DIR || error_handler "Cloning DFIR IRIS Repository"
        cd $DFIR_DIR
        git checkout v2.3.7 || error_handler "Checking out version v2.3.7"
    fi

    # Handle .env file
    if [ ! -f ".env" ]; then
        echo "📄 Creating .env file from .env.model..."
        cp .env.model .env || error_handler "Copying .env file"
    else
        echo "✅ .env file already exists. Skipping."
    fi

    # Upgrade pip, setuptools, and wheel
    echo "🔧 Upgrading pip, setuptools, and wheel..."
    pip install --upgrade pip setuptools wheel || error_handler "Upgrading pip, setuptools, and wheel"

    # Install splunk-hec dependency
    echo "🔧 Installing splunk-hec with --use-pep517..."
    pip install splunk-hec --use-pep517 || error_handler "Installing splunk-hec with PEP 517"

    # Verify splunk-hec installation
    if ! pip show splunk-hec > /dev/null; then
        error_handler "Splunk-HEC Installation Failed"
    fi

    # Build and start containers
    echo "🔧 Building DFIR IRIS containers..."
    sudo docker-compose build || error_handler "Building DFIR IRIS Containers"

    echo "🚀 Starting DFIR IRIS containers..."
    sudo docker-compose up -d || error_handler "Starting DFIR IRIS Containers"

    echo "✅ DFIR IRIS installation completed successfully!"
}

error_handler() {
    local MESSAGE=$1
    echo "❌ Error: $MESSAGE. Exiting."
    exit 1
}

# Run the installation function
install_dfir_iris
