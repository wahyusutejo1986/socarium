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
    echo "Recommended OS: Ubuntu Server 22.04 LTS                      "
    echo "This package has been tested and verified to work optimally   "
    echo "on Ubuntu Server 22.04 LTS.                                  "
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
    local requirements_met=true
    local checklist=""

    # OS Check
    os_version=$(lsb_release -d | awk -F'\t' '{print $2}')
    if [[ "$os_version" != *"Ubuntu 22.04"* ]]; then
        checklist+="[✘] OS: Not Ubuntu 22.04 LTS (Detected: $os_version)\n"
        echo "⚠️ Socarium has not been tested on $os_version. Proceeding with caution."
    else
        checklist+="[✔] OS: Ubuntu 22.04 LTS (Detected: $os_version)\n"
    fi

    # Check memory requirements
    total_memory=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_memory" -lt 15500 ]; then
        echo "[✘] RAM: Less than 16GB (Detected: ${total_memory}MB)"
        echo "❌ At least 16GB RAM is required. Please upgrade your RAM to proceed."
        exit 1
    else
        checklist+="[✔] RAM: 16GB or more (${total_memory}MB)\n"
    fi

    # Check required packages
    REQUIRED_PACKAGES=("docker" "docker-compose" "git" "curl" "wget" "build-essential" "python3-pip")
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if command -v $package &> /dev/null; then
            checklist+="[✔] $package: Installed\n"
        else
            checklist+="[✘] $package: Not Installed\n"
            requirements_met=false
        fi
    done

    # Display checklist
    echo -e "========================================="
    echo -e "         System Requirements Checklist"
    echo -e "========================================="
    echo -e "$checklist"
    echo -e "========================================="

    # Handle unmet requirements
    if [ "$requirements_met" = false ]; then
        echo "⚠️ Some requirements are not met. Installing pre-requisites..."
        install_prerequisites
    else
        echo "✅ All system requirements are met. Proceeding with installation."
    fi
}

# Function to handle directory conflicts
handle_directory_conflicts() {
    # Define the directories to check
    DIRECTORIES=(
        "/opt/socarium"
        "/opt/socarium/iris_web"
        "/opt/socarium/misp"
        "/opt/socarium/wazuh-docker"
        "/opt/socarium/opencti"
        "/opt/socarium/shuffle"
    )

    for DIR in "${DIRECTORIES[@]}"; do
        if [ -d "$DIR" ]; then
            echo "⚠️ Directory $DIR already exists."
            while true; do
                echo "Options for $DIR:"
                echo "1. Use existing directory"
                echo "2. Delete and create a new directory"
                echo "3. Skip this directory"
                echo "4. Exit setup"
                read -p "Choose an option [1-4]: " conflict_choice

                case "$conflict_choice" in
                    1)
                        echo "✅ Using existing directory: $DIR"
                        break
                        ;;
                    2)
                        echo "🗑 Deleting $DIR and creating a new one..."
                        rm -rf "$DIR"
                        mkdir -p "$DIR"
                        echo "✅ New directory created: $DIR"
                        break
                        ;;
                    3)
                        echo "⏭ Skipping $DIR. No changes will be made."
                        break
                        ;;
                    4)
                        echo "❌ Exiting setup. No further changes will be made."
                        exit 1
                        ;;
                    *)
                        echo "Invalid input. Please choose 1, 2, 3, or 4."
                        ;;
                esac
            done
        else
            echo "Directory $DIR does not exist. Creating it..."
            mkdir -p "$DIR"
            echo "✅ Created directory: $DIR"
        fi
    done

    echo "✅ Directory conflict resolution completed."
}

# Main Menu
while true; do
    echo "================================="
    echo "SOC Tools Installation Menu"
    echo "================================="
    echo "1. Handle Directory Conflicts"
    echo "2. Check Requirements"
    echo "3. Install Prerequisites"
    echo "4. Install All (Automated, Excluding YARA)"
    echo "5. Install Wazuh"
    echo "6. Install OpenCTI"
    echo "7. Install MISP"
    echo "8. Install DFIR IRIS"
    echo "9. Install Shuffle (Last)"
    echo "10. YARA Manual Step (Instructions)"
    echo "11. Exit"
    echo "================================="
    read -p "Choose an option [1-11]: " choice
    case $choice in
        1) handle_directory_conflicts ;;
        2) check_requirements ;;
        3) install_prerequisites ;;
        4)
            echo "🚀 Installing all components in the correct order..."
            install_prerequisites
            install_wazuh
            install_opencti
            install_misp
            install_dfir_iris
            install_shuffle
            echo "✅ All components installed successfully!"
            ;;
        5) install_wazuh ;;
        6) install_opencti ;;
        7) install_misp ;;
        8) install_dfir_iris ;;
        9) install_shuffle ;;
        10) install_yara_manual ;;
        11) echo "Exiting..."; break ;;
        *) echo "Invalid option, please choose again." ;;
    esac
done

echo "✅ Installation menu completed!"
