#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.
trap cleanup ERR  # Trap errors and perform cleanup.

# Base setup
BASE_DIR="modules"

LOG_FILE="/var/log/socarium_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # Redirect output to log file.

# Welcome Banner
welcome_banner() {
    echo "==============================================================="
    echo "                     Welcome to Socarium                      "
    echo "==============================================================="
    echo "Socarium is a modular SOC management package designed for     "
    echo "simplified deployment, management, and testing of SOC tools. "
    echo "This package includes: Wazuh, IRIS, Shuffle, MISP, and OpenCTI."
    echo "---------------------------------------------------------------"
    echo "Author:                                                       "
    echo "This SOC package was created through a collaboration between  "
    echo "JICA and idCARE UI to promote cybersecurity excellence.       "
    echo "==============================================================="
}

# Cleanup Function
cleanup() {
    echo "🧹 Cleaning up incomplete installations..."
    docker-compose down || true
    rm -rf "$BASE_DIR"/*
    echo "Cleanup completed."
}

# Check Requirements
check_requirements() {
    echo "🛠 Checking system requirements..."
    total_memory=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_memory" -lt 16000 ]; then
        echo "❌ At least 16GB RAM is recommended for this setup."
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker before proceeding."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose is not installed. Please install Docker Compose before proceeding."
        exit 1
    fi

    echo "✅ System requirements met."
}

# Install Prerequisites
install_prerequisites() {
    echo "🛠 Installing prerequisites..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y docker docker-compose git curl wget build-essential python3-pip yara
}

# Install All Socarium Modules
install_socarium_modules() {
    echo "🚀 Installing all Socarium modules..."
    install_wazuh
    install_dfir_iris
    install_shuffle
    install_misp
    install_opencti
    install_yara
    echo "✅ All Socarium modules installed successfully!"
    display_running_services
}

# Install Individual Modules
install_wazuh() {
    echo "🚀 Installing Wazuh..."
    docker-compose -f $BASE_DIR/wazuh/docker-compose.yml up -d
}

install_dfir_iris() {
    echo "🚀 Installing DFIR IRIS..."
    docker-compose -f $BASE_DIR/iris/docker-compose.yml up -d
}

install_shuffle() {
    echo "🚀 Installing Shuffle..."
    docker-compose -f $BASE_DIR/shuffle/docker-compose.yml up -d
}

install_misp() {
    echo "🚀 Installing MISP..."
    docker-compose -f $BASE_DIR/misp/docker-compose.yml up -d
}

install_opencti() {
    echo "🚀 Installing OpenCTI..."
    docker-compose -f $BASE_DIR/opencti/docker-compose.yml up -d
}

install_yara() {
    echo "🚀 Installing Yara..."
    sudo apt install -y yara
}

# Uninstall All Modules
uninstall_all() {
    echo "🗑️ Removing all Socarium modules..."
    docker-compose down -v || true
    docker system prune -af || true
    rm -rf "$BASE_DIR"
    echo "✅ All Socarium modules have been removed."
}

# Display Running Services
display_running_services() {
    echo "==============================================================="
    echo "       Running Socarium Modules and Access Details            "
    echo "==============================================================="
    docker ps --format "table {{.Names}}\t{{.Ports}}"
    echo "==============================================================="
    echo "Access Details:"
    echo "Wazuh:     http://<your-server-ip>:5601 (admin / admin)"
    echo "IRIS:      http://<your-server-ip>:8080 (iris_admin / iris_admin)"
    echo "Shuffle:   http://<your-server-ip>:3001 (admin@example.com / password)"
    echo "MISP:      http://<your-server-ip>:80   (admin@admin.test / admin)"
    echo "OpenCTI:   http://<your-server-ip>:8082 (admin@opencti.io / admin)"
    echo "==============================================================="
}

# Help Menu
show_help() {
    echo "📝 Help Menu"
    echo "1) Check Requirements: Validates your system's resources."
    echo "2) Install Prerequisites: Installs required tools."
    echo "3) Install Socarium Modules: Installs all SOC tools."
    echo "4-9) Install Individual Modules: Installs Wazuh, DFIR IRIS, Shuffle, etc."
    echo "10) Uninstall All: Removes all modules and cleans up."
    echo "11) Help: Displays this menu."
    echo "12) Exit: Exits the script."
}

# Main Menu
while true; do
    clear
    welcome_banner
    echo "================================="
    echo "Socarium Management Menu"
    echo "================================="
    echo "1) Check Requirements"
    echo "2) Install Prerequisites"
    echo "3) Install Socarium Modules"
    echo "4) Install Wazuh"
    echo "5) Install DFIR IRIS"
    echo "6) Install Shuffle"
    echo "7) Install MISP"
    echo "8) Install OpenCTI"
    echo "9) Install Yara"
    echo "10) Uninstall All"
    echo "11) Help"
    echo "12) Exit"
    echo "================================="
    read -p "Choose an option [1-12]: " choice
    case $choice in
        1) check_requirements ;;
        2) install_prerequisites ;;
        3) install_socarium_modules ;;
        4) install_wazuh ;;
        5) install_dfir_iris ;;
        6) install_shuffle ;;
        7) install_misp ;;
        8) install_opencti ;;
        9) install_yara ;;
        10) uninstall_all ;;
        11) show_help ;;
        12) echo "Exiting..."; break ;;
        *) echo "Invalid option, please choose again." ;;
    esac
done

echo "✅ Socarium management completed!"
