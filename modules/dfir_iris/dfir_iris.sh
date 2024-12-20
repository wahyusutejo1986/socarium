#!/bin/bash

# Function to handle errors
error_handler() {
    local MESSAGE=$1
    echo "❌ Error: $MESSAGE. Exiting." >> $LOG_FILE
    exit 1
}

# Function to prompt for admin password
prompt_password() {
    PASSWORD=$(whiptail --passwordbox "Please enter a password for the iris web administrator user:" 10 70 3>&1 1>&2 2>&3)
    local STATUS=$?
    if [ $STATUS -ne 0 ]; then
        echo "❌ Password input cancelled." >&2
        exit 1
    fi

    # Save to environment file
    local ENV_FILE="/opt/socarium/iris_web/.env"
    if [ -f "$ENV_FILE" ]; then
        sed -i "s/^IRIS_ADM_PASSWORD=.*/IRIS_ADM_PASSWORD=$PASSWORD/" "$ENV_FILE"
    else
        echo "IRIS_ADM_PASSWORD=$PASSWORD" >> "$ENV_FILE"
    fi
    echo "🔑 Admin Password Set for IRIS: $PASSWORD" >> $LOG_FILE
}

declare -r LOG_FILE="/opt/socarium/install_logs/dfir_iris_install.log"

# Function to install DFIR IRIS
install_dfir_iris() {
    (
        echo 0
        echo "🔧 Preparing to install DFIR IRIS..." >&2
        mkdir -p /opt/socarium/install_logs
        sleep 1

        BASE_DIR=$(dirname "$(realpath "$0")")

        echo 10
        echo "📂 Step 1: Checking or Cloning DFIR IRIS repository..." >&2
        local DFIR_DIR="/opt/socarium/iris_web"
        local DFIR_REPO="https://github.com/dfir-iris/iris-web.git"
        if [ -d "$DFIR_DIR" ]; then
            echo "🛠 Checking existing repository..." >&2
            cd $DFIR_DIR
            git fetch origin >> $LOG_FILE 2>&1 || error_handler "Fetching latest updates failed"
            git pull origin main >> $LOG_FILE 2>&1 || error_handler "Repository update failed"
        else
            git clone $DFIR_REPO $DFIR_DIR >> $LOG_FILE 2>&1 || error_handler "Repository cloning failed"
            cd $DFIR_DIR
        fi
        sleep 1

        echo 30
        echo "📝 Step 2: Configuring environment variables and setting admin password..." >&2
        local ENV_DEFAULT_PATH="$BASE_DIR/modules/dfir_iris/env_default"
        if [ ! -f "$DFIR_DIR/.env" ]; then
            if [ -f "$ENV_DEFAULT_PATH" ]; then
                cp "$ENV_DEFAULT_PATH" "$DFIR_DIR/.env" >> $LOG_FILE 2>&1 || error_handler "Environment configuration failed"
            else
                error_handler "Environment default file not found at $ENV_DEFAULT_PATH"
            fi
        fi
        prompt_password
        sleep 1

        echo 50
        echo "📦 Step 3: Upgrading pip and installing dependencies..." >&2
        pip install --upgrade pip setuptools wheel >> $LOG_FILE 2>&1 || error_handler "Pip upgrade failed"
        pip install splunk-hec --use-pep517 >> $LOG_FILE 2>&1 || error_handler "Splunk-HEC installation failed"
        sleep 1

        echo 70
        echo "🔧 Step 4: Updating Docker ports and starting containers..." >&2
        sed -i "s/- \"\${INTERFACE_HTTPS_PORT:-443}:\${INTERFACE_HTTPS_PORT:-443}\"/- \"\${INTERFACE_HTTPS_PORT:-8443}:\${INTERFACE_HTTPS_PORT:-8443}\"/" "$DFIR_DIR/docker-compose.base.yml" >> $LOG_FILE 2>&1 || error_handler "Docker port configuration failed"
        docker-compose build >> $LOG_FILE 2>&1 || error_handler "Container build failed"
        docker-compose up -d >> $LOG_FILE 2>&1 || error_handler "Starting containers failed"
        sleep 1

        echo 100
        echo "✅ DFIR IRIS installation completed successfully!" >&2
    ) | whiptail --gauge "Installing DFIR IRIS. Please wait..." 10 70 0

    # Final status
    local CONTAINER_NAME="iriswebapp_nginx"
    if docker ps --filter "name=$CONTAINER_NAME" --format '{{.Names}}' | grep -q $CONTAINER_NAME; then
        whiptail --msgbox "✅ DFIR IRIS has been installed successfully! Access it via the configured URL." 10 70
    else
        whiptail --msgbox "❌ DFIR IRIS installation failed. Please check the log file at $LOG_FILE." 10 70
    fi
}

# Run the installation function
install_dfir_iris
